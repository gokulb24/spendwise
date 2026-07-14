import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../state/app_model.dart';
import '../utils/format.dart';
import 'ai_key.dart';

/// Stores the user's Groq API key and chat history locally on the device.
class AiConfig {
  static const _key = 'groqApiKey';
  static const _histKey = 'aiHistory';

  static Future<String> getKey() async {
    final stored = (await SharedPreferences.getInstance()).getString(_key) ?? '';
    return stored.isNotEmpty ? stored : kDefaultGroqApiKey;
  }

  static Future<void> setKey(String k) async =>
      (await SharedPreferences.getInstance()).setString(_key, k.trim());
  static Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);

  static Future<void> saveHistory(List<Map<String, dynamic>> msgs) async =>
      (await SharedPreferences.getInstance())
          .setString(_histKey, jsonEncode(msgs));

  static Future<List<Map<String, dynamic>>> loadHistory() async {
    final s = (await SharedPreferences.getInstance()).getString(_histKey);
    if (s == null || s.isEmpty) return [];
    try {
      return (jsonDecode(s) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clearHistory() async =>
      (await SharedPreferences.getInstance()).remove(_histKey);
}

/// Removes markdown so replies show as clean plain text in chat bubbles.
String stripMarkdown(String s) {
  var t = s;
  t = t.replaceAll(RegExp(r'```[\s\S]*?```'), ''); // code fences
  t = t.replaceAll('`', ''); // inline code ticks
  t = t.replaceAll(RegExp(r'^\s{0,3}#{1,6}\s*', multiLine: true), ''); // headings
  t = t.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m[1] ?? ''); // links
  t = t.replaceAll('**', '').replaceAll('__', ''); // bold
  t = t.replaceAll(RegExp(r'^(\s*)[\*\+]\s+', multiLine: true), r'$1- '); // bullets
  t = t.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return t.trim();
}

class AiException implements Exception {
  final String message;
  AiException(this.message);
  @override
  String toString() => message;
}

/// Talks to Groq's OpenAI-compatible API using the gpt-oss-120b model.
class AiService {
  static const String endpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String model = 'openai/gpt-oss-120b';

  /// Sends [question] with the tracker [context] and prior [history]
  /// (list of {'role','content'}). Returns the assistant's reply text.
  static Future<String> ask({
    required String apiKey,
    required String context,
    required List<Map<String, String>> history,
    required String question,
  }) async {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _system(context)},
      ...history,
      {'role': 'user', 'content': question},
    ];
    http.Response resp;
    try {
      resp = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'messages': messages,
              'temperature': 0.2,
              'max_tokens': 3072,
              // Medium reasoning for grounded, complete answers.
              'reasoning_effort': 'medium',
            }),
          )
          .timeout(const Duration(seconds: 45));
    } catch (_) {
      throw AiException('Network problem reaching the AI — check your connection.');
    }
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      final content = (choices != null && choices.isNotEmpty)
          ? (choices.first['message']?['content'] as String?)
          : null;
      if (content == null || content.trim().isEmpty) {
        throw AiException('The AI returned an empty response. Please try again.');
      }
      return stripMarkdown(content);
    }
    throw AiException(_friendlyError(resp.statusCode, resp.body));
  }

  static String _friendlyError(int code, String body) {
    switch (code) {
      case 401:
        return 'Your Groq API key was rejected. Re-check it in AI settings.';
      case 403:
        return 'Access denied by Groq. Check that your key is active.';
      case 404:
        return 'The model "$model" was not found on Groq. It may have been renamed.';
      case 429:
        return 'Rate limit reached on Groq. Wait a moment and try again.';
      default:
        return 'AI request failed (HTTP $code). Please try again.';
    }
  }

  static String _system(String context) =>
      'You are a friendly, knowledgeable family-finance assistant inside an '
      'expense-tracker app. Have a natural back-and-forth conversation.\n'
      'GROUNDING: Base every figure and statement STRICTLY on the DATA below. '
      'Never invent or estimate numbers that are not derivable from it. All '
      'amounts are Indian Rupees (INR, ₹). If something is not in the data, say '
      'clearly what is missing instead of guessing.\n'
      'COMPLETENESS: Give a complete, self-contained answer. When summarising, '
      'cover income, total spending, savings, the top spending categories and '
      'members, and mention relevant goals, debts or investments. Do the math '
      'and show the key totals.\n'
      'STYLE: Reply in plain conversational text — short paragraphs and simple '
      '"- " bullets. Do NOT use any markdown symbols (no *, **, #, backticks, '
      'or tables). Keep it clear and practical for a non-expert.\n\n'
      '=== FAMILY FINANCE DATA ===\n$context';
}

/// Builds a compact text snapshot of the tracker for the model.
String buildTrackerContext(AppModel m) {
  final s = m.summary;
  final b = StringBuffer();
  b.writeln('Family: ${m.family?.name ?? '-'}');
  b.writeln('Tracked members: ${m.members.join(', ')}');
  b.writeln('Current month: ${monthLabel(m.currentMonth)}');
  b.writeln('Income this month: ${inr(s.income)}');
  b.writeln('Total spent: ${inr(s.totalSpent)}');
  b.writeln('Total budget: ${inr(s.totalBudget)} (remaining ${inr(s.remaining)})');
  b.writeln('Net savings this month: ${inr(s.netSavings)}');

  b.writeln('\nCategory budget vs spent this month:');
  final budgets = m.currentBudgets;
  for (final c in m.categories) {
    final spent = s.spentByCat[c] ?? 0;
    final bud = budgets[c] ?? 0;
    if (spent > 0 || bud > 0) {
      b.writeln('- $c: spent ${inr(spent)} of ${inr(bud)}');
    }
  }

  b.writeln('\nSpending by member this month:');
  for (final mb in m.breakdownMembers) {
    b.writeln('- $mb: ${inr(s.spentByMem[mb] ?? 0)}');
  }

  final exps = [...m.monthExpenses]..sort((a, b) => b.date.compareTo(a.date));
  b.writeln('\nExpenses this month (${exps.length}):');
  for (final e in exps.take(60)) {
    b.writeln('- ${e.date} ${e.desc} | ${e.cat} | ${e.mem} | ${inr(e.amt)} | ${e.pay}'
        '${e.tags.isNotEmpty ? ' | #${e.tags.join(' #')}' : ''}');
  }

  // All-time aggregates so broad questions (e.g. "who spends the most overall")
  // can be answered even though the detailed list above is the current month.
  if (m.expenses.isNotEmpty) {
    final byMem = <String, double>{};
    final byCat = <String, double>{};
    final months = <String>{};
    var allTotal = 0.0;
    for (final e in m.expenses) {
      byMem[e.mem] = (byMem[e.mem] ?? 0) + e.amt;
      byCat[e.cat] = (byCat[e.cat] ?? 0) + e.amt;
      if (e.date.length >= 7) months.add(e.date.substring(0, 7));
      allTotal += e.amt;
    }
    final topCat = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final memSorted = byMem.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    b.writeln('\nOverall across all ${months.length} recorded month(s), '
        '${m.expenses.length} expenses totalling ${inr(allTotal)}:');
    b.writeln('By member (all time): '
        '${memSorted.map((e) => '${e.key} ${inr(e.value)}').join(', ')}');
    b.writeln('Top categories (all time): '
        '${topCat.take(6).map((e) => '${e.key} ${inr(e.value)}').join(', ')}');
  }

  if (m.goals.isNotEmpty) {
    b.writeln('\nSavings goals:');
    for (final g in m.goals) {
      b.writeln('- ${g.name} (${g.type}): saved ${inr(g.saved)} of ${inr(g.target)}'
          '${g.deadline != null ? ', by ${g.deadline}' : ''}');
    }
  }
  if (m.debts.isNotEmpty) {
    b.writeln('\nDebts / loans:');
    for (final d in m.debts) {
      b.writeln('- ${d.name} (${d.type}): outstanding ${inr(d.outstanding)} of '
          '${inr(d.principal)}${d.emi > 0 ? ', EMI ${inr(d.emi)}' : ''}'
          '${d.closed ? ' [paid off]' : ''}');
    }
  }
  if (m.investments.isNotEmpty) {
    b.writeln('\nInvestments:');
    for (final i in m.investments) {
      b.writeln('- ${i.name} (${i.type}): invested ${inr(i.invested)}, now '
          '${inr(i.currentValue)} (${i.returnPct >= 0 ? '+' : ''}${i.returnPct.toStringAsFixed(1)}%)');
    }
  }
  if (m.reminders.where((r) => !r.done).isNotEmpty) {
    b.writeln('\nPending reminders:');
    for (final r in m.reminders.where((r) => !r.done)) {
      b.writeln('- ${r.title} (${r.date})');
    }
  }
  return b.toString();
}

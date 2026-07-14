import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ai_service.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';

class _Msg {
  final bool user;
  final String text;
  _Msg(this.user, this.text);
  Map<String, dynamic> toJson() => {'user': user, 'text': text};
  factory _Msg.fromJson(Map<String, dynamic> j) =>
      _Msg(j['user'] as bool? ?? false, (j['text'] ?? '') as String);
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});
  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  String _key = '';
  bool _loadingKey = true;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    AiConfig.getKey().then((k) {
      if (mounted) {
        setState(() {
          _key = k;
          _loadingKey = false;
        });
      }
    });
    AiConfig.loadHistory().then((h) {
      if (mounted && h.isNotEmpty) {
        setState(() => _messages.addAll(h.map(_Msg.fromJson)));
        _toBottom();
      }
    });
  }

  void _persist() =>
      AiConfig.saveHistory(_messages.map((m) => m.toJson()).toList());

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<Map<String, String>> _apiHistory() => _messages
      .take(_messages.length)
      .toList()
      .reversed
      .take(8)
      .toList()
      .reversed
      .map((m) => {'role': m.user ? 'user' : 'assistant', 'content': m.text})
      .toList();

  Future<void> _send(String text) async {
    text = text.trim();
    if (text.isEmpty || _sending) return;
    final history = _apiHistory();
    setState(() {
      _messages.add(_Msg(true, text));
      _sending = true;
      _input.clear();
    });
    _toBottom();
    try {
      final m = context.read<AppModel>();
      final reply = await AiService.ask(
        apiKey: _key,
        context: buildTrackerContext(m),
        history: history,
        question: text,
      );
      setState(() => _messages.add(_Msg(false, reply)));
    } catch (e) {
      setState(() => _messages.add(_Msg(false,
          e is AiException ? e.message : 'Something went wrong. Try again.')));
    } finally {
      if (mounted) setState(() => _sending = false);
      _persist();
      _toBottom();
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              tooltip: 'New chat',
              icon: const Icon(Icons.add_comment_outlined),
              onPressed: () {
                setState(() => _messages.clear());
                AiConfig.clearHistory();
              },
            ),
          if (_key.isNotEmpty)
            IconButton(
              tooltip: 'AI settings',
              icon: const Icon(Icons.key_outlined),
              onPressed: _openSettings,
            ),
        ],
      ),
      body: _loadingKey
          ? const Center(child: CircularProgressIndicator())
          : _key.isEmpty
              ? _SetupView(onSaved: (k) => setState(() => _key = k))
              : _chat(context),
    );
  }

  Widget _chat(BuildContext context) {
    final scheme = context.scheme;
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? _intro(context)
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: _messages.length + (_sending ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i >= _messages.length) {
                      return const _Bubble(user: false, child: _Typing());
                    }
                    final msg = _messages[i];
                    return _Bubble(
                        user: msg.user, child: SelectableText(msg.text));
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _send,
                    decoration: InputDecoration(
                      hintText: 'Ask about your money…',
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: 'aiSend',
                  elevation: 0,
                  onPressed: _sending ? null : () => _send(_input.text),
                  child: const Icon(Icons.arrow_upward),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _intro(BuildContext context) {
    final scheme = context.scheme;
    const quick = [
      'Summarise this month',
      'Where can we cut spending?',
      'Who spent the most and on what?',
      'How are our savings goals doing?',
      'How much debt do we have left?',
    ];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        Icon(Icons.auto_awesome, size: 44, color: scheme.primary),
        const SizedBox(height: 12),
        Center(
          child: Text('Ask about your finances',
              style: context.texts.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
              'Powered by gpt-oss-120b via Groq. It can see this family\'s '
              'tracker data to answer questions and summarise.',
              textAlign: TextAlign.center,
              style: context.texts.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final q in quick)
              ActionChip(label: Text(q), onPressed: () => _send(q)),
          ],
        ),
      ],
    );
  }

  Future<void> _openSettings() async {
    final ctrl = TextEditingController(text: _key);
    final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('AI settings'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
              labelText: 'Groq API key', hintText: 'gsk_…'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await AiConfig.clear();
              if (c.mounted) Navigator.pop(c, '');
            },
            child: const Text('Remove'),
          ),
          FilledButton(
              onPressed: () => Navigator.pop(c, ctrl.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (result != null) {
      await AiConfig.setKey(result);
      setState(() => _key = result);
    }
  }
}

class _Bubble extends StatelessWidget {
  final bool user;
  final Widget child;
  const _Bubble({required this.user, required this.child});
  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: user ? scheme.primary : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(user ? 18 : 4),
            bottomRight: Radius.circular(user ? 4 : 18),
          ),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(
              color: user ? scheme.onPrimary : scheme.onSurface,
              fontSize: 14.5,
              height: 1.35),
          child: child,
        ),
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();
  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 44,
        child: Text('…', style: TextStyle(fontSize: 22, height: 0.8)),
      );
}

class _SetupView extends StatefulWidget {
  final ValueChanged<String> onSaved;
  const _SetupView({required this.onSaved});
  @override
  State<_SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<_SetupView> {
  final _ctrl = TextEditingController();
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        Icon(Icons.auto_awesome, size: 44, color: scheme.primary),
        const SizedBox(height: 12),
        Text('Turn on the AI assistant',
            style:
                context.texts.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
            'The assistant uses the gpt-oss-120b model via Groq, which has a '
            'free tier. Paste a Groq API key to enable it:',
            style: context.texts.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 14),
        _step(context, '1', 'Go to  console.groq.com  and sign in (free).'),
        _step(context, '2', 'Open  API Keys  →  Create API Key  and copy it.'),
        _step(context, '3', 'Paste it below and tap Save.'),
        const SizedBox(height: 16),
        TextField(
          controller: _ctrl,
          decoration: const InputDecoration(
              labelText: 'Groq API key', hintText: 'gsk_…'),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () async {
            final k = _ctrl.text.trim();
            if (k.isEmpty) return;
            await AiConfig.setKey(k);
            widget.onSaved(k);
          },
          icon: const Icon(Icons.check),
          label: const Text('Save & start'),
        ),
        const SizedBox(height: 12),
        Text(
            'Note: your tracker data for the current month is sent to Groq to '
            'answer questions. The key is stored only on this device.',
            style: context.texts.labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _step(BuildContext context, String n, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: context.scheme.primaryContainer,
              child: Text(n,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.scheme.onPrimaryContainer)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: context.texts.bodyMedium)),
          ],
        ),
      );
}

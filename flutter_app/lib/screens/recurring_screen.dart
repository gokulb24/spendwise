import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/constants.dart';
import '../models/recurring.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<AppModel>();
    final scheme = context.scheme;
    final items = [...m.recurring]
      ..sort((a, b) => a.nextDate.compareTo(b.nextDate));
    return Scaffold(
      appBar: AppBar(title: const Text('Recurring transactions')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'recFab',
        onPressed: () => showRecurringEditor(context, m, null),
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.repeat, size: 44, color: scheme.primary),
                    const SizedBox(height: 12),
                    Text('No recurring transactions',
                        style: context.texts.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                        'Set up rent, EMIs, subscriptions or salary once and '
                        'the app adds them automatically each cycle.',
                        textAlign: TextAlign.center,
                        style: context.texts.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: items.length,
              separatorBuilder: (_, i) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _RecurringCard(r: items[i]),
            ),
    );
  }
}

class _RecurringCard extends StatelessWidget {
  final Recurring r;
  const _RecurringCard({required this.r});

  @override
  Widget build(BuildContext context) {
    final m = context.read<AppModel>();
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.desc.isEmpty ? r.cat : r.desc,
                    style: context.texts.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                    '${inr(r.amt)} · ${r.frequency[0].toUpperCase()}${r.frequency.substring(1)} · ${r.mem}',
                    style: context.texts.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(
                    r.active
                        ? 'Next: ${fmtDay(r.nextDate)}'
                        : 'Paused',
                    style: context.texts.labelSmall?.copyWith(
                        color: r.active
                            ? context.semantic.positive
                            : context.semantic.warning,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Switch(
            value: r.active,
            onChanged: (v) => m.setRecurringActive(r.id, v),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') showRecurringEditor(context, m, r);
              if (v == 'delete') m.deleteRecurring(r.id);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> showRecurringEditor(
    BuildContext context, AppModel m, Recurring? r) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: ChangeNotifierProvider.value(
        value: m,
        child: _RecurringEditorSheet(recurring: r),
      ),
    ),
  );
}

class _RecurringEditorSheet extends StatefulWidget {
  final Recurring? recurring;
  const _RecurringEditorSheet({this.recurring});
  @override
  State<_RecurringEditorSheet> createState() => _RecurringEditorSheetState();
}

class _RecurringEditorSheetState extends State<_RecurringEditorSheet> {
  late final _desc = TextEditingController(text: widget.recurring?.desc ?? '');
  late final _amt = TextEditingController(
      text: widget.recurring != null
          ? widget.recurring!.amt.round().toString()
          : '');
  late String _cat = widget.recurring?.cat ?? kCategories.first;
  late String _mem = widget.recurring?.mem ?? '';
  late String _pay = widget.recurring?.pay ?? kPayments.first;
  late String _freq = widget.recurring?.frequency ?? 'monthly';
  late DateTime _next =
      DateTime.tryParse(widget.recurring?.nextDate ?? '') ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    final members = context.read<AppModel>().members;
    if (_mem.isEmpty) _mem = members.isNotEmpty ? members.first : '';
  }

  @override
  void dispose() {
    _desc.dispose();
    _amt.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amt = double.tryParse(_amt.text.trim()) ?? 0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter an amount greater than 0.')));
      return;
    }
    final m = context.read<AppModel>();
    final mem = m.members.contains(_mem)
        ? _mem
        : (m.members.isNotEmpty ? m.members.first : '');
    await m.saveRecurring(Recurring(
      id: widget.recurring?.id ?? '',
      desc: _desc.text.trim().isEmpty ? '(no description)' : _desc.text.trim(),
      cat: _cat,
      mem: mem,
      amt: amt,
      pay: _pay,
      frequency: _freq,
      nextDate: ymd(_next),
      active: widget.recurring?.active ?? true,
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<AppModel>();
    final members =
        {...model.members, _mem}.where((s) => s.isNotEmpty).toList();
    final cats = {...model.categories, _cat}.toList();
    final isEdit = widget.recurring != null;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isEdit ? 'Edit recurring' : 'New recurring transaction',
                style: context.texts.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
                controller: _desc,
                decoration: const InputDecoration(
                    labelText: 'Description', hintText: 'e.g. House rent')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                    controller: _amt,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Amount', prefixText: '₹ ', hintText: '0')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dd('Frequency', kFrequencies, _freq,
                    Icons.repeat, (v) => setState(() => _freq = v!),
                    capitalize: true),
              ),
            ]),
            const SizedBox(height: 12),
            _dd('Category', cats, _cat, Icons.category_outlined,
                (v) => setState(() => _cat = v!)),
            const SizedBox(height: 12),
            _dd('Member', members, _mem, Icons.person_outline,
                (v) => setState(() => _mem = v!)),
            const SizedBox(height: 12),
            _dd('Payment', kPayments, _pay, Icons.credit_card,
                (v) => setState(() => _pay = v!)),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                    context: context,
                    initialDate: _next,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100));
                if (d != null) setState(() => _next = d);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Starts / next on',
                    prefixIcon: Icon(Icons.event)),
                child: Text(fmtDay(ymd(_next))),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: Icon(isEdit ? Icons.check : Icons.add),
              label: Text(isEdit ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dd(String label, List<String> items, String value, IconData icon,
      ValueChanged<String?> onChanged,
      {bool capitalize = false}) {
    final safe = items.contains(value) ? value : items.first;
    return DropdownButtonFormField<String>(
      initialValue: safe,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: items
          .map((e) => DropdownMenuItem(
              value: e,
              child: Text(
                  capitalize
                      ? '${e[0].toUpperCase()}${e.substring(1)}'
                      : e,
                  overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

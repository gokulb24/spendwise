import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/constants.dart';
import '../models/expense.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Icon shown for a category (small visual cue in lists).
IconData iconForCategory(String cat) {
  switch (cat) {
    case 'Housing / Rent':
      return Icons.home_outlined;
    case 'Utilities':
      return Icons.bolt_outlined;
    case 'Groceries':
      return Icons.local_grocery_store_outlined;
    case 'Dining Out':
      return Icons.restaurant_outlined;
    case 'Transport / Fuel':
      return Icons.local_gas_station_outlined;
    case 'Healthcare':
      return Icons.medical_services_outlined;
    case 'Education':
      return Icons.school_outlined;
    case 'Childcare':
      return Icons.child_care_outlined;
    case 'Insurance':
      return Icons.verified_user_outlined;
    case 'Entertainment':
      return Icons.movie_outlined;
    case 'Shopping':
      return Icons.shopping_bag_outlined;
    case 'Personal Care':
      return Icons.spa_outlined;
    case 'Loan / EMI':
      return Icons.account_balance_outlined;
    case 'Savings / Investment':
      return Icons.savings_outlined;
    default:
      return Icons.receipt_long_outlined;
  }
}

/// A single expense row: leading category icon, description + meta, amount.
/// Swipe left to delete; tap to edit.
class ExpenseListItem extends StatelessWidget {
  final Expense e;
  final bool dense;
  const ExpenseListItem({super.key, required this.e, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final m = context.read<AppModel>();
    return Dismissible(
      key: ValueKey(e.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: context.semantic.negativeContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline, color: context.semantic.negative),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Delete this expense?'),
                content: Text('${e.desc} — ${inr(e.amt)}'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: context.semantic.negative),
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Delete')),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => m.deleteExpense(e.id),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showEditExpense(context, m, e),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: dense ? 8 : 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconForCategory(e.cat),
                    size: 20, color: scheme.onSecondaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.desc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                        '${fmtDay(e.date)} · ${e.mem} · ${e.pay}'
                        '${e.tags.isNotEmpty ? '  ${e.tags.map((t) => '#$t').join(' ')}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(inr(e.amt),
                  style: context.texts.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the add/edit expense bottom sheet.
Future<void> showEditExpense(BuildContext context, AppModel m, Expense? e) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: ChangeNotifierProvider.value(
        value: m,
        child: ExpenseEditorSheet(expense: e),
      ),
    ),
  );
}

/// Bottom-sheet form for adding a new expense or editing an existing one.
class ExpenseEditorSheet extends StatefulWidget {
  final Expense? expense; // null = add new
  const ExpenseEditorSheet({super.key, this.expense});
  @override
  State<ExpenseEditorSheet> createState() => _ExpenseEditorSheetState();
}

class _ExpenseEditorSheetState extends State<ExpenseEditorSheet> {
  late final _desc =
      TextEditingController(text: widget.expense?.desc ?? '');
  late final _amt = TextEditingController(
      text: widget.expense != null ? widget.expense!.amt.round().toString() : '');
  late DateTime _date =
      DateTime.tryParse(widget.expense?.date ?? '') ?? DateTime.now();
  late String _cat = widget.expense?.cat ?? kCategories.first;
  late String _mem = widget.expense?.mem ?? '';
  late String _pay = widget.expense?.pay ?? kPayments.first;
  late final _tags =
      TextEditingController(text: (widget.expense?.tags ?? const []).join(', '));
  late final _note = TextEditingController(text: widget.expense?.note ?? '');

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
    _tags.dispose();
    _note.dispose();
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
    final tags = _tags.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final exp = Expense(
      id: widget.expense?.id ?? '',
      date: ymd(_date),
      desc: _desc.text.trim().isEmpty ? '(no description)' : _desc.text.trim(),
      cat: _cat,
      mem: mem,
      amt: amt,
      pay: _pay,
      tags: tags,
      note: _note.text.trim(),
    );
    // Warn about a likely duplicate before adding a brand-new expense.
    if (widget.expense == null) {
      final dup = m.findPossibleDuplicate(exp);
      if (dup != null) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Possible duplicate'),
            content: Text(
                'You already have "${dup.desc}" (${inr(dup.amt)}) in ${dup.cat} '
                'on ${fmtDay(dup.date)}. Add this one anyway?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('Add anyway')),
            ],
          ),
        );
        if (proceed != true) return;
      }
      await m.addExpense(exp);
    } else {
      await m.updateExpense(widget.expense!.id, exp);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<AppModel>();
    final members =
        {...model.members, _mem}.where((s) => s.isNotEmpty).toList();
    final cats = {...model.categories, _cat}.toList();
    final isEdit = widget.expense != null;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isEdit ? 'Edit expense' : 'Add expense',
                style: context.texts.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100));
                    if (d != null) setState(() => _date = d);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Date', prefixIcon: Icon(Icons.event)),
                    child: Text(fmtDay(ymd(_date))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _amt,
                  keyboardType: TextInputType.number,
                  autofocus: !isEdit,
                  decoration: const InputDecoration(
                      labelText: 'Amount', prefixText: '₹ ', hintText: '0'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextField(
                controller: _desc,
                decoration: const InputDecoration(
                    labelText: 'Description', hintText: 'e.g. Groceries')),
            const SizedBox(height: 12),
            _dropdown('Category', cats, _cat, Icons.category_outlined,
                (v) => setState(() => _cat = v!)),
            const SizedBox(height: 12),
            _dropdown('Member', members, _mem, Icons.person_outline,
                (v) => setState(() => _mem = v!)),
            const SizedBox(height: 12),
            _dropdown('Payment', kPayments, _pay, Icons.credit_card,
                (v) => setState(() => _pay = v!)),
            const SizedBox(height: 12),
            TextField(
                controller: _tags,
                decoration: const InputDecoration(
                    labelText: 'Tags (comma separated)',
                    hintText: 'e.g. trip, reimbursable',
                    prefixIcon: Icon(Icons.label_outline))),
            const SizedBox(height: 12),
            TextField(
                controller: _note,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    prefixIcon: Icon(Icons.sticky_note_2_outlined))),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: Icon(isEdit ? Icons.check : Icons.add),
              label: Text(isEdit ? 'Save changes' : 'Add expense'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(String label, List<String> items, String value,
      IconData icon, ValueChanged<String?> onChanged) {
    final safe = items.contains(value) ? value : (items.isNotEmpty ? items.first : null);
    return DropdownButtonFormField<String>(
      initialValue: safe,
      isExpanded: true,
      decoration:
          InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: items
          .map((e) => DropdownMenuItem(
              value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

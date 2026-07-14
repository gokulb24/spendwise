import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'common.dart';

class BudgetTable extends StatelessWidget {
  const BudgetTable({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<AppModel>();
    final budgets = m.currentBudgets;
    final s = m.summary;
    return SectionCard(
      title: 'Category Budget vs. Actual',
      trailing: IconButton(
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.tune, size: 20),
        tooltip: 'Edit categories',
        onPressed: () => showCategoryManager(context, m),
      ),
      child: Column(
        children: [
          for (final c in m.categories)
            _BudgetRow(
              category: c,
              budget: budgets[c] ?? 0,
              spent: s.spentByCat[c] ?? 0,
            ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => showCategoryManager(context, m),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add category'),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet to add/remove the categories tracked in Budget vs. Actual.
Future<void> showCategoryManager(BuildContext context, AppModel m) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: ChangeNotifierProvider.value(
        value: m,
        child: const _CategoryManagerSheet(),
      ),
    ),
  );
}

class _CategoryManagerSheet extends StatefulWidget {
  const _CategoryManagerSheet();
  @override
  State<_CategoryManagerSheet> createState() => _CategoryManagerSheetState();
}

class _CategoryManagerSheetState extends State<_CategoryManagerSheet> {
  final _add = TextEditingController();

  @override
  void dispose() {
    _add.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = context.watch<AppModel>();
    final scheme = context.scheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit categories',
                style: context.texts.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Add anything you want to track, or remove ones you don\'t use.',
                style: context.texts.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in m.categories)
                      InputChip(
                        label: Text(c),
                        onDeleted: m.categories.length > 1
                            ? () => m.removeCategory(c)
                            : null,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _add,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                        labelText: 'New category',
                        hintText: 'e.g. Gadgets, Pets, Charity'),
                    onSubmitted: (_) => _submit(m),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                    onPressed: () => _submit(m), child: const Text('Add')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit(AppModel m) {
    final t = _add.text.trim();
    if (t.isEmpty) return;
    m.addCategory(t);
    _add.clear();
  }
}

class _BudgetRow extends StatefulWidget {
  final String category;
  final double budget;
  final double spent;
  const _BudgetRow(
      {required this.category, required this.budget, required this.spent});
  @override
  State<_BudgetRow> createState() => _BudgetRowState();
}

class _BudgetRowState extends State<_BudgetRow> {
  // Show 0 as a placeholder (hint) rather than a literal "0" the user must clear.
  late final TextEditingController _c = TextEditingController(
      text: widget.budget > 0 ? widget.budget.round().toString() : '');

  @override
  void didUpdateWidget(covariant _BudgetRow old) {
    super.didUpdateWidget(old);
    final t = widget.budget > 0 ? widget.budget.round().toString() : '';
    if (!_c.selection.isValid && _c.text != t) _c.text = t;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = context.read<AppModel>();
    final sem = context.semantic;
    final left = widget.budget - widget.spent;
    final pct = widget.budget > 0 ? (widget.spent / widget.budget * 100) : 0;
    final over = pct >= 100;
    final warn = pct >= 80;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.category,
                    style: context.texts.bodyMedium),
                Text('Left ${inr(left)}',
                    style: context.texts.labelSmall?.copyWith(
                        color: left < 0 ? sem.negative : sem.positive)),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _c,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                style: context.texts.bodyMedium,
                decoration: const InputDecoration(
                  hintText: '0',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onSubmitted: (v) =>
                    m.setBudget(widget.category, double.tryParse(v.trim()) ?? 0),
                onTapOutside: (_) => m.setBudget(
                    widget.category, double.tryParse(_c.text.trim()) ?? 0),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(inr(widget.spent),
                textAlign: TextAlign.right,
                style: context.texts.bodyMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Pill(
                '${pct.round()}%',
                bg: over
                    ? sem.negativeContainer
                    : warn
                        ? sem.warningContainer
                        : sem.positiveContainer,
                fg: over
                    ? sem.negative
                    : warn
                        ? sem.warning
                        : sem.positive,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

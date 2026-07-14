import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/expense_tile.dart';
import '../widgets/month_picker.dart';

class ExpensesTab extends StatefulWidget {
  const ExpensesTab({super.key});
  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab> {
  final _search = TextEditingController();
  String _query = '';
  String _member = 'All';
  String _category = 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Expense> _filtered(AppModel m) {
    final items = m.monthExpenses.where((e) {
      if (_member != 'All' && e.mem != _member) return false;
      if (_category != 'All' && e.cat != _category) return false;
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final hay = [
          e.desc,
          e.cat,
          e.mem,
          e.note,
          ...e.tags,
        ].join(' ').toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        final d = b.date.compareTo(a.date);
        return d != 0 ? d : b.id.compareTo(a.id);
      });
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final m = context.watch<AppModel>();
    final scheme = context.scheme;
    final items = _filtered(m);
    final total = items.fold<double>(0, (s, e) => s + e.amt);
    final members = ['All', ...m.members];

    return Column(
      children: [
        // header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Text('Expenses',
                  style: context.texts.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              _MonthChip(m: m),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v.trim()),
            decoration: InputDecoration(
              hintText: 'Search description, category, member…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
        ),
        // member filter chips
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final mb in members)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(mb),
                    selected: _member == mb,
                    onSelected: (_) => setState(() => _member = mb),
                  ),
                ),
            ],
          ),
        ),
        // category dropdown + total
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Builder(builder: (context) {
                  final catItems = ['All', ...m.categories];
                  final catValue =
                      catItems.contains(_category) ? _category : 'All';
                  return DropdownButtonFormField<String>(
                    key: ValueKey('cat-${catItems.length}-$catValue'),
                    initialValue: catValue,
                    isExpanded: true,
                    decoration: const InputDecoration(
                        isDense: true,
                        prefixIcon: Icon(Icons.category_outlined)),
                    items: catItems
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v ?? 'All'),
                  );
                }),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${items.length} · ${inr(total)}',
                      style: context.texts.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text('shown',
                      style: context.texts.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 40, color: scheme.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text('No matching expenses',
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: items.length,
                  separatorBuilder: (_, i) => const Divider(height: 1),
                  itemBuilder: (_, i) => ExpenseListItem(e: items[i]),
                ),
        ),
      ],
    );
  }
}

class _MonthChip extends StatelessWidget {
  final AppModel m;
  const _MonthChip({required this.m});
  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.calendar_month, size: 18),
      label: Text(monthLabel(m.currentMonth)),
      onPressed: () async {
        final picked = await showMonthPicker(context, m.currentMonth);
        if (picked != null) m.setMonth(picked);
      },
    );
  }
}

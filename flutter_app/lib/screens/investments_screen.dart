import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/investment.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

IconData iconForInvestment(String type) {
  switch (type) {
    case 'Mutual Fund':
      return Icons.pie_chart_outline;
    case 'Stocks':
      return Icons.show_chart;
    case 'SIP':
      return Icons.autorenew;
    case 'Fixed Deposit':
      return Icons.account_balance_outlined;
    case 'PPF / EPF':
      return Icons.savings_outlined;
    case 'Gold':
      return Icons.workspace_premium_outlined;
    case 'Real Estate':
      return Icons.home_work_outlined;
    case 'Bonds':
      return Icons.receipt_long_outlined;
    case 'Crypto':
      return Icons.currency_bitcoin;
    default:
      return Icons.attach_money;
  }
}

class InvestmentsScreen extends StatelessWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<AppModel>();
    final scheme = context.scheme;
    final sem = context.semantic;
    final gain = m.totalReturns >= 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Investments')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'invFab',
        onPressed: () => showInvestmentEditor(context, m, null),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PORTFOLIO VALUE',
                    style: context.texts.labelSmall?.copyWith(
                        color: scheme.onPrimary.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text(inr(m.totalPortfolioValue),
                    style: context.texts.headlineMedium?.copyWith(
                        color: scheme.onPrimary, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _pill(context, 'Invested ${inr(m.totalInvested)}'),
                    const SizedBox(width: 8),
                    _pill(
                        context,
                        '${gain ? '▲' : '▼'} ${inr(m.totalReturns.abs())}',
                        color: gain ? sem.positive : sem.negative),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (m.investments.isEmpty)
            _empty(context)
          else
            for (final inv in m.investments) _InvestmentCard(inv: inv),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, String text, {Color? color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: context.scheme.onPrimary.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: context.texts.labelMedium?.copyWith(
                color: color ?? context.scheme.onPrimary,
                fontWeight: FontWeight.w700)),
      );

  Widget _empty(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.trending_up, size: 44, color: scheme.primary),
          const SizedBox(height: 12),
          Text('No investments yet',
              style: context.texts.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
              'Track mutual funds, stocks, SIPs, FDs, gold or property — with '
              'how much you invested and what it\'s worth now.',
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _InvestmentCard extends StatelessWidget {
  final Investment inv;
  const _InvestmentCard({required this.inv});

  @override
  Widget build(BuildContext context) {
    final m = context.read<AppModel>();
    final scheme = context.scheme;
    final sem = context.semantic;
    final gain = inv.isGain;
    final c = gain ? sem.positive : sem.negative;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(iconForInvestment(inv.type),
                    color: scheme.onSecondaryContainer, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inv.name,
                        style: context.texts.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(inv.type,
                        style: context.texts.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'update') _updateValue(context, m);
                  if (v == 'edit') showInvestmentEditor(context, m, inv);
                  if (v == 'delete') m.deleteInvestment(inv.id);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: 'update', child: Text('Update value')),
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _kv(context, 'Current value', inr(inv.currentValue)),
              ),
              Expanded(
                child: _kv(context, 'Invested', inr(inv.invested)),
              ),
              Expanded(
                child: _kv(
                    context,
                    'Returns',
                    '${gain ? '+' : '-'}${inr(inv.returns.abs())}',
                    color: c,
                    sub: '${inv.returnPct >= 0 ? '+' : ''}${inv.returnPct.toStringAsFixed(1)}%'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => _updateValue(context, m),
            icon: const Icon(Icons.sync, size: 18),
            label: const Text('Update current value'),
          ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v,
      {Color? color, String? sub}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k,
            style: context.texts.labelSmall
                ?.copyWith(color: context.scheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(v,
            style: context.texts.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700, color: color)),
        if (sub != null)
          Text(sub,
              style: context.texts.labelSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Future<void> _updateValue(BuildContext context, AppModel m) async {
    final ctrl =
        TextEditingController(text: inv.currentValue.round().toString());
    final v = await showDialog<double>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Update value · ${inv.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
              labelText: 'Current value', prefixText: '₹ '),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(c, double.tryParse(ctrl.text.trim())),
              child: const Text('Save')),
        ],
      ),
    );
    if (v != null && v >= 0) {
      await m.saveInvestment(Investment(
        id: inv.id,
        name: inv.name,
        type: inv.type,
        invested: inv.invested,
        currentValue: v,
        date: todayIso(),
      ));
    }
  }
}

Future<void> showInvestmentEditor(
    BuildContext context, AppModel m, Investment? inv) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: ChangeNotifierProvider.value(
        value: m,
        child: _InvestmentEditorSheet(investment: inv),
      ),
    ),
  );
}

class _InvestmentEditorSheet extends StatefulWidget {
  final Investment? investment;
  const _InvestmentEditorSheet({this.investment});
  @override
  State<_InvestmentEditorSheet> createState() => _InvestmentEditorSheetState();
}

class _InvestmentEditorSheetState extends State<_InvestmentEditorSheet> {
  late final _name =
      TextEditingController(text: widget.investment?.name ?? '');
  late final _invested = TextEditingController(
      text: widget.investment != null
          ? widget.investment!.invested.round().toString()
          : '');
  late final _current = TextEditingController(
      text: widget.investment != null
          ? widget.investment!.currentValue.round().toString()
          : '');
  late String _type = widget.investment?.type ?? kInvestmentTypes.first;
  late DateTime _date =
      DateTime.tryParse(widget.investment?.date ?? '') ?? DateTime.now();

  @override
  void dispose() {
    _name.dispose();
    _invested.dispose();
    _current.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final invested = double.tryParse(_invested.text.trim()) ?? 0;
    if (_name.text.trim().isEmpty || invested <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter a name and an invested amount greater than 0.')));
      return;
    }
    final current = double.tryParse(_current.text.trim()) ?? invested;
    await context.read<AppModel>().saveInvestment(Investment(
          id: widget.investment?.id ?? '',
          name: _name.text.trim(),
          type: _type,
          invested: invested,
          currentValue: current,
          date: ymd(_date),
        ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.investment != null;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isEdit ? 'Edit investment' : 'Add investment',
                style: context.texts.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _type,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Type', prefixIcon: Icon(Icons.category_outlined)),
              items: kInvestmentTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _type = v ?? kInvestmentTypes.first),
            ),
            const SizedBox(height: 12),
            TextField(
                controller: _name,
                decoration: const InputDecoration(
                    labelText: 'Name', hintText: 'e.g. Nifty 50 Index Fund')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                    controller: _invested,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Invested', prefixText: '₹ ', hintText: '0')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                    controller: _current,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Current value',
                        prefixText: '₹ ',
                        hintText: '0')),
              ),
            ]),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100));
                if (d != null) setState(() => _date = d);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Started on', prefixIcon: Icon(Icons.event)),
                child: Text(fmtDay(ymd(_date))),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: Icon(isEdit ? Icons.check : Icons.add),
              label: Text(isEdit ? 'Save' : 'Add investment'),
            ),
          ],
        ),
      ),
    );
  }
}

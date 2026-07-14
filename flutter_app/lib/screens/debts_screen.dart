import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/debt.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

IconData iconForDebt(String type) {
  switch (type) {
    case 'Home loan':
      return Icons.home_outlined;
    case 'Gold loan':
      return Icons.workspace_premium_outlined;
    case 'Personal loan':
      return Icons.person_outline;
    case 'Car loan':
      return Icons.directions_car_outlined;
    case 'Education loan':
      return Icons.school_outlined;
    case 'Credit card':
      return Icons.credit_card;
    case 'Business loan':
      return Icons.business_outlined;
    default:
      return Icons.account_balance_outlined;
  }
}

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<AppModel>();
    final scheme = context.scheme;
    final debts = m.debts;
    return Scaffold(
      appBar: AppBar(title: const Text('Debt tracker')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'debtFab',
        onPressed: () => showDebtEditor(context, m, null),
        icon: const Icon(Icons.add),
        label: const Text('Add loan'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // total outstanding
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
                Text('TOTAL OUTSTANDING',
                    style: context.texts.labelSmall?.copyWith(
                        color: scheme.onPrimary.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text(inr(m.totalOutstanding),
                    style: context.texts.headlineMedium?.copyWith(
                        color: scheme.onPrimary, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('${debts.where((d) => !d.isFullyPaid).length} active loan(s)',
                    style: context.texts.bodySmall?.copyWith(
                        color: scheme.onPrimary.withValues(alpha: 0.9))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (debts.isEmpty)
            _empty(context)
          else
            for (final d in debts) _DebtCard(debt: d),
        ],
      ),
    );
  }

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
          Icon(Icons.account_balance_outlined, size: 44, color: scheme.primary),
          const SizedBox(height: 12),
          Text('No loans tracked',
              style: context.texts.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
              'Add a home, gold, personal or car loan to track the balance, '
              'EMIs, and record each repayment.',
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  const _DebtCard({required this.debt});

  @override
  Widget build(BuildContext context) {
    final m = context.read<AppModel>();
    final scheme = context.scheme;
    final done = debt.isFullyPaid;
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
                child: Icon(iconForDebt(debt.type),
                    color: scheme.onSecondaryContainer, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(debt.name,
                        style: context.texts.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                        '${debt.type}'
                        '${debt.rate > 0 ? ' · ${debt.rate.toStringAsFixed(1)}%' : ''}'
                        '${debt.emi > 0 ? ' · EMI ${inr(debt.emi)}' : ''}',
                        style: context.texts.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  switch (v) {
                    case 'edit':
                      showDebtEditor(context, m, debt);
                      break;
                    case 'close':
                      m.setDebtClosed(debt.id, true);
                      break;
                    case 'reopen':
                      m.setDebtClosed(debt.id, false);
                      break;
                    case 'delete':
                      m.deleteDebt(debt.id);
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (!debt.closed)
                    const PopupMenuItem(
                        value: 'close', child: Text('Mark as paid off'))
                  else
                    const PopupMenuItem(
                        value: 'reopen', child: Text('Reopen')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: done ? 1 : debt.progress,
              minHeight: 10,
              backgroundColor: scheme.surfaceContainerHighest,
              color: done ? context.semantic.positive : scheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  done
                      ? 'Paid off 🎉'
                      : 'Outstanding ${inr(debt.outstanding)}',
                  style: context.texts.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: done ? context.semantic.positive : null)),
              Text('of ${inr(debt.principal)}',
                  style: context.texts.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (debt.startDate.isNotEmpty)
                Text('Taken ${fmtDay(debt.startDate)}',
                    style: context.texts.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              if (debt.lastPaymentDate != null) ...[
                const SizedBox(width: 10),
                Text('Last paid ${fmtDay(debt.lastPaymentDate!)}',
                    style: context.texts.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ],
          ),
          if (!done) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _recordPayment(context, m),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('Record payment'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => _history(context, m),
                  child: Text('History (${debt.payments.length})'),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _history(context, m),
                child: Text('Payment history (${debt.payments.length})'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _recordPayment(BuildContext context, AppModel m) async {
    final amt = TextEditingController(
        text: debt.emi > 0 ? debt.emi.round().toString() : '');
    DateTime date = DateTime.now();
    final result = await showDialog<DebtPayment>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setSt) => AlertDialog(
          title: Text('Record payment · ${debt.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amt,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                    labelText: 'Amount', prefixText: '₹ ', hintText: '0'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text('Paid on ${fmtDay(ymd(date))}')),
                  TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                          context: c,
                          initialDate: date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100));
                      if (d != null) setSt(() => date = d);
                    },
                    child: const Text('Change'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final a = double.tryParse(amt.text.trim()) ?? 0;
                if (a <= 0) return;
                Navigator.pop(c, DebtPayment(date: ymd(date), amount: a));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      await m.addDebtPayment(debt.id, result);
      if (context.mounted &&
          debt.paid + result.amount >= debt.principal) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('That clears the loan — nicely done! 🎉')));
      }
    }
  }

  void _history(BuildContext context, AppModel m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        final live =
            m.debts.firstWhere((d) => d.id == debt.id, orElse: () => debt);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${live.name} · payments',
                    style: context.texts.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (live.payments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('No payments recorded yet.',
                        style: TextStyle(
                            color: context.scheme.onSurfaceVariant)),
                  )
                else
                  ...List.generate(live.payments.length, (i) {
                    final p = live.payments[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(inr(p.amount)),
                      subtitle: Text(fmtDay(p.date)),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: context.semantic.negative),
                        onPressed: () {
                          m.removeDebtPayment(live.id, i);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> showDebtEditor(BuildContext context, AppModel m, Debt? debt) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: ChangeNotifierProvider.value(
        value: m,
        child: _DebtEditorSheet(debt: debt),
      ),
    ),
  );
}

class _DebtEditorSheet extends StatefulWidget {
  final Debt? debt;
  const _DebtEditorSheet({this.debt});
  @override
  State<_DebtEditorSheet> createState() => _DebtEditorSheetState();
}

class _DebtEditorSheetState extends State<_DebtEditorSheet> {
  late final _name = TextEditingController(text: widget.debt?.name ?? '');
  late final _principal = TextEditingController(
      text: widget.debt != null ? widget.debt!.principal.round().toString() : '');
  late final _rate = TextEditingController(
      text: (widget.debt?.rate ?? 0) > 0
          ? widget.debt!.rate.toString()
          : '');
  late final _emi = TextEditingController(
      text: (widget.debt?.emi ?? 0) > 0 ? widget.debt!.emi.round().toString() : '');
  late String _type = widget.debt?.type ?? kDebtTypes.first;
  late DateTime _start =
      DateTime.tryParse(widget.debt?.startDate ?? '') ?? DateTime.now();

  @override
  void dispose() {
    _name.dispose();
    _principal.dispose();
    _rate.dispose();
    _emi.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final principal = double.tryParse(_principal.text.trim()) ?? 0;
    if (_name.text.trim().isEmpty || principal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter a name and a loan amount greater than 0.')));
      return;
    }
    await context.read<AppModel>().saveDebt(Debt(
          id: widget.debt?.id ?? '',
          name: _name.text.trim(),
          type: _type,
          principal: principal,
          rate: double.tryParse(_rate.text.trim()) ?? 0,
          emi: double.tryParse(_emi.text.trim()) ?? 0,
          startDate: ymd(_start),
          payments: widget.debt?.payments ?? const [],
          closed: widget.debt?.closed ?? false,
        ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.debt != null;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isEdit ? 'Edit loan' : 'Add a loan',
                style: context.texts.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _type,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Type', prefixIcon: Icon(Icons.category_outlined)),
              items: kDebtTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? kDebtTypes.first),
            ),
            const SizedBox(height: 12),
            TextField(
                controller: _name,
                decoration: const InputDecoration(
                    labelText: 'Name', hintText: 'e.g. SBI home loan')),
            const SizedBox(height: 12),
            TextField(
                controller: _principal,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Loan amount', prefixText: '₹ ', hintText: '0')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                    controller: _rate,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Interest %', hintText: 'optional')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                    controller: _emi,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'EMI', prefixText: '₹ ', hintText: 'optional')),
              ),
            ]),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                    context: context,
                    initialDate: _start,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100));
                if (d != null) setState(() => _start = d);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Loan taken on', prefixIcon: Icon(Icons.event)),
                child: Text(fmtDay(ymd(_start))),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: Icon(isEdit ? Icons.check : Icons.add),
              label: Text(isEdit ? 'Save loan' : 'Add loan'),
            ),
          ],
        ),
      ),
    );
  }
}

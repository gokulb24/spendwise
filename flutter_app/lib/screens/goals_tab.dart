import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/goal.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

class GoalsTab extends StatelessWidget {
  const GoalsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<AppModel>();
    final scheme = context.scheme;
    final emergency = m.goals.where((g) => g.isEmergency).toList();
    final savings = m.goals.where((g) => !g.isEmergency).toList();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text('Goals',
              style: context.texts.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Save towards what matters to your family.',
              style: context.texts.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          if (m.goals.isEmpty)
            _EmptyState(),
          if (emergency.isNotEmpty) ...[
            _sectionLabel(context, 'Emergency Fund'),
            for (final g in emergency) _GoalCard(goal: g),
            const SizedBox(height: 8),
          ],
          if (savings.isNotEmpty) ...[
            _sectionLabel(context, 'Savings Goals'),
            for (final g in savings) _GoalCard(goal: g),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'goalsFab',
        onPressed: () => showGoalEditor(context, m, null),
        icon: const Icon(Icons.add),
        label: const Text('New goal'),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(t,
            style: context.texts.titleSmall?.copyWith(
                color: context.scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700)),
      );
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.savings_outlined, size: 44, color: scheme.primary),
          const SizedBox(height: 12),
          Text('No goals yet',
              style: context.texts.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
              'Create a savings goal (a car, a trip, school fees) or an '
              'emergency fund, and track your progress as a family.',
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final m = context.read<AppModel>();
    final scheme = context.scheme;
    final done = goal.progress >= 1;
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(
                    goal.isEmergency
                        ? Icons.health_and_safety_outlined
                        : Icons.flag_outlined,
                    color: scheme.onSecondaryContainer,
                    size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name,
                        style: context.texts.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (goal.deadline != null)
                      Text('by ${monthLabel(goal.deadline!.substring(0, 7))}',
                          style: context.texts.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') showGoalEditor(context, m, goal);
                  if (v == 'delete') _confirmDelete(context, m);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 10,
              backgroundColor: scheme.surfaceContainerHighest,
              color: done ? context.semantic.positive : scheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${inr(goal.saved)} of ${inr(goal.target)}',
                  style: context.texts.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Text(
                  done
                      ? 'Reached 🎉'
                      : '${(goal.progress * 100).round()}%',
                  style: context.texts.labelLarge?.copyWith(
                      color: done
                          ? context.semantic.positive
                          : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _contribute(context, m),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add money'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _contribute(BuildContext context, AppModel m) async {
    final ctrl = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Add to "${goal.name}"'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(c, double.tryParse(ctrl.text.trim())),
              child: const Text('Add')),
        ],
      ),
    );
    if (amount != null && amount > 0) {
      await m.contributeToGoal(goal.id, amount);
    }
  }

  Future<void> _confirmDelete(BuildContext context, AppModel m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete "${goal.name}"?'),
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
    );
    if (ok == true) m.deleteGoal(goal.id);
  }
}

/// Add/edit a goal via a bottom sheet.
Future<void> showGoalEditor(BuildContext context, AppModel m, Goal? goal) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: ChangeNotifierProvider.value(
        value: m,
        child: _GoalEditorSheet(goal: goal),
      ),
    ),
  );
}

class _GoalEditorSheet extends StatefulWidget {
  final Goal? goal;
  const _GoalEditorSheet({this.goal});
  @override
  State<_GoalEditorSheet> createState() => _GoalEditorSheetState();
}

class _GoalEditorSheetState extends State<_GoalEditorSheet> {
  late final _name = TextEditingController(text: widget.goal?.name ?? '');
  late final _target = TextEditingController(
      text: widget.goal != null ? widget.goal!.target.round().toString() : '');
  late final _saved = TextEditingController(
      text: (widget.goal?.saved ?? 0) > 0
          ? widget.goal!.saved.round().toString()
          : '');
  late String _type = widget.goal?.type ?? 'savings';
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    if (widget.goal?.deadline != null) {
      _deadline = DateTime.tryParse(widget.goal!.deadline!);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _saved.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final target = double.tryParse(_target.text.trim()) ?? 0;
    if (_name.text.trim().isEmpty || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter a name and a target greater than 0.')));
      return;
    }
    await context.read<AppModel>().saveGoal(Goal(
          id: widget.goal?.id ?? '',
          name: _name.text.trim(),
          type: _type,
          target: target,
          saved: double.tryParse(_saved.text.trim()) ?? 0,
          deadline: _deadline != null ? ymd(_deadline!) : null,
        ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.goal != null;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isEdit ? 'Edit goal' : 'New goal',
                style: context.texts.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'savings',
                    icon: Icon(Icons.flag_outlined),
                    label: Text('Savings')),
                ButtonSegment(
                    value: 'emergency',
                    icon: Icon(Icons.health_and_safety_outlined),
                    label: Text('Emergency')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
                controller: _name,
                decoration: const InputDecoration(
                    labelText: 'Goal name', hintText: 'e.g. New car')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                    controller: _target,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Target', prefixText: '₹ ', hintText: '0')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                    controller: _saved,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Saved so far',
                        prefixText: '₹ ',
                        hintText: '0')),
              ),
            ]),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _deadline ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => _deadline = d);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Target date (optional)',
                    prefixIcon: Icon(Icons.event)),
                child: Text(_deadline != null
                    ? fmtDay(ymd(_deadline!))
                    : 'No deadline'),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: Icon(isEdit ? Icons.check : Icons.add),
              label: Text(isEdit ? 'Save goal' : 'Create goal'),
            ),
          ],
        ),
      ),
    );
  }
}

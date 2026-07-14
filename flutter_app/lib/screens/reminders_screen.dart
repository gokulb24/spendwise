import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reminder.dart';
import '../services/notification_service.dart';
import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});
  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with WidgetsBindingObserver {
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.requestPermission();
      _refreshEnabled();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check after the user returns from the system settings screen.
    if (state == AppLifecycleState.resumed) _refreshEnabled();
  }

  Future<void> _refreshEnabled() async {
    final on = await NotificationService.areEnabled();
    if (mounted && on != _enabled) setState(() => _enabled = on);
  }

  @override
  Widget build(BuildContext context) {
    final m = context.watch<AppModel>();
    final overdue = m.reminders.where((r) => r.isOverdue).toList();
    final upcoming = m.reminders.where((r) => r.isPending).toList();
    final done = m.reminders.where((r) => r.done).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'remFab',
        onPressed: () => showReminderEditor(context, m, null),
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: Column(
        children: [
          if (!_enabled) _permissionBanner(context),
          Expanded(
            child: m.reminders.isEmpty
                ? _empty(context)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    children: [
                      if (overdue.isNotEmpty) ...[
                        _label(context, 'Overdue',
                            color: context.semantic.negative),
                        for (final r in overdue) _ReminderTile(r: r),
                        const SizedBox(height: 8),
                      ],
                      if (upcoming.isNotEmpty) ...[
                        _label(context, 'Upcoming'),
                        for (final r in upcoming) _ReminderTile(r: r),
                        const SizedBox(height: 8),
                      ],
                      if (done.isNotEmpty) ...[
                        _label(context, 'Done'),
                        for (final r in done) _ReminderTile(r: r),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _permissionBanner(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.semantic.warningContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_off_outlined, color: context.semantic.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notifications are turned off',
                    style: context.texts.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text('Reminders can\'t alert you until you allow notifications.',
                    style: context.texts.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => NotificationService.openNotificationSettings(),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String t, {Color? color}) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 6),
        child: Text(t,
            style: context.texts.titleSmall?.copyWith(
                color: color ?? context.scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700)),
      );

  Widget _empty(BuildContext context) {
    final scheme = context.scheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 48, color: scheme.primary),
            const SizedBox(height: 12),
            Text('No reminders yet',
                style: context.texts.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
                'Add things like "Buy groceries today" or "Pay the phone bill" '
                'and get a notification when they\'re due.',
                textAlign: TextAlign.center,
                style: context.texts.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final Reminder r;
  const _ReminderTile({required this.r});
  @override
  Widget build(BuildContext context) {
    final m = context.read<AppModel>();
    final scheme = context.scheme;
    final t = TimeOfDay(hour: r.hour, minute: r.minute).format(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
        leading: Checkbox(
          value: r.done,
          onChanged: (v) => m.setReminderDone(r.id, v ?? false),
        ),
        title: Text(r.title,
            style: TextStyle(
                decoration: r.done ? TextDecoration.lineThrough : null,
                fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${fmtDay(r.date)} · $t${r.note.isNotEmpty ? ' · ${r.note}' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.bodySmall?.copyWith(
                color: r.isOverdue
                    ? context.semantic.negative
                    : scheme.onSurfaceVariant)),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') showReminderEditor(context, m, r);
            if (v == 'delete') m.deleteReminder(r.id);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => showReminderEditor(context, m, r),
      ),
      ),
    );
  }
}

Future<void> showReminderEditor(BuildContext context, AppModel m, Reminder? r) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: ChangeNotifierProvider.value(
        value: m,
        child: _ReminderEditorSheet(reminder: r),
      ),
    ),
  );
}

class _ReminderEditorSheet extends StatefulWidget {
  final Reminder? reminder;
  const _ReminderEditorSheet({this.reminder});
  @override
  State<_ReminderEditorSheet> createState() => _ReminderEditorSheetState();
}

class _ReminderEditorSheetState extends State<_ReminderEditorSheet> {
  late final _title = TextEditingController(text: widget.reminder?.title ?? '');
  late final _note = TextEditingController(text: widget.reminder?.note ?? '');
  late DateTime _date =
      DateTime.tryParse(widget.reminder?.date ?? '') ?? DateTime.now();
  late TimeOfDay _time = widget.reminder != null
      ? TimeOfDay(hour: widget.reminder!.hour, minute: widget.reminder!.minute)
      : const TimeOfDay(hour: 9, minute: 0);

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter what to be reminded about.')));
      return;
    }
    final model = context.read<AppModel>();
    await NotificationService.requestPermission();
    await model.saveReminder(Reminder(
          id: widget.reminder?.id ?? '',
          title: _title.text.trim(),
          note: _note.text.trim(),
          date: ymd(_date),
          hour: _time.hour,
          minute: _time.minute,
          done: widget.reminder?.done ?? false,
        ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.reminder != null;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isEdit ? 'Edit reminder' : 'New reminder',
                style: context.texts.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
                controller: _title,
                autofocus: !isEdit,
                decoration: const InputDecoration(
                    labelText: 'Remind me to…',
                    hintText: 'e.g. Buy a birthday gift')),
            const SizedBox(height: 12),
            TextField(
                controller: _note,
                decoration: const InputDecoration(
                    labelText: 'Note (optional)')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
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
                child: InkWell(
                  onTap: () async {
                    final t = await showTimePicker(
                        context: context, initialTime: _time);
                    if (t != null) setState(() => _time = t);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Time',
                        prefixIcon: Icon(Icons.schedule)),
                    child: Text(_time.format(context)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: Icon(isEdit ? Icons.check : Icons.notifications_active),
              label: Text(isEdit ? 'Save reminder' : 'Set reminder'),
            ),
          ],
        ),
      ),
    );
  }
}

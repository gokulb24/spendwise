import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'reminders_screen.dart';
import 'settings_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _name = TextEditingController();
  final _members = TextEditingController();
  bool _editing = false;

  @override
  void dispose() {
    _name.dispose();
    _members.dispose();
    super.dispose();
  }

  void _startEdit(AppModel m) {
    _name.text = m.family?.name ?? '';
    _members.text = m.members.join('\n');
    setState(() => _editing = true);
  }

  Future<void> _save(AppModel m) async {
    final members = _members.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keep at least one member name.')));
      return;
    }
    await m.updateFamily(
        _name.text.trim().isEmpty ? 'Family' : _name.text.trim(), members);
    if (mounted) setState(() => _editing = false);
  }

  /// A tappable navigation row used for Money tools / Settings / Reminders.
  Widget _navCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final scheme = context.scheme;
    return Card(
      color: scheme.surfaceContainerLow,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.secondaryContainer,
          child: Icon(icon, color: scheme.onSecondaryContainer),
        ),
        title: Text(title),
        subtitle: Text(subtitle,
            style: context.texts.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = context.watch<AppModel>();
    final scheme = context.scheme;
    final initial = (m.user?.displayName?.trim().isNotEmpty ?? false)
        ? m.user!.displayName!.trim()[0].toUpperCase()
        : '?';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // account card
        Card(
          color: scheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(initial,
                      style: context.texts.titleLarge?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.user?.displayName ?? 'Member',
                          style: context.texts.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(m.user?.email ?? '',
                          style: context.texts.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // family management
        SectionCard(
          title: 'Family',
          trailing: _editing
              ? null
              : IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _startEdit(m)),
          child: _editing
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                        controller: _name,
                        decoration:
                            const InputDecoration(labelText: 'Family name')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: _members,
                        minLines: 3,
                        maxLines: 8,
                        decoration: const InputDecoration(
                            labelText: 'Members (one per line)',
                            alignLabelWithHint: true)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                              onPressed: () =>
                                  setState(() => _editing = false),
                              child: const Text('Cancel')),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                              onPressed: () => _save(m),
                              child: const Text('Save')),
                        ),
                      ],
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kv(context, 'Name', m.family?.name ?? '—'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Invite code',
                                  style: context.texts.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant)),
                              Text(m.family?.inviteCode ?? '——————',
                                  style: context.texts.titleLarge?.copyWith(
                                      letterSpacing: 3,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(
                                text: m.family?.inviteCode ?? ''));
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Invite code copied')));
                          },
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Copy'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Members',
                        style: context.texts.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final mb in m.members)
                          Chip(
                            label: Text(mb),
                            avatar: CircleAvatar(
                              backgroundColor: scheme.secondaryContainer,
                              child: Text(
                                  mb.isNotEmpty ? mb[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 14),
        // settings
        _navCard(
          context,
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'Appearance, app lock, notifications',
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
        const SizedBox(height: 10),
        // reminders (kept separate, below settings)
        _navCard(
          context,
          icon: Icons.notifications_active_outlined,
          title: 'Reminders',
          subtitle: m.pendingReminders.isEmpty
              ? 'Get notified — "buy this today" etc.'
              : '${m.pendingReminders.length} pending${m.overdueReminders.isNotEmpty ? ' · ${m.overdueReminders.length} overdue' : ''}',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                  value: m, child: const RemindersScreen()))),
        ),
        const SizedBox(height: 14),
        FilledButton.tonalIcon(
          style: FilledButton.styleFrom(
            backgroundColor: context.semantic.negativeContainer,
            foregroundColor: context.semantic.negative,
          ),
          onPressed: () => m.signOut(),
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
        ),
      ],
    );
  }

  Widget _kv(BuildContext context, String k, String v) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k,
              style: context.texts.bodyMedium
                  ?.copyWith(color: context.scheme.onSurfaceVariant)),
          Text(v,
              style: context.texts.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      );
}

/// Full-screen Profile, pushed from the top-bar avatar.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const ProfileTab(),
    );
  }
}

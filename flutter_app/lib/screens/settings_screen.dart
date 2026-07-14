import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_lock.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/common.dart';

/// App-wide settings: appearance, app lock, notifications and about.
/// Opened from the Profile tab.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool? _notifOn; // null = still checking

  @override
  void initState() {
    super.initState();
    _refreshNotif();
  }

  Future<void> _refreshNotif() async {
    final on = await NotificationService.areEnabled();
    if (mounted) setState(() => _notifOn = on);
  }

  Future<void> _toggleLock(bool value) async {
    final lock = context.read<AppLock>();
    final messenger = ScaffoldMessenger.of(context);
    if (value) {
      if (!await lock.deviceCanAuthenticate()) {
        messenger.showSnackBar(const SnackBar(
            duration: Duration(seconds: 5),
            content: Text('Set up a fingerprint or screen lock (PIN/password) '
                'on your phone first, then enable this.')));
        return;
      }
      await lock.setEnabled(true);
      final ok = await lock.authenticate(); // confirm it works
      if (!ok) {
        await lock.setEnabled(false); // couldn't verify — leave it off
        messenger.showSnackBar(const SnackBar(
            content: Text('Couldn\'t verify — app lock left off.')));
      } else {
        messenger.showSnackBar(const SnackBar(
            content:
                Text('App lock on. You\'ll unlock each time you open the app.')));
      }
    } else {
      await lock.setEnabled(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final scheme = context.scheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ---- Appearance ----------------------------------------------------
          SectionCard(
            title: 'Appearance',
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto),
                    label: Text('Auto')),
                ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode),
                    label: Text('Light')),
                ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode),
                    label: Text('Dark')),
              ],
              selected: {theme.mode},
              onSelectionChanged: (s) => theme.setMode(s.first),
            ),
          ),
          const SizedBox(height: 14),
          // ---- Security ------------------------------------------------------
          SectionCard(
            title: 'Security',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(Icons.fingerprint, color: scheme.primary),
              title: const Text('App lock'),
              subtitle: Text('Require fingerprint or PIN to open the app',
                  style: context.texts.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              value: context.watch<AppLock>().enabled,
              onChanged: (v) => _toggleLock(v),
            ),
          ),
          const SizedBox(height: 14),
          // ---- Notifications -------------------------------------------------
          SectionCard(
            title: 'Notifications',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                        _notifOn == false
                            ? Icons.notifications_off_outlined
                            : Icons.notifications_active_outlined,
                        color: _notifOn == false
                            ? context.semantic.negative
                            : scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          _notifOn == null
                              ? 'Checking…'
                              : _notifOn!
                                  ? 'On — your reminders can alert you.'
                                  : 'Blocked — turn on to get reminder alerts.',
                          style: context.texts.bodyMedium),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await NotificationService.openNotificationSettings();
                    await _refreshNotif();
                  },
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('System notification settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // ---- About ---------------------------------------------------------
          SectionCard(
            title: 'About',
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.asset('assets/logo.png',
                      width: 44, height: 44, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SpendWise',
                        style: context.texts.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text('Version 1.0.0',
                        style: context.texts.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

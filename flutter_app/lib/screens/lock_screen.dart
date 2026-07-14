import 'package:flutter/material.dart';

import '../services/app_lock.dart';
import '../theme/app_theme.dart';

/// Full-screen lock shown until the user passes fingerprint / PIN.
class LockScreen extends StatefulWidget {
  final AppLock lock;
  const LockScreen({super.key, required this.lock});
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prompt());
  }

  Future<void> _prompt() async {
    final ok = await widget.lock.authenticate();
    if (mounted) setState(() => _failed = !ok);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline,
                    size: 40, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: 20),
              Text('SpendWise is locked',
                  style: context.texts.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Unlock with your fingerprint or phone PIN.',
                  textAlign: TextAlign.center,
                  style: context.texts.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _prompt,
                icon: const Icon(Icons.fingerprint),
                label: Text(_failed ? 'Try again' : 'Unlock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

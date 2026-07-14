import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/lock_screen.dart';
import '../services/app_lock.dart';

/// Wraps the app: shows the lock screen whenever the lock is engaged, and
/// re-locks when the app returns from the background.
class AppLockGate extends StatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});
  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool _wasPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lock = context.read<AppLock>();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _wasPaused = true;
    } else if (state == AppLifecycleState.resumed && _wasPaused) {
      _wasPaused = false;
      lock.relockIfEnabled(); // require auth again after returning
    }
  }

  @override
  Widget build(BuildContext context) {
    final lock = context.watch<AppLock>();
    return Stack(
      children: [
        widget.child,
        if (lock.locked)
          Positioned.fill(child: LockScreen(lock: lock)),
      ],
    );
  }
}

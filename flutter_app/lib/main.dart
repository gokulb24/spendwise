import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/family_screen.dart';
import 'screens/home_shell.dart';
import 'services/app_lock.dart';
import 'state/app_model.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'widgets/app_lock_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = ThemeController();
  await themeController.load();
  final appLock = AppLock();
  await appLock.load();
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    // serverClientId = the project's WEB OAuth client id, required so Google
    // Sign-In returns an ID token that Firebase Auth accepts on Android.
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '765758847064-h4mo5jv29ctu3m6errbfhu0k6upv4a71.apps.googleusercontent.com',
    );
    firebaseReady = true;
  } catch (_) {
    firebaseReady = false; // keys not filled in yet — see BUILD-ANDROID.md
  }
  runApp(FamilyExpenseApp(
      firebaseReady: firebaseReady,
      themeController: themeController,
      appLock: appLock));
}

class FamilyExpenseApp extends StatelessWidget {
  final bool firebaseReady;
  final ThemeController themeController;
  final AppLock appLock;
  const FamilyExpenseApp(
      {super.key,
      required this.firebaseReady,
      required this.themeController,
      required this.appLock});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider.value(value: appLock),
      ],
      child: DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          final lightScheme = lightDynamic ??
              ColorScheme.fromSeed(seedColor: kBrandSeed);
          final darkScheme = darkDynamic ??
              ColorScheme.fromSeed(
                  seedColor: kBrandSeed, brightness: Brightness.dark);
          return Consumer<ThemeController>(
            builder: (context, tc, _) => MaterialApp(
              title: 'SpendWise',
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(lightScheme),
              darkTheme: buildAppTheme(darkScheme),
              themeMode: tc.mode,
              home: AppLockGate(
                child: firebaseReady
                    ? ChangeNotifierProvider(
                        create: (_) => AppModel(), child: const _AuthGate())
                    : const _NotConfigured(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();
  @override
  Widget build(BuildContext context) {
    final model = context.watch<AppModel>();
    switch (model.stage) {
      case AppStage.loading:
        return const Scaffold(
            body: Center(child: CircularProgressIndicator()));
      case AppStage.signedOut:
        return const AuthScreen();
      case AppStage.needFamily:
        return const FamilyScreen();
      case AppStage.ready:
        return const HomeShell();
      case AppStage.loadError:
        return _LoadError(onRetry: model.retry);
    }
  }
}

class _LoadError extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _LoadError({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48),
              const SizedBox(height: 16),
              const Text("Couldn't load your account",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              const Text(
                'Check your internet connection and try again. '
                'Your data is safe.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotConfigured extends StatelessWidget {
  const _NotConfigured();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.cloud_off, size: 48),
              SizedBox(height: 16),
              Text('Firebase not configured yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              SizedBox(height: 10),
              Text(
                'Run "flutterfire configure" to connect your Firebase '
                'project, then rebuild. See BUILD-ANDROID.md.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

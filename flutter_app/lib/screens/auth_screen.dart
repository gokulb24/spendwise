import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../state/app_model.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _signUp = false;
  bool _busy = false;
  String? _error;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  String _nice(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'user-not-found':
          return 'No account found with that email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email or password is incorrect.';
        case 'email-already-in-use':
          return 'That email already has an account — try signing in.';
        case 'weak-password':
          return 'Password should be at least 6 characters.';
        case 'too-many-requests':
          return 'Too many attempts — wait a minute and try again.';
        case 'network-request-failed':
          return 'Network problem — check your connection.';
      }
      return e.message ?? 'Something went wrong.';
    }
    return 'Something went wrong.';
  }

  Future<void> _submit() async {
    final m = context.read<AppModel>();
    final email = _email.text.trim();
    final pass = _pass.text;
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      if (_signUp) {
        if (_name.text.trim().isEmpty) throw _Msg('Enter your name.');
        if (email.isEmpty || pass.length < 6) {
          throw _Msg('Enter an email and a password of at least 6 characters.');
        }
        await m.signUp(_name.text.trim(), email, pass);
      } else {
        if (email.isEmpty || pass.isEmpty) {
          throw _Msg('Enter your email and password.');
        }
        await m.signIn(email, pass);
      }
    } catch (e) {
      setState(() => _error = e is _Msg ? e.text : _nice(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await context.read<AppModel>().signInWithGoogle();
    } catch (e) {
      if (e is GoogleSignInException &&
          e.code == GoogleSignInExceptionCode.canceled) {
        // user closed the picker — not an error
      } else {
        setState(() => _error = _nice(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Type your email first, then tap Forgot password.');
      return;
    }
    try {
      await context.read<AppModel>().sendReset(email);
      setState(() => _error = 'Password-reset email sent to $email.');
    } catch (e) {
      setState(() => _error = _nice(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo only, sitting a little up the screen.
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset('assets/logo.png',
                          width: 132, height: 132, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.semantic.negativeContainer,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(_error!,
                          style: TextStyle(
                              color: context.semantic.negative,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_signUp) ...[
                    TextField(
                        controller: _name,
                        decoration:
                            const InputDecoration(labelText: 'Your name')),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: _pass,
                      obscureText: true,
                      decoration: InputDecoration(
                          labelText: _signUp
                              ? 'Password (min 6 characters)'
                              : 'Password')),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: scheme.onPrimary))
                        : Text(_signUp ? 'Create account' : 'Sign in'),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('or',
                            style:
                                TextStyle(color: scheme.onSurfaceVariant))),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _google,
                    icon: const Icon(Icons.g_mobiledata, size: 26),
                    label: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (!_signUp)
                        TextButton(
                            onPressed: _reset,
                            child: const Text('Forgot password?'))
                      else
                        const SizedBox(),
                      TextButton(
                        onPressed: () => setState(() {
                          _signUp = !_signUp;
                          _error = null;
                        }),
                        child: Text(_signUp
                            ? 'Have an account? Sign in'
                            : 'Create an account'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Msg implements Exception {
  final String text;
  _Msg(this.text);
}

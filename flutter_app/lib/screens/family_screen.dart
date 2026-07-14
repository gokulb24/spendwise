import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_model.dart';
import '../theme/app_theme.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});
  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final _famName = TextEditingController();
  late final _members = TextEditingController(
      text: context.read<AppModel>().user?.displayName ?? '');
  final _code = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _famName.dispose();
    _members.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _famName.text.trim();
    final members = _members.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (name.isEmpty) return setState(() => _error = 'Give your family a name.');
    if (members.isEmpty) {
      return setState(() => _error = 'Add at least one member name.');
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AppModel>().createFamily(name, members);
    } catch (e) {
      setState(() => _error = 'Could not create family. $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final code = _code.text.trim();
    if (code.length < 4) {
      return setState(() => _error = 'Enter the invite code from your family.');
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final err = await context.read<AppModel>().joinFamily(code);
      if (err != null) setState(() => _error = err);
    } catch (e) {
      setState(() => _error = 'Could not join. $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = context.watch<AppModel>();
    final scheme = context.scheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your family'),
        actions: [
          TextButton(
            onPressed: () => m.signOut(),
            child: const Text('Log out'),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(
                      'Signed in as ${m.user?.email ?? ''}. Create your family, '
                      'or join one your relative already made.',
                      style: TextStyle(color: scheme.onSecondaryContainer)),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: context.semantic.negativeContainer,
                        borderRadius: BorderRadius.circular(9)),
                    child: Text(_error!,
                        style: TextStyle(
                            color: context.semantic.negative,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
                const SizedBox(height: 18),
                Text('Create a new family',
                    style: context.texts.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                TextField(
                    controller: _famName,
                    decoration: const InputDecoration(
                        labelText: 'Family name',
                        hintText: 'e.g. The Sharmas')),
                const SizedBox(height: 10),
                TextField(
                    controller: _members,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                        labelText: 'Member names (one per line)',
                        alignLabelWithHint: true)),
                const SizedBox(height: 6),
                Text(
                    'These are the people whose spending you track. '
                    'You can change them later.',
                    style: context.texts.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy ? null : _create,
                  child: const Text('Create family'),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('or join an existing family',
                          style: TextStyle(color: scheme.onSurfaceVariant))),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 16),
                TextField(
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                        labelText: 'Invite code',
                        hintText: '6-character code')),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: _busy ? null : _join,
                  child: const Text('Join family'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

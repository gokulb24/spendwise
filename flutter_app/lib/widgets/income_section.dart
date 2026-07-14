import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_model.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'common.dart';

class IncomeSection extends StatelessWidget {
  const IncomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.watch<AppModel>();
    final income = m.currentIncome;
    final scheme = context.scheme;
    return SectionCard(
      title: 'Monthly Income by Member',
      subtitle: '· ${monthLabel(m.currentMonth)}',
      child: LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth >= 640 ? 3 : 2;
        return Column(
          children: [
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 74,
              ),
              children: [
                for (final mb in m.members)
                  _IncomeField(member: mb, value: income[mb] ?? 0),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text('Total Income',
                      style: context.texts.titleSmall?.copyWith(
                          color: scheme.onSecondaryContainer,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(inr(m.summary.income),
                          style: context.texts.titleLarge?.copyWith(
                              color: scheme.onSecondaryContainer,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _IncomeField extends StatefulWidget {
  final String member;
  final double value;
  const _IncomeField({required this.member, required this.value});
  @override
  State<_IncomeField> createState() => _IncomeFieldState();
}

class _IncomeFieldState extends State<_IncomeField> {
  // Show 0 as a placeholder (hint) rather than a literal "0" the user must clear.
  late final TextEditingController _c = TextEditingController(
      text: widget.value > 0 ? widget.value.round().toString() : '');

  @override
  void didUpdateWidget(covariant _IncomeField old) {
    super.didUpdateWidget(old);
    final t = widget.value > 0 ? widget.value.round().toString() : '';
    if (!_c.selection.isValid && _c.text != t) _c.text = t;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = context.read<AppModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(widget.member,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.labelSmall?.copyWith(
                color: context.scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        TextField(
          controller: _c,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: '₹ ', hintText: '0'),
          onSubmitted: (v) =>
              m.setIncome(widget.member, double.tryParse(v.trim()) ?? 0),
          onTapOutside: (_) =>
              m.setIncome(widget.member, double.tryParse(_c.text.trim()) ?? 0),
        ),
      ],
    );
  }
}

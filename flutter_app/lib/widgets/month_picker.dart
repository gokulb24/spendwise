import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';

/// A calendar-style month/year picker with no range limit — pick any month.
/// Returns a `yyyy-MM` string, or null if dismissed.
Future<String?> showMonthPicker(BuildContext context, String current) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _MonthPickerSheet(current: current),
  );
}

class _MonthPickerSheet extends StatefulWidget {
  final String current;
  const _MonthPickerSheet({required this.current});
  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year;
  late int _selMonth; // 1..12 of the selected yyyy-MM
  late int _selYear;

  @override
  void initState() {
    super.initState();
    final parts = widget.current.split('-');
    _selYear = int.tryParse(parts[0]) ?? DateTime.now().year;
    _selMonth = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;
    _year = _selYear;
  }

  String _key(int y, int m) => '$y-${m.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisYm = ym(now);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select month',
                style: context.texts.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            // year navigator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filledTonal(
                  onPressed: () => setState(() => _year--),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('$_year',
                    style: context.texts.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                IconButton.filledTonal(
                  onPressed: () => setState(() => _year++),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.1,
              children: [
                for (var m = 1; m <= 12; m++)
                  _MonthCell(
                    label: DateFormat('MMM').format(DateTime(_year, m)),
                    selected: _year == _selYear && m == _selMonth,
                    isCurrent: _key(_year, m) == thisYm,
                    onTap: () => Navigator.pop(context, _key(_year, m)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context, thisYm),
                icon: const Icon(Icons.today, size: 18),
                label: const Text('This month'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isCurrent;
  final VoidCallback onTap;
  const _MonthCell({
    required this.label,
    required this.selected,
    required this.isCurrent,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: isCurrent && !selected
                ? Border.all(color: scheme.primary, width: 1.5)
                : null,
          ),
          child: Text(label,
              style: context.texts.titleSmall?.copyWith(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

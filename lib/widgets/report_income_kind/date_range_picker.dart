import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateRangePicker extends StatelessWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final Function(DateTime?, DateTime?) onRangeSelected;

  const DateRangePicker({
    Key? key,
    required this.fromDate,
    required this.toDate,
    required this.onRangeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _selectDateRange(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getDateRangeText(),
                  style: TextStyle(
                    fontSize: 14,
                    color: (fromDate != null && toDate != null)
                        ? Colors.black87
                        : Colors.grey.shade500,
                  ),
                ),
              ),
              Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }

  String _getDateRangeText() {
    if (fromDate != null && toDate != null) {
      return '${DateFormat('yyyy/MM/dd').format(fromDate!)} - ${DateFormat('yyyy/MM/dd').format(toDate!)}';
    }
    return 'اختر الفترة الزمنية';
  }

  Future<void> _selectDateRange(BuildContext context) async {
    try {
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 1)),
        initialDateRange: (fromDate != null && toDate != null)
            ? DateTimeRange(start: fromDate!, end: toDate!)
            : DateTimeRange(
                start: DateTime.now().subtract(const Duration(days: 30)),
                end: DateTime.now(),
              ),
      );

      if (picked != null) {
        onRangeSelected(picked.start, picked.end);
      }
    } catch (e) {
      debugPrint('❌ خطأ في اختيار التاريخ: $e');
    }
  }
}
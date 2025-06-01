import 'package:flutter/material.dart';

class DateSelector extends StatefulWidget {
  final ValueChanged<DateTime> onDateChanged;
  final DateTime? initialDate;

  const DateSelector({
    super.key,
    required this.onDateChanged,
    this.initialDate,
  });

  @override
  State<DateSelector> createState() => _DateSelectorState();
}

class _DateSelectorState extends State<DateSelector> {
  late int selectedDay;
  late int selectedMonth;
  late int selectedYear;

  @override
  void initState() {
    super.initState();
    final date = widget.initialDate ?? DateTime(2000);
    selectedDay = date.day;
    selectedMonth = date.month;
    selectedYear = date.year;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            value: selectedDay,
            items: List.generate(31, (i) => i + 1)
                .map((day) => DropdownMenuItem(
                      value: day,
                      child: Text(day.toString()),
                    ))
                .toList(),
            onChanged: (day) {
              if (day != null) {
                setState(() => selectedDay = day);
                _notifyDateChange();
              }
            },
            decoration: const InputDecoration(labelText: 'Día'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: selectedMonth,
            items: List.generate(12, (i) => i + 1)
                .map((month) => DropdownMenuItem(
                      value: month,
                      child: Text(month.toString()),
                    ))
                .toList(),
            onChanged: (month) {
              if (month != null) {
                setState(() => selectedMonth = month);
                _notifyDateChange();
              }
            },
            decoration: const InputDecoration(labelText: 'Mes'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: selectedYear,
            items: List.generate(
              DateTime.now().year - 1899,
              (i) => 1900 + i,
            )
                .map((year) => DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    ))
                .toList(),
            onChanged: (year) {
              if (year != null) {
                setState(() => selectedYear = year);
                _notifyDateChange();
              }
            },
            decoration: const InputDecoration(labelText: 'Año'),
          ),
        ),
      ],
    );
  }

  void _notifyDateChange() {
    widget.onDateChanged(DateTime(selectedYear, selectedMonth, selectedDay));
  }
}
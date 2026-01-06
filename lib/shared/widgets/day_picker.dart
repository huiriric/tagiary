import 'package:flutter/material.dart';

class DayPicker extends StatefulWidget {
  final List<bool> selectedDays;
  final Function(List<bool>) onDaysChanged;

  const DayPicker({
    super.key,
    required this.selectedDays,
    required this.onDaysChanged,
  });

  @override
  State<DayPicker> createState() => _DayPickerState();
}

class _DayPickerState extends State<DayPicker> {
  late List<bool> _selectedDays;
  final List<String> _dayLabels = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  void initState() {
    super.initState();
    _selectedDays = List.from(widget.selectedDays);
    if (_selectedDays.length != 7) {
      _selectedDays = List.generate(7, (index) => false);
    }
  }

  @override
  void didUpdateWidget(DayPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDays != oldWidget.selectedDays) {
      _selectedDays = List.from(widget.selectedDays);
    }
  }

  void _toggleDay(int index) {
    setState(() {
      _selectedDays[index] = !_selectedDays[index];
      widget.onDaysChanged(_selectedDays);
    });
  }

  Color _getDayColor(int index, bool isSelected) {
    if (!isSelected) return Colors.transparent;

    // 일요일 (0) - 빨강
    if (index == 0) return Colors.red.shade400;
    // 토요일 (6) - 파랑
    if (index == 6) return Colors.blue.shade400;
    // 평일 - 검정
    return Colors.black87;
  }

  Color _getBorderColor(int index, bool isSelected) {
    if (isSelected) return Colors.transparent;

    // 일요일 - 빨강 테두리
    // if (index == 0) return Colors.red.shade200;
    // 토요일 - 파랑 테두리
    // if (index == 6) return Colors.blue.shade200;
    // 평일 - 회색 테두리
    return Colors.grey.shade300;
  }

  Color _getTextColor(int index, bool isSelected) {
    if (isSelected) return Colors.white;

    // 일요일 - 빨강 텍스트
    // if (index == 0) return Colors.red.shade300;
    // 토요일 - 파랑 텍스트
    // if (index == 6) return Colors.blue.shade300;
    // 평일 - 회색 텍스트
    return Colors.grey.shade600;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            '반복 요일',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            7,
            (index) => _buildDayButton(index),
          ),
        ),
      ],
    );
  }

  Widget _buildDayButton(int index) {
    final bool isSelected = _selectedDays[index];

    return GestureDetector(
      onTap: () => _toggleDay(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getDayColor(index, isSelected),
          border: Border.all(
            color: _getBorderColor(index, isSelected),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _getDayColor(index, isSelected).withAlpha((255 * 0.3).toInt()),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: _getTextColor(index, isSelected),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: isSelected ? 14 : 13,
            ),
            child: Text(_dayLabels[index]),
          ),
        ),
      ),
    );
  }
}

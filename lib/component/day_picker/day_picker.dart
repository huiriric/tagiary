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
    // 초기 선택 상태 설정
    _selectedDays = List.from(widget.selectedDays);
    if (_selectedDays.length != 7) {
      _selectedDays = List.generate(7, (index) => false);
    }
  }

  void _toggleDay(int index) {
    setState(() {
      _selectedDays[index] = !_selectedDays[index];
      widget.onDaysChanged(_selectedDays);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Text(
            '반복 요일',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
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
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? Colors.black : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            _dayLabels[index],
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tagiary/tables/check_routine/check_routine_item.dart';
import 'package:tagiary/tables/check_routine/routine_history.dart';

class RoutineHistoryView extends StatefulWidget {
  final CheckRoutineItem routine;
  
  const RoutineHistoryView({
    Key? key,
    required this.routine,
  }) : super(key: key);

  @override
  State<RoutineHistoryView> createState() => _RoutineHistoryViewState();
}

class _RoutineHistoryViewState extends State<RoutineHistoryView> {
  late RoutineHistoryRepository _historyRepository;
  List<RoutineHistory> _history = [];
  DateTime _selectedMonth = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _historyRepository = RoutineHistoryRepository();
    _historyRepository.init().then((_) {
      _loadHistory();
    });
  }
  
  Future<void> _loadHistory() async {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    
    setState(() {
      _history = _historyRepository.getHistoryForRoutine(widget.routine.id)
        .where((h) => h.completedDate.isAfter(firstDayOfMonth) && 
                     h.completedDate.isBefore(lastDayOfMonth.add(const Duration(days: 1))))
        .toList();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('루틴 기록: ${widget.routine.content}'),
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          Expanded(
            child: _buildCalendar(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
                _loadHistory();
              });
            },
          ),
          Text(
            DateFormat('yyyy년 MM월').format(_selectedMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month + 1,
                );
                _loadHistory();
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildCalendar() {
    // 달의 일수 계산
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0은 일요일
    
    // 월 전체 날짜 목록 생성
    final calendarDays = List.generate(
      daysInMonth + firstWeekday,
      (index) {
        if (index < firstWeekday) {
          return null; // 1일 이전의 빈 칸
        }
        return DateTime(_selectedMonth.year, _selectedMonth.month, index - firstWeekday + 1);
      },
    );
    
    // 주별로 2차원 배열 생성
    final weeks = <List<DateTime?>>[]; 
    for (var i = 0; i < calendarDays.length; i += 7) {
      final end = i + 7;
      weeks.add(calendarDays.sublist(i, end > calendarDays.length ? calendarDays.length : end));
      if (end > calendarDays.length) {
        // 주의 나머지 부분을 null로 채움
        weeks.last.addAll(List.generate(end - calendarDays.length, (_) => null));
      }
    }
    
    return Column(
      children: [
        // 요일 헤더
        Row(
          children: const [
            Expanded(child: Center(child: Text('일', style: TextStyle(fontWeight: FontWeight.bold)))),
            Expanded(child: Center(child: Text('월', style: TextStyle(fontWeight: FontWeight.bold)))),
            Expanded(child: Center(child: Text('화', style: TextStyle(fontWeight: FontWeight.bold)))),
            Expanded(child: Center(child: Text('수', style: TextStyle(fontWeight: FontWeight.bold)))),
            Expanded(child: Center(child: Text('목', style: TextStyle(fontWeight: FontWeight.bold)))),
            Expanded(child: Center(child: Text('금', style: TextStyle(fontWeight: FontWeight.bold)))),
            Expanded(child: Center(child: Text('토', style: TextStyle(fontWeight: FontWeight.bold)))),
          ],
        ),
        const Divider(),
        // 캘린더 그리드
        Expanded(
          child: ListView.builder(
            itemCount: weeks.length,
            itemBuilder: (context, weekIndex) {
              return Row(
                children: List.generate(7, (dayIndex) {
                  final date = weeks[weekIndex].length > dayIndex ? weeks[weekIndex][dayIndex] : null;
                  return Expanded(
                    child: _buildCalendarDay(date),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildCalendarDay(DateTime? date) {
    if (date == null) {
      return const SizedBox(height: 50);
    }
    
    // 이 날짜에 루틴을 완료했는지 확인
    final isCompleted = _history.any((h) {
      final historyDate = DateTime(h.completedDate.year, h.completedDate.month, h.completedDate.day);
      final compareDate = DateTime(date.year, date.month, date.day);
      return historyDate.isAtSameMomentAs(compareDate);
    });
    
    final isToday = DateTime.now().day == date.day && 
                    DateTime.now().month == date.month && 
                    DateTime.now().year == date.year;
    
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        color: isToday ? Colors.blue.withOpacity(0.1) : null,
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: date.weekday == DateTime.sunday ? Colors.red : 
                        date.weekday == DateTime.saturday ? Colors.blue : 
                        Colors.black,
                ),
              ),
            ),
          ),
          if (isCompleted)
            Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(widget.routine.colorValue),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
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
  late CheckRoutineRepository _routineRepository;
  List<RoutineHistory> _history = [];
  DateTime _selectedMonth = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _historyRepository = RoutineHistoryRepository();
    _routineRepository = CheckRoutineRepository();
    
    Future.wait([
      _historyRepository.init(),
      _routineRepository.init(),
    ]).then((_) {
      _loadHistory();
    });
  }
  
  // 루틴 요일 편집 다이얼로그
  void _editRoutineDays() {
    // 현재 루틴의 요일 설정 복사
    List<bool> selectedDays = List.from(widget.routine.daysOfWeek);
    
    // 요일 없는 경우 기본값 설정
    if (selectedDays.length != 7) {
      selectedDays = List.generate(7, (index) => true);
    }
    
    // 요일 표시용 라벨
    final dayLabels = ['일', '월', '화', '수', '목', '금', '토'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('반복 요일 편집'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('루틴을 반복할 요일을 선택하세요'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: List.generate(7, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDays[index] = !selectedDays[index];
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selectedDays[index] ? Colors.black : Colors.transparent,
                            border: Border.all(
                              color: selectedDays[index] ? Colors.black : Colors.grey,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              dayLabels[index],
                              style: TextStyle(
                                color: selectedDays[index] ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              // 선택한 요일 중 하나라도 선택되어 있는지 확인
              if (!selectedDays.contains(true)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('최소 하나의 요일을 선택해주세요')),
                );
                return;
              }
              
              // 루틴 업데이트
              _updateRoutineDays(selectedDays);
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
  
  // 루틴 요일 업데이트
  Future<void> _updateRoutineDays(List<bool> newDays) async {
    // 새 루틴 객체 생성
    final updatedRoutine = CheckRoutineItem(
      id: widget.routine.id,
      content: widget.routine.content,
      colorValue: widget.routine.colorValue,
      check: widget.routine.check,
      updated: widget.routine.updated,
      daysOfWeek: newDays,
    );
    
    // 저장소에 업데이트
    await _routineRepository.updateItem(updatedRoutine);
    
    // UI에 반영
    setState(() {
      // widget.routine = updatedRoutine; // 직접 widget 속성은 변경 불가능하므로 루틴 새로 불러오기
    });
    
    // 업데이트 메시지
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('반복 요일이 업데이트되었습니다')),
      );
    }
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
        actions: [
          // 요일 편집 버튼 추가
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: '반복 요일 편집',
            onPressed: _editRoutineDays,
          ),
        ],
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
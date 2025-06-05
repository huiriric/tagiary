import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tagiary/component/slide_up_container.dart';
import 'package:tagiary/tables/check_routine/check_routine_item.dart';
import 'package:tagiary/tables/check_routine/routine_history.dart';
import 'package:tagiary/todo_routine_widget/add_routine/add_routine.dart';
import 'package:tagiary/todo_routine_widget/routine_history_view.dart';
import 'package:tagiary/todo_routine_widget/todo_routine_widget.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  late CheckRoutineRepository _repository;
  late RoutineHistoryRepository _historyRepository;
  int _selectedDayIndex = DateTime.now().weekday % 7; // 오늘 요일 (0: 일요일, 1: 월요일, ... 6: 토요일)

  //날짜별 루틴 기록
  final Map<DateTime, List<RoutineHistory>> _routineHistory = {};

  //달력
  late List<DateTime> _daysInMonth = [];
  late DateTime selectedDate;
  final List<String> weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  // 달력과 주간 뷰 전환
  bool _isMonthView = true;

  // Repository 초기화 상태 추적
  bool _isRepositoryInitialized = false;

  @override
  void initState() {
    super.initState();
    _repository = CheckRoutineRepository();
    _historyRepository = RoutineHistoryRepository();

    // 현재 날짜로 초기화
    final now = DateTime.now();
    selectedDate = DateTime(now.year, now.month, now.day);

    _initRepositories();
    _updateSelectedDate();
    _calculateMonthDays();
  }

  // 선택된 요일에 해당하는 날짜 계산
  void _updateSelectedDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayDayOfWeek = now.weekday % 7; // 0(일)~6(토) 범위로 변환

    // 선택된 요일과 오늘 요일의 차이 계산
    int dayDifference = _selectedDayIndex - todayDayOfWeek;

    // 날짜 계산
    selectedDate = today.add(Duration(days: dayDifference));

    // 달력 데이터도 업데이트
    _calculateMonthDays();
  }

  Future<void> _initRepositories() async {
    await _repository.init();
    await _historyRepository.init();
    // 새로운 날짜가 시작될 때 루틴 초기화
    _repository.initializeRoutine();

    setState(() {
      _isRepositoryInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 요일 라벨 배열
    final dayLabels = ['일', '월', '화', '수', '목', '금', '토'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '루틴',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Color(0xBB000000)),
        onPressed: () => _showAddRoutineDialog(context),
      ),
      body: !_isRepositoryInitialized
          ? const Center(child: CircularProgressIndicator()) // 로딩 표시
          : Column(mainAxisSize: MainAxisSize.min, children: [
              // 요일 선택 버튼 row
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (index) {
                    bool isSelected = index == _selectedDayIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDayIndex = index;
                          _updateSelectedDate(); // 날짜 업데이트 (달력도 함께 업데이트됨)
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            dayLabels[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // 선택된 날짜 표시
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 달력/주간 뷰 전환 버튼
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isMonthView = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isMonthView ? Colors.black : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: Icon(
                              Icons.calendar_month,
                              size: 20,
                              color: _isMonthView ? Colors.white : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isMonthView = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: !_isMonthView ? Colors.black : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: Icon(
                              Icons.view_week,
                              size: 20,
                              color: !_isMonthView ? Colors.white : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 루틴 위젯 사용
              TodoRoutineWidget(
                date: selectedDate,
                onRoutineChanged: () => setState(() {}),
              ),

              // 달력 또는 주간 뷰 표시
              Expanded(
                child: SingleChildScrollView(
                  child: _isMonthView ? routineCalendar() : routineWeekView(),
                ),
              ),
            ]),
    );
  }

  void _calculateMonthDays() {
    List<DateTime> days = [];

    // 선택된 달의 첫 날짜
    final DateTime firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);

    // 선택된 달의 마지막 날짜
    final DateTime lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);

    // 이전 달의 날짜들 (첫 주의 빈 부분 채우기)
    int firstWeekday = firstDayOfMonth.weekday % 7; // 0: 일요일, 1: 월요일, ..., 6: 토요일
    for (int i = firstWeekday - 1; i >= 0; i--) {
      days.add(firstDayOfMonth.subtract(Duration(days: i + 1)));
    }

    // 현재 달의 모든 날짜
    for (int i = 0; i < lastDayOfMonth.day; i++) {
      days.add(DateTime(firstDayOfMonth.year, firstDayOfMonth.month, i + 1));
    }

    // 다음 달의 날짜들 (마지막 주의 빈 부분 채우기)
    int lastWeekday = lastDayOfMonth.weekday % 7;
    int daysToAdd = 6 - lastWeekday;
    for (int i = 1; i <= daysToAdd; i++) {
      days.add(lastDayOfMonth.add(Duration(days: i)));
    }

    setState(() {
      _daysInMonth = days;
    });
  }

  Widget routineCalendar() {
    final List<String> weekdays = ['일', '월', '화', '수', '목', '금', '토'];

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      color: Colors.white,
      // margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 요일 헤더
            Row(
              children: weekdays
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: day == '일' ? Colors.red : (day == '토' ? Colors.blue : Colors.black87),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),

            // 달력 그리드
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.8,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: _daysInMonth.length,
              itemBuilder: (context, index) {
                final date = _daysInMonth[index];
                final isCurrentMonth = date.month == selectedDate.month;
                final isToday = _isToday(date);
                final isSelected = date.year == selectedDate.year && date.month == selectedDate.month && date.day == selectedDate.day;

                return GestureDetector(
                  onTap: () => _showDayRoutineDialog(date),
                  onLongPress: () {
                    setState(() {
                      selectedDate = date;
                      _selectedDayIndex = date.weekday % 7; // 선택된 날짜에 맞춰 요일 인덱스도 업데이트
                      _calculateMonthDays(); // 달력 데이터 업데이트
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // 날짜 텍스트
                        // Padding(
                        //   padding: const EdgeInsets.only(top: 4),
                        //   child: Text(
                        //     date.day.toString(),
                        //     style: TextStyle(
                        //       fontWeight: FontWeight.bold,
                        //       fontSize: 12,
                        //       color: isSelected ? Colors.white : (date.month != selectedDate.month ? Colors.grey : Colors.black87),
                        //     ),
                        //   ),
                        // ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          decoration: const BoxDecoration(
                            color: Colors.transparent, // 배경색 제거
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(3),
                              topRight: Radius.circular(3),
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isToday ? Theme.of(context).primaryColor : Colors.transparent,
                              ),
                              child: Center(
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: !isCurrentMonth
                                        ? Colors.grey.shade400
                                        : isToday
                                            ? Colors.white
                                            : date.weekday == 7 // 일요일
                                                ? Colors.red
                                                : date.weekday == 6 // 토요일
                                                    ? Colors.blue
                                                    : Colors.black87,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 루틴 체크박스들
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: SingleChildScrollView(
                              child: _buildRoutineCheckboxes(date, true), // true = 축소 버전
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget routineWeekView() {
    // 현재 주의 날짜들 계산
    final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday % 7));
    final weekDays = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      color: Colors.white,
      // margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 주간 뷰 헤더
            Row(
              children: weekdays
                  .asMap()
                  .entries
                  .map((entry) => Expanded(
                        child: Center(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: entry.value == '일' ? Colors.red : (entry.value == '토' ? Colors.blue : Colors.black87),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),

            // 주간 날짜와 루틴
            SizedBox(
              height: 100,
              child: Row(
                children: weekDays.asMap().entries.map((entry) {
                  final date = entry.value;
                  final isToday = _isToday(date);
                  final isSelected = date.year == selectedDate.year && date.month == selectedDate.month && date.day == selectedDate.day;
                  final isCurrentMonth = date.month == selectedDate.month;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _showDayRoutineDialog(date),
                      onLongPress: () {
                        setState(() {
                          selectedDate = date;
                          _selectedDayIndex = date.weekday % 7;
                          _calculateMonthDays();
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                        ),
                        child: Column(
                          children: [
                            // 날짜
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Center(
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isToday ? Theme.of(context).primaryColor : Colors.transparent,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${date.day}',
                                      style: TextStyle(
                                        fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: !isCurrentMonth
                                            ? Colors.grey.shade400
                                            : isToday
                                                ? Colors.white
                                                : date.weekday == 7 // 일요일
                                                    ? Colors.red
                                                    : date.weekday == 6 // 토요일
                                                        ? Colors.blue
                                                        : Colors.black87,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 루틴 체크박스들 (주간 뷰용 - 스크롤 없음)
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(4),
                                child: _buildRoutineCheckboxes(date, false), // false = 전체 버전
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 루틴 체크박스 위젯 빌더
  Widget _buildRoutineCheckboxes(DateTime date, bool isCompact) {
    // Repository가 초기화되지 않았으면 빈 위젯 반환
    if (!_isRepositoryInitialized) return const SizedBox.shrink();

    final routines = _repository.getAllItems().where((routine) => routine.daysOfWeek[date.weekday % 7]).toList();

    if (routines.isEmpty) return const SizedBox.shrink();

    final checkboxes = routines.map((routine) {
      final isCompleted = _historyRepository.wasRoutineCompletedOnDate(routine.id, date);
      final color = Color(routine.colorValue);

      return Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isCompleted ? color : color.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(
            color: color,
            width: 0.5,
          ),
        ),
        child: isCompleted
            ? const Icon(
                Icons.check,
                size: 8,
                color: Colors.white,
              )
            : null,
      );
    }).toList();

    return Wrap(
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      spacing: 1,
      runSpacing: 1,
      children: isCompact ? checkboxes.toList() : checkboxes,
    );
  }

  // 특정 날짜의 루틴 상세 다이얼로그
  void _showDayRoutineDialog(DateTime date) {
    // Repository가 초기화되지 않았으면 리턴
    if (!_isRepositoryInitialized) return;

    final routines = _repository.getAllItems().where((routine) => routine.daysOfWeek[date.weekday % 7]).toList();

    if (routines.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${date.month}월 ${date.day}일 루틴',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: routines.map((routine) {
              final isCompleted = _historyRepository.wasRoutineCompletedOnDate(routine.id, date);
              final color = Color(routine.colorValue);

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                // decoration: BoxDecoration(
                //   color: color.withOpacity(0.1),
                //   borderRadius: BorderRadius.circular(8),
                //   border: Border.all(color: color, width: 1),
                // ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isCompleted ? color : color.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 1),
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        routine.content,
                        style: TextStyle(
                          fontSize: 14,
                          color: isCompleted ? Colors.black87 : Colors.grey[600],
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showAddRoutineDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AnimatedPadding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        duration: const Duration(milliseconds: 0),
        curve: Curves.decelerate,
        child: SingleChildScrollView(
          child: SlideUpContainer(
            height: 350,
            child: AddRoutine(
              onRoutineAdded: () {
                setState(() {});
              },
            ),
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

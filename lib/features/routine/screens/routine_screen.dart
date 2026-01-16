import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mrplando/shared/models/category_manager_interface.dart';
import 'package:mrplando/shared/widgets/slide_up_container.dart';
import 'package:mrplando/features/routine/models/check_routine_item.dart';
import 'package:mrplando/features/routine/models/routine_history.dart';
import 'package:mrplando/features/routine/models/routine_category.dart';
import 'package:mrplando/features/routine/models/routine_category_manager.dart';
import 'package:mrplando/features/routine/widgets/add_routine.dart';
import 'package:mrplando/features/routine/widgets/routine_widget.dart';
import 'package:mrplando/features/routine/widgets/routine_history_view.dart';
import 'package:mrplando/features/routine/widgets/routine_detail.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  late CheckRoutineRepository _repository;
  late RoutineHistoryRepository _historyRepository;
  late RoutineCategoryManager _categoryManager;
  List<CategoryInfo> _categories = [];
  CategoryInfo? _selectedCategory; // null이면 전체 보기
  final int _selectedDayIndex = DateTime.now().weekday % 7; // 오늘 요일 (0: 일요일, 1: 월요일, ... 6: 토요일)

  //날짜별 루틴 기록
  final Map<DateTime, List<RoutineHistory>> _routineHistory = {};

  //달력
  late List<DateTime> _daysInMonth = [];
  late DateTime selectedDate;
  final List<String> weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  // 달력과 주간 뷰 전환
  final bool _isMonthView = true;

  // Repository 초기화 상태 추적
  bool _isRepositoryInitialized = false;

  @override
  void initState() {
    super.initState();
    _repository = CheckRoutineRepository();
    _historyRepository = RoutineHistoryRepository();
    _categoryManager = RoutineCategoryManager(
      categoryRepository: RoutineCategoryRepository(),
    );

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
    await _categoryManager.init();
    // 새로운 날짜가 시작될 때 루틴 초기화
    _repository.initializeRoutine();

    setState(() {
      _categories = _categoryManager.getAllCategories();
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
          : Column(children: [
              // 선택된 날짜 표시
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 이전 월 버튼
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _goToPreviousMonth,
                    ),

                    // 현재 월 표시
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, size: 25, color: Colors.black87),
                        const SizedBox(width: 8),
                        Text(
                          '${selectedDate.year}년 ${selectedDate.month}월${_isCurrentMonth() ? ' ${selectedDate.day}일' : ''}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // 다음 월 버튼
                    // 선택된 년월이 현재이면 이후 월로 이동 불가
                    selectedDate.year == DateTime.now().year && selectedDate.month == DateTime.now().month
                        ? const IconButton(
                            icon: Icon(Icons.chevron_right, color: Colors.grey),
                            onPressed: null,
                          )
                        : IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: _goToNextMonth,
                          ),
                  ],
                ),
              ),

              // 루틴 위젯 사용 (현재 달일 때만 표시)
              if (_isCurrentMonth())
                TodoRoutineWidget(
                  date: selectedDate,
                  onRoutineChanged: () => setState(() {
                    _updateSelectedDate();
                    _calculateMonthDays();
                  }),
                  fromMain: false,
                  selectedCategoryId: null,
                  categories: _categories,
                ),

              // 카테고리 필터 (가로 스크롤 ChoiceChip)
              if (_categories.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // 전체 카테고리
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ChoiceChip(
                          label: const Text('전체'),
                          selected: _selectedCategory == null,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = null;
                            });
                          },
                          showCheckmark: false,
                          selectedColor: Colors.blue.shade100,
                          labelStyle: TextStyle(
                            color: _selectedCategory == null ? Colors.blue.shade700 : Colors.grey.shade700,
                            fontWeight: _selectedCategory == null ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: _selectedCategory == null ? Colors.blue.shade300 : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      // 각 카테고리
                      ..._categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: category.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(category.name),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            showCheckmark: false,
                            selectedColor: category.color.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? category.color : Colors.grey.shade700,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            backgroundColor: Colors.grey.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? category.color : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

              // 달력 또는 주간 뷰 표시
              Expanded(
                child: Align(
                  alignment: AlignmentGeometry.topLeft,
                  child: routineCalendar(_selectedCategory?.id ?? -1),
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

  // 이전 달로 이동
  void _goToPreviousMonth() {
    setState(() {
      final newMonth = DateTime(selectedDate.year, selectedDate.month - 1, 1);
      final now = DateTime.now();

      // 현재 달로 돌아가는 경우 오늘 날짜로 설정
      if (newMonth.year == now.year && newMonth.month == now.month) {
        selectedDate = DateTime(now.year, now.month, now.day);
      } else {
        selectedDate = newMonth;
      }

      _calculateMonthDays();
    });
  }

  // 다음 달로 이동
  void _goToNextMonth() {
    setState(() {
      final newMonth = DateTime(selectedDate.year, selectedDate.month + 1, 1);
      final now = DateTime.now();

      // 현재 달로 돌아가는 경우 오늘 날짜로 설정
      if (newMonth.year == now.year && newMonth.month == now.month) {
        selectedDate = DateTime(now.year, now.month, now.day);
      } else {
        selectedDate = newMonth;
      }

      _calculateMonthDays();
    });
  }

  // 현재 달인지 확인
  bool _isCurrentMonth() {
    final now = DateTime.now();
    return selectedDate.year == now.year && selectedDate.month == now.month;
  }

  Widget routineCalendar(int categoryId) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<RoutineHistory>('routineHistoryBox').listenable(),
      builder: (context, Box<RoutineHistory> historyBox, _) {
        // 해당 달에 활성화된 루틴 필터링
        final activeRoutines = _getActiveRoutinesForMonth(categoryId);

        if (activeRoutines.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_repeat, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  '이번 달에 활성화된 루틴이 없습니다',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              spacing: 12,
              runSpacing: 12,
              children: activeRoutines.map((routine) => _buildRoutineCalendar(routine, historyBox)).toList(),
            ),
          ),
        );
      },
    );
  }

  // 해당 달에 활성화된 루틴 가져오기
  List<CheckRoutineItem> _getActiveRoutinesForMonth(int categoryId) {
    final allRoutines = categoryId == -1 ? _repository.getAllItems() : _repository.getCategoryItems(categoryId);
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);

    return allRoutines.where((routine) {
      // startDate가 해당 달 이전 또는 해당 달에 있고
      final startBeforeOrInMonth = routine.startDate.isBefore(lastDayOfMonth.add(const Duration(days: 1)));
      // endDate가 null이거나 해당 달 이후 또는 해당 달에 있는 경우
      final endAfterOrInMonth =
          routine.endDate == null || routine.endDate!.isAfter(firstDayOfMonth.subtract(const Duration(days: 1)));

      return startBeforeOrInMonth && endAfterOrInMonth;
    }).toList();
  }

  // 루틴별 미니 달력 위젯
  Widget _buildRoutineCalendar(CheckRoutineItem routine, Box<RoutineHistory> historyBox) {
    final List<String> weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final screenWidth = MediaQuery.of(context).size.width;
    final calendarWidth = (screenWidth - 28) / 2; // 양쪽 여백 8 + 중간 간격 12

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoutineHistoryView(routine: routine),
          ),
        );
      },
      child: Container(
        width: calendarWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 루틴 제목과 수정 아이콘
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      routine.content,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _showEditRoutineDialog(routine);
                    },
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 요일 헤더
              Row(
                children: weekdays
                    .map((day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: day == '일' ? Colors.red : (day == '토' ? Colors.blue : Colors.black87),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 4),

              // 미니 달력 그리드
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: _daysInMonth.length,
                itemBuilder: (context, index) {
                  final date = _daysInMonth[index];
                  final isCurrentMonth = date.month == selectedDate.month;
                  final isToday = _isToday(date);

                  // 해당 날짜에 루틴이 완료되었는지 확인
                  final isCompleted = _isRoutineCompletedOnDate(routine, date, historyBox);

                  // 루틴이 해당 날짜에 활성화되어 있는지 확인
                  final isActiveOnDate = _isRoutineActiveOnDate(routine, date);

                  return Container(
                    decoration: BoxDecoration(
                      color: !isCurrentMonth
                          ? Colors.transparent
                          : !isActiveOnDate
                              ? Colors.transparent
                              : isCompleted
                                  ? Color(routine.colorValue)
                                  : Color(routine.colorValue).withAlpha(80),
                      borderRadius: BorderRadius.circular(4),
                      border: isToday ? Border.all(color: Colors.black, width: 1.5) : null,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: !isCurrentMonth
                              ? Colors.grey.shade300
                              : !isActiveOnDate
                                  ? Colors.grey.shade400
                                  : isCompleted
                                      ? Colors.white
                                      : Colors.black54,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 해당 날짜에 루틴이 완료되었는지 확인
  bool _isRoutineCompletedOnDate(CheckRoutineItem routine, DateTime date, Box<RoutineHistory> historyBox) {
    final histories = historyBox.values.where((history) {
      return history.routineId == routine.id &&
          history.completedDate.year == date.year &&
          history.completedDate.month == date.month &&
          history.completedDate.day == date.day;
    });
    return histories.isNotEmpty;
  }

  // 해당 날짜에 루틴이 활성화되어 있는지 확인
  bool _isRoutineActiveOnDate(CheckRoutineItem routine, DateTime date) {
    // startDate 이전이면 비활성화
    if (date.isBefore(DateTime(routine.startDate.year, routine.startDate.month, routine.startDate.day))) {
      return false;
    }

    // endDate 이후면 비활성화
    if (routine.endDate != null &&
        date.isAfter(DateTime(routine.endDate!.year, routine.endDate!.month, routine.endDate!.day))) {
      return false;
    }

    // 요일 확인 (0: 일요일, 1: 월요일, ..., 6: 토요일)
    final dayOfWeek = date.weekday % 7;
    return routine.daysOfWeek[dayOfWeek];
  }

  // 루틴 체크/체크 해제
  Future<void> _toggleRoutineForDate(CheckRoutineItem routine, DateTime date) async {
    final historyBox = Hive.box<RoutineHistory>('routineHistoryBox');
    final isCompleted = _isRoutineCompletedOnDate(routine, date, historyBox);

    if (isCompleted) {
      // 체크 해제: 해당 날짜의 히스토리 삭제
      final histories = historyBox.values.where((history) {
        return history.routineId == routine.id &&
            history.completedDate.year == date.year &&
            history.completedDate.month == date.month &&
            history.completedDate.day == date.day;
      }).toList();

      for (var history in histories) {
        await history.delete();
      }
    } else {
      // 체크: 히스토리 추가
      final history = RoutineHistory(
        id: 0,
        routineId: routine.id,
        completedDate: date,
      );
      await _historyRepository.addItem(history);
    }

    setState(() {});
  }

  // Widget routineWeekView() {
  //   // 현재 주의 날짜들 계산
  //   final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday % 7));
  //   final weekDays = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

  //   return ValueListenableBuilder(
  //     valueListenable: Hive.box<RoutineHistory>('routineHistoryBox').listenable(),
  //     builder: (context, Box<RoutineHistory> historyBox, _) {
  //       return Card(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         elevation: 1,
  //         color: Colors.white,
  //         // margin: const EdgeInsets.all(16),
  //         child: Padding(
  //           padding: const EdgeInsets.all(16),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               // 주간 뷰 헤더
  //               Row(
  //                 children: weekdays
  //                     .asMap()
  //                     .entries
  //                     .map((entry) => Expanded(
  //                           child: Center(
  //                             child: Text(
  //                               entry.value,
  //                               style: TextStyle(
  //                                 fontWeight: FontWeight.bold,
  //                                 color: entry.value == '일' ? Colors.red : (entry.value == '토' ? Colors.blue : Colors.black87),
  //                               ),
  //                             ),
  //                           ),
  //                         ))
  //                     .toList(),
  //               ),
  //               const SizedBox(height: 8),

  //               // 주간 날짜와 루틴
  //               SizedBox(
  //                 height: 100,
  //                 child: Row(
  //                   children: weekDays.asMap().entries.map((entry) {
  //                     final date = entry.value;
  //                     final isToday = _isToday(date);
  //                     final isSelected = date.year == selectedDate.year && date.month == selectedDate.month && date.day == selectedDate.day;
  //                     final isCurrentMonth = date.month == selectedDate.month;

  //                     return Expanded(
  //                       child: GestureDetector(
  //                         onTap: () => _showDayRoutineDialog(date),
  //                         onLongPress: () {
  //                           setState(() {
  //                             selectedDate = date;
  //                             _selectedDayIndex = date.weekday % 7;
  //                             _calculateMonthDays();
  //                           });
  //                         },
  //                         child: Container(
  //                           margin: const EdgeInsets.symmetric(horizontal: 1),
  //                           decoration: BoxDecoration(
  //                             color: Colors.transparent,
  //                             borderRadius: BorderRadius.circular(8),
  //                             border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
  //                           ),
  //                           child: Column(
  //                             children: [
  //                               // 날짜
  //                               Padding(
  //                                 padding: const EdgeInsets.only(top: 8),
  //                                 child: Center(
  //                                   child: Container(
  //                                     width: 20,
  //                                     height: 20,
  //                                     decoration: BoxDecoration(
  //                                       shape: BoxShape.circle,
  //                                       color: isToday ? Theme.of(context).primaryColor : Colors.transparent,
  //                                     ),
  //                                     child: Center(
  //                                       child: Text(
  //                                         '${date.day}',
  //                                         style: TextStyle(
  //                                           fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
  //                                           color: !isCurrentMonth
  //                                               ? Colors.grey.shade400
  //                                               : isToday
  //                                                   ? Colors.white
  //                                                   : date.weekday == 7 // 일요일
  //                                                       ? Colors.red
  //                                                       : date.weekday == 6 // 토요일
  //                                                           ? Colors.blue
  //                                                           : Colors.black87,
  //                                           fontSize: 12,
  //                                         ),
  //                                       ),
  //                                     ),
  //                                   ),
  //                                 ),
  //                               ),

  //                               // 루틴 체크박스들 (주간 뷰용 - 스크롤 없음)
  //                               Expanded(
  //                                 child: Container(
  //                                   width: double.infinity,
  //                                   padding: const EdgeInsets.all(4),
  //                                   child: _buildRoutineCheckboxes(date, false), // false = 전체 버전
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                       ),
  //                     );
  //                   }).toList(),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  // 루틴 체크박스 위젯 빌더
  Widget _buildRoutineCheckboxes(DateTime date, bool isCompact) {
    // Repository가 초기화되지 않았으면 빈 위젯 반환
    if (!_isRepositoryInitialized) return const SizedBox.shrink();

    // 날짜 비교를 위해 시간 정보 제거
    final dateOnly = DateTime(date.year, date.month, date.day);

    final routines = _repository.getAllItems().where((routine) {
      // 해당 요일에 루틴이 설정되어 있는지 확인
      if (!routine.daysOfWeek[date.weekday % 7]) return false;

      // 루틴 시작일 이후인지 확인
      final routineStartDate = DateTime(routine.startDate.year, routine.startDate.month, routine.startDate.day);
      if (dateOnly.isBefore(routineStartDate)) return false;

      // 종료일이 설정되어 있고, 표시 날짜가 종료일 이후이면 제외
      if (routine.endDate != null) {
        final routineEndDate = DateTime(routine.endDate!.year, routine.endDate!.month, routine.endDate!.day);
        if (dateOnly.isAfter(routineEndDate)) return false;
      }

      return true;
    }).toList();

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

    // 날짜 비교를 위해 시간 정보 제거
    final dateOnly = DateTime(date.year, date.month, date.day);

    final routines = _repository.getAllItems().where((routine) {
      // 해당 요일에 루틴이 설정되어 있는지 확인
      if (!routine.daysOfWeek[date.weekday % 7]) return false;

      // 루틴 시작일 이후인지 확인
      final routineStartDate = DateTime(routine.startDate.year, routine.startDate.month, routine.startDate.day);
      if (dateOnly.isBefore(routineStartDate)) return false;

      // 종료일이 설정되어 있고, 표시 날짜가 종료일 이후이면 제외
      if (routine.endDate != null) {
        final routineEndDate = DateTime(routine.endDate!.year, routine.endDate!.month, routine.endDate!.day);
        if (dateOnly.isAfter(routineEndDate)) return false;
      }

      return true;
    }).toList();

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
    TimeOfDay now = TimeOfDay.now();
    TimeOfDay start = TimeOfDay(hour: now.hour, minute: 0);
    TimeOfDay end = TimeOfDay(hour: now.hour + 1, minute: 0);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AnimatedPadding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        duration: const Duration(milliseconds: 0),
        curve: Curves.decelerate,
        child: SingleChildScrollView(
          child: SlideUpContainer(
            child: AddRoutine(
              categories: _categories,
              onRoutineAdded: () {
                setState(() {});
              },
              onCategoryUpdated: () {
                setState(() {
                  _categories = _categoryManager.getAllCategories();
                });
              },
              selectedDate: selectedDate,
              start: start,
              end: end,
              category: _selectedCategory,
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

  // 루틴 수정 바텀시트
  void _showEditRoutineDialog(CheckRoutineItem routine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AnimatedPadding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        duration: const Duration(milliseconds: 0),
        curve: Curves.decelerate,
        child: SingleChildScrollView(
          child: SlideUpContainer(
            child: RoutineDetail(
              item: routine,
              onUpdated: () {
                setState(() {});
              },
              onCategoryUpdated: () {
                setState(() {
                  _categories = _categoryManager.getAllCategories();
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}

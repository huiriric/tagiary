import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tagiary/component/slide_up_container.dart';
import 'package:tagiary/constants/colors.dart';
import 'package:tagiary/tables/check_routine/check_routine_item.dart';
import 'package:tagiary/tables/check_routine/routine_history.dart';
import 'package:tagiary/todo_routine_widget/add_routine.dart';
import 'package:tagiary/todo_routine_widget/routine_detail.dart';
import 'package:tagiary/todo_routine_widget/routine_history_view.dart';

class TodoRoutineWidget extends StatefulWidget {
  final DateTime? date; // 표시할 날짜 (null이면 오늘 날짜)
  final bool? fromMain; // 메인 화면에서 호출된 경우 true
  final VoidCallback? onRoutineChanged; // 루틴 변경 시 호출되는 콜백

  const TodoRoutineWidget({
    super.key,
    this.date,
    this.fromMain = false,
    this.onRoutineChanged,
  });

  @override
  State<TodoRoutineWidget> createState() => _TodoRoutineWidgetState();
}

class _TodoRoutineWidgetState extends State<TodoRoutineWidget> {
  late CheckRoutineRepository _repository;
  late RoutineHistoryRepository _historyRepository;
  late DateTime _displayDate; // 표시할 날짜
  bool _isToday = true; // 오늘 날짜인지 여부

  @override
  void initState() {
    super.initState();
    _repository = CheckRoutineRepository();
    _historyRepository = RoutineHistoryRepository();
    _initRepositories();
    _updateDisplayDate();
  }

  @override
  void didUpdateWidget(TodoRoutineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 날짜가 변경된 경우 업데이트
    if (oldWidget.date != widget.date) {
      _updateDisplayDate();
    }
  }

  // 표시할 날짜 업데이트
  void _updateDisplayDate() {
    final today = DateTime.now();
    // 날짜 정보만 사용 (시간 제외)
    final todayDate = DateTime(today.year, today.month, today.day);

    if (widget.date == null) {
      _displayDate = todayDate;
      _isToday = true;
    } else {
      _displayDate = widget.date!;
      // 선택된 날짜가 오늘인지 비교 (년, 월, 일만 비교)
      _isToday = (_displayDate.year == todayDate.year && _displayDate.month == todayDate.month && _displayDate.day == todayDate.day);
    }
  }

  Future<void> _initRepositories() async {
    await _repository.init();
    await _historyRepository.init();
    // 새로운 날짜가 시작될 때 루틴 초기화
    _repository.initializeRoutine();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<CheckRoutineItem>('checkRoutineBox').listenable(),
      builder: (context, Box<CheckRoutineItem> box, _) {
        final routines = box.values.toList();
        return _buildRoutineWidget(routines);
      },
    );
  }

  Widget _buildRoutineWidget(List<CheckRoutineItem> allRoutines) {
    // 선택된 날짜의 요일 가져오기 (0: 일요일, 1: 월요일, ... 6: 토요일)
    final displayDayOfWeek = _displayDate.weekday % 7; // 0(일)~6(토) 범위로 변환

    // 선택된 요일에 해당하는 루틴만 필터링
    final filteredRoutines = allRoutines.where((routine) {
      // daysOfWeek가 null이거나 길이가 7이 아닌 경우 기본값 처리
      if (routine.daysOfWeek.length != 7) {
        return true; // 기존 데이터는 모든 요일에 표시
      }
      // 선택된 요일에 해당하는 값이 true인 루틴만 반환
      return routine.daysOfWeek[displayDayOfWeek];
    }).toList();

    // 요일 라벨 배열
    final dayLabels = ['일', '월', '화', '수', '목', '금', '토'];
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: filteredRoutines.isEmpty && _isToday
            ? () {
                _showAddRoutineDialog(context);
              }
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: widget.fromMain == true ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 16, right: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 왼쪽에 제목 추가 (선택된 요일 표시)
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: '루틴',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: ' (${dayLabels[displayDayOfWeek]})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // // 중앙에 주간 달성률 표시 (오늘 날짜일 때만 표시)
                  // if (filteredRoutines.isNotEmpty)
                  FutureBuilder<double>(
                    future: _getWeeklyCompletionRate(allRoutines),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final completionRate = snapshot.data!;
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: widget.fromMain == false ? 8.0 : 0),
                          child: Row(
                            children: [
                              Text(
                                '주간 ${(completionRate * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              if (widget.fromMain == false) const SizedBox(width: 4),
                              if (widget.fromMain == false) _buildProgressIndicator(completionRate),
                            ],
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                  GestureDetector(
                    onTap: () => _showAddRoutineDialog(context, onRoutineChanged: widget.onRoutineChanged),
                    child: const Icon(
                      Icons.add,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (filteredRoutines.isEmpty)
              widget.fromMain == true
                  ? Expanded(
                      child: Center(
                        child: Text(
                          _isToday ? '오늘의 루틴이 없습니다' : '${dayLabels[_displayDate.weekday % 7]}요일 루틴이 없습니다',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30.0),
                      child: Center(
                        child: Text(
                          _isToday ? '오늘의 루틴이 없습니다' : '${dayLabels[_displayDate.weekday % 7]}요일 루틴이 없습니다',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
            else if (widget.fromMain == true)
              Expanded(child: routineList(filteredRoutines))
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: routineList(filteredRoutines, widget.onRoutineChanged),
              )
          ],
        ),
      ),
    );
  }

  Widget routineList(List<CheckRoutineItem> filteredRoutines, [VoidCallback? onRoutineChanged]) {
    return ListView.builder(
      shrinkWrap: widget.fromMain == false ? true : false,
      physics: widget.fromMain == false ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
      itemCount: filteredRoutines.length,
      itemBuilder: (context, index) {
        final routine = filteredRoutines[index];

        return ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          contentPadding: const EdgeInsets.only(left: 0, right: 4),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  routine.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _isToday && routine.check ? Colors.grey : Colors.black,
                    fontSize: 13,
                  ),
                ),
              ),
              if (widget.fromMain == false)
                FutureBuilder<double>(
                  future: _getRoutineMonthlyCompletionRate(routine.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return SizedBox(
                        width: 110,
                        // margin: const EdgeInsets.only(right: 8.0),
                        child: Row(
                          children: [
                            Text(
                              '월간 ${(snapshot.data! * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: _buildProgressIndicator(snapshot.data!),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
            ],
          ),
          // 오늘 날짜면 체크박스, 아니면 컬러 도트 표시
          leading: _isToday
              ? Checkbox(
                  value: routine.check,
                  onChanged: (value) {
                    setState(() {
                      _updateRoutineCheck(routine, value!);
                      if (onRoutineChanged != null) {
                        onRoutineChanged();
                      }
                      _showToast(value ? '루틴을 완료했습니다' : '루틴 체크를 해제했습니다');
                    });
                  },
                  shape: const CircleBorder(),
                  activeColor: Color(routine.colorValue),
                  // 테두리 색상 설정
                  side: BorderSide(
                    color: routine.check ? Colors.transparent : Color(routine.colorValue),
                    width: 2,
                  ),
                )
              : FutureBuilder<bool>(
                  future: _isRoutineCompletedOnDate(routine.id, _displayDate),
                  builder: (context, snapshot) {
                    final isCompleted = snapshot.data ?? false;
                    return Checkbox(
                      value: isCompleted,
                      onChanged: (value) => _showToast('오늘의 루틴만 체크할 수 있습니다'),
                      shape: const CircleBorder(),
                      activeColor: Color(routine.colorValue),
                      // 테두리 색상 설정
                      side: BorderSide(
                        color: isCompleted ? Colors.transparent : Color(routine.colorValue),
                        width: 2,
                      ),
                    );
                  },
                ),
          // 삭제 버튼 (루틴 페이지일 때만 표시)
          trailing: widget.fromMain == false
              ? IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    _deleteRoutine(routine, onRoutineChanged: onRoutineChanged);
                  },
                )
              : null,
          onTap: () async {
            await _showRoutineDetail(routine, onRoutineChanged);
          },
        );
      },
    );
  }

  Future<void> _showRoutineDetail(CheckRoutineItem routine, VoidCallback? onRoutineChanged) async {
    // 루틴 상세 페이지 표시
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AnimatedPadding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        duration: const Duration(milliseconds: 0),
        curve: Curves.decelerate,
        child: SlideUpContainer(
          child: RoutineDetail(
            item: routine,
            onUpdated: onRoutineChanged,
          ),
        ),
      ),
    );
  }

  // 진행률 표시 위젯
  Widget _buildProgressIndicator(double value) {
    // 달성률에 따른 색상 설정
    Color progressColor;
    if (value >= 0.8) {
      progressColor = Colors.green;
    } else if (value >= 0.5) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // 배경 프로그레스 바
        Container(
          height: 5,
          width: 55,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        // 진행률 표시 프로그레스 바
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            height: 5,
            width: 55 * value,
            decoration: BoxDecoration(
              color: progressColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  // 전체 루틴의 주간 달성률 계산 (이번 주에 예정된 루틴 수 기준)
  Future<double> _getWeeklyCompletionRate(List<CheckRoutineItem> routines) async {
    final today = DateTime.now();

    // 이번 주의 첫날 계산 (일요일)
    final weekday = today.weekday % 7; // 0(일)~6(토)
    final firstDayOfWeek = today.subtract(Duration(days: weekday));
    final lastDayOfWeek = firstDayOfWeek.add(const Duration(days: 6));

    // 총 예정된 루틴 횟수 (주간)
    int totalScheduledDays = 0;
    // 총 완료된 루틴 횟수
    int totalCompleted = 0;

    // 각 루틴별로 계산
    for (final routine in routines) {
      // 요일 정보가 없는 경우 기본값 처리
      print(routine.content);
      List<bool> daysOfWeek = routine.daysOfWeek;
      if (daysOfWeek.length != 7) {
        daysOfWeek = List.generate(7, (index) => true);
      }

      // 이번 주에 루틴이 예정된 날짜 수 계산
      int routineScheduledDays = 0;

      // 이번 주의 일요일부터 토요일까지의 모든 날짜 확인
      print(daysOfWeek);
      for (int i = 0; i < 7; i++) {
        final date = firstDayOfWeek.add(Duration(days: i));
        final dayOfWeek = date.weekday % 7; // 0(일)~6(토)

        // 오늘 또는 오늘 이전의 날짜만 포함 (미래 날짜는 제외)
        // if (date.isAfter(today)) continue;

        if (daysOfWeek[dayOfWeek]) {
          routineScheduledDays++;
        }
      }

      totalScheduledDays += routineScheduledDays;
      print(totalScheduledDays);
      // 해당 루틴의 모든 완료 기록 가져오기
      final allHistory = _historyRepository.getHistoryForRoutine(routine.id);

      // 이번 주 기록만 필터링
      final weekHistory = allHistory.where((history) {
        final historyDate = DateTime(
          history.completedDate.year,
          history.completedDate.month,
          history.completedDate.day,
        );
        return historyDate.isAfter(firstDayOfWeek.subtract(const Duration(days: 1))) && historyDate.isBefore(lastDayOfWeek.add(const Duration(days: 1)));
      }).toList();

      totalCompleted += weekHistory.length;
    }

    // 예정된 날짜가 없으면 0% 반환
    if (totalScheduledDays == 0) return 0.0;

    // 달성률 계산 (총 완료된 루틴 / 이번 주 예정된 루틴)
    print('주간 달성률: $totalCompleted / $totalScheduledDays');
    return totalCompleted / totalScheduledDays;
  }

  // 특정 루틴의 주간 달성률 계산 (이번 주 기준)
  Future<double> _getRoutineWeeklyCompletionRate(int routineId) async {
    final today = DateTime.now();

    // 이번 주의 첫날 계산 (일요일)
    final weekday = today.weekday % 7; // 0(일)~6(토)
    final firstDayOfWeek = today.subtract(Duration(days: weekday));
    final lastDayOfWeek = firstDayOfWeek.add(const Duration(days: 6));

    final routine = _repository.getItem(routineId);
    if (routine == null) return 0.0;

    // 요일 정보가 없는 경우 기본값 처리
    List<bool> daysOfWeek = routine.daysOfWeek;
    if (daysOfWeek.length != 7) {
      daysOfWeek = List.generate(7, (index) => true);
    }

    // 해당 루틴의 모든 완료 기록 가져오기
    final allHistory = _historyRepository.getHistoryForRoutine(routineId);

    // 이번 주 기록만 필터링
    final weekHistory = allHistory.where((history) {
      final historyDate = DateTime(
        history.completedDate.year,
        history.completedDate.month,
        history.completedDate.day,
      );
      return historyDate.isAfter(firstDayOfWeek.subtract(const Duration(days: 1))) && historyDate.isBefore(lastDayOfWeek.add(const Duration(days: 1)));
    }).toList();

    // 이번 주에 루틴이 예정된 날짜 수 계산 (오늘까지)
    int scheduledDays = 0;
    for (int i = 0; i <= weekday; i++) {
      final date = firstDayOfWeek.add(Duration(days: i));
      final dayOfWeek = date.weekday % 7; // 0(일)~6(토)

      if (daysOfWeek[dayOfWeek]) {
        scheduledDays++;
      }
    }

    // 예정된 날짜가 없으면 0% 반환
    if (scheduledDays == 0) return 0.0;

    // 달성률 계산 (완료된 날짜 / 이번 주 예정된 날짜)
    return weekHistory.length / scheduledDays;
  }

  // 특정 루틴의 월간 달성률 계산
  Future<double> _getRoutineMonthlyCompletionRate(int routineId) async {
    final today = DateTime.now();
    final selectedMonth = DateTime(today.year, today.month);

    // 현재 달의 첫날과 마지막 날
    final firstDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

    final routine = _repository.getItem(routineId);
    if (routine == null) return 0.0;

    // 요일 정보가 없는 경우 기본값 처리
    List<bool> daysOfWeek = routine.daysOfWeek;
    if (daysOfWeek.length != 7) {
      daysOfWeek = List.generate(7, (index) => true);
    }

    // 해당 루틴의 모든 완료 기록 가져오기
    final allHistory = _historyRepository.getHistoryForRoutine(routineId);

    // 이번 달 기록만 필터링
    final monthlyHistory = allHistory.where((history) {
      final historyDate = DateTime(
        history.completedDate.year,
        history.completedDate.month,
        history.completedDate.day,
      );
      return historyDate.isAfter(firstDayOfMonth.subtract(const Duration(days: 1))) && historyDate.isBefore(lastDayOfMonth.add(const Duration(days: 1)));
    }).toList();

    // 이번 달에 루틴이 예정된 날짜 수 계산 (전체 달 기준)
    int scheduledDays = 0;
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(selectedMonth.year, selectedMonth.month, day);
      final dayOfWeek = date.weekday % 7; // 0(일)~6(토)

      if (daysOfWeek[dayOfWeek]) {
        scheduledDays++;
      }
    }

    // 예정된 날짜가 없으면 0% 반환
    if (scheduledDays == 0) return 0.0;

    // 달성률 계산 (완료된 날짜 / 전체 예정된 날짜)
    return monthlyHistory.length / scheduledDays;
  }

  // 오늘까지 예정된 루틴 날짜 수 계산
  int getScheduledDaysUntilToday(CheckRoutineItem routine) {
    final today = DateTime.now();

    // 요일 정보가 없는 경우 기본값 처리
    List<bool> daysOfWeek = routine.daysOfWeek;
    if (daysOfWeek.length != 7) {
      daysOfWeek = List.generate(7, (index) => true);
    }

    // 이번 달 1일부터 오늘까지 예정된 날짜 수 계산
    int count = 0;
    for (int day = 1; day <= today.day; day++) {
      final date = DateTime(today.year, today.month, day);
      final dayOfWeek = date.weekday % 7; // 0(일)~6(토)

      if (daysOfWeek[dayOfWeek]) {
        count++;
      }
    }

    return count;
  }

  // 전체 루틴의 월간 달성률 계산
  Future<double> _getMonthlyCompletionRate(List<CheckRoutineItem> routines) async {
    final today = DateTime.now();
    final selectedMonth = DateTime(today.year, today.month);

    // 현재 달의 첫날과 마지막 날
    final firstDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

    // 총 예정된 루틴 횟수 (전체 달 기준)
    int totalScheduledDays = 0;
    // 총 완료된 루틴 횟수
    int totalCompleted = 0;

    // 각 루틴별로 계산
    for (final routine in routines) {
      // 요일 정보가 없는 경우 기본값 처리
      List<bool> daysOfWeek = routine.daysOfWeek;
      if (daysOfWeek.length != 7) {
        daysOfWeek = List.generate(7, (index) => true);
      }

      // 이번 달 전체에 루틴이 예정된 날짜 수 계산
      int routineScheduledDays = 0;
      for (int day = 1; day <= lastDayOfMonth.day; day++) {
        final date = DateTime(selectedMonth.year, selectedMonth.month, day);
        final dayOfWeek = date.weekday % 7; // 0(일)~6(토)

        if (daysOfWeek[dayOfWeek]) {
          routineScheduledDays++;
        }
      }

      totalScheduledDays += routineScheduledDays;

      // 해당 루틴의 모든 완료 기록 가져오기
      final allHistory = _historyRepository.getHistoryForRoutine(routine.id);

      // 이번 달 기록만 필터링
      final monthlyHistory = allHistory.where((history) {
        final historyDate = DateTime(
          history.completedDate.year,
          history.completedDate.month,
          history.completedDate.day,
        );
        return historyDate.isAfter(firstDayOfMonth.subtract(const Duration(days: 1))) && historyDate.isBefore(lastDayOfMonth.add(const Duration(days: 1)));
      }).toList();

      totalCompleted += monthlyHistory.length;
    }

    // 예정된 날짜가 없으면 0% 반환
    if (totalScheduledDays == 0) return 0.0;

    // 달성률 계산 (총 완료된 루틴 / 총 예정된 루틴)
    return totalCompleted / totalScheduledDays;
  }

  void _updateRoutineCheck(CheckRoutineItem routine, bool value) {
    // 단순 체크 업데이트 대신 기록 추가 메소드 사용
    _checkRoutine(routine, value);
  }

  Future<void> _checkRoutine(CheckRoutineItem routine, bool checked) async {
    // 루틴 체크 상태 업데이트
    // 주의: 체크 상태는 "오늘 완료했는지" 여부만 의미함
    // 다른 날짜에서는 RoutineHistory를 참조하여 완료 여부 확인
    final updatedRoutine = CheckRoutineItem(
      id: routine.id,
      content: routine.content,
      colorValue: routine.colorValue,
      check: checked, // 오늘의 완료 상태
      updated: DateTime.now(), // 타임스탬프 업데이트
      daysOfWeek: routine.daysOfWeek, // 요일 정보 유지
    );

    await _repository.updateItem(updatedRoutine);

    if (checked) {
      // 체크 시에 기록 추가
      final history = RoutineHistory(
        id: 0, // 저장소에서 ID 할당
        routineId: routine.id,
        completedDate: DateTime.now(),
      );
      await _historyRepository.addItem(history);
    } else {
      // 체크 해제 시 오늘 날짜의 기록 삭제
      await _deleteRoutineHistoryForToday(routine.id);
    }
  }

  // 오늘 날짜의, 특정 루틴 기록만 삭제하는 메서드
  Future<void> _deleteRoutineHistoryForToday(int routineId) async {
    // 히스토리 삭제 메서드 호출
    await _historyRepository.deleteHistoryForRoutineOnDate(routineId, DateTime.now());
  }

  void _deleteRoutine(CheckRoutineItem routine, {VoidCallback? onRoutineChanged}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('루틴 삭제'),
        content: const Text('이 루틴을 삭제하시겠습니까?\n(모든 기록도 함께 삭제됩니다)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              // 루틴 삭제
              await _repository.deleteItem(routine.id);
              // 해당 루틴의 모든 기록 삭제
              await _historyRepository.deleteHistoryForRoutine(routine.id);
              onRoutineChanged?.call(); // 루틴 변경 콜백 호출
              Navigator.pop(context);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showAddRoutineDialog(BuildContext context, {VoidCallback? onRoutineChanged}) {
    TimeOfDay now = TimeOfDay.now();
    TimeOfDay start = TimeOfDay(hour: now.hour, minute: 0);
    TimeOfDay end = TimeOfDay(hour: now.hour + 1, minute: 0); // 기본 종료 시간은 시작 시간 + 1시간
    // SlideUpContainer를 사용하여 일정 추가와 유사한 UI로 변경
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
              onRoutineAdded: onRoutineChanged,
              start: start,
              end: end,
            ),
          ),
        ),
      ),
    );
  }

  // 특정 날짜에 루틴이 완료되었는지 확인
  Future<bool> _isRoutineCompletedOnDate(int routineId, DateTime date) async {
    // 히스토리 저장소 확인
    final histories = _historyRepository.getHistoryForRoutine(routineId);

    // 지정된 날짜의 완료 기록 확인
    return histories.any((history) {
      final historyDate = DateTime(history.completedDate.year, history.completedDate.month, history.completedDate.day);
      final targetDate = DateTime(date.year, date.month, date.day);
      return historyDate.isAtSameMomentAs(targetDate);
    });
  }

  void _showToast(String message) {
    // Exception 텍스트가 포함되어 있으면 제거
    String cleanMessage = message;
    if (message.contains('Exception:')) {
      cleanMessage = message.replaceAll('Exception:', '').trim();
    }

    Fluttertoast.showToast(
      msg: cleanMessage,
      toastLength: Toast.LENGTH_LONG, // 더 긴 시간 표시
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3, // iOS와 웹에서 3초 동안 표시
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }
}

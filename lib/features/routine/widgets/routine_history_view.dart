import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mrplando/features/routine/models/check_routine_item.dart';
import 'package:mrplando/features/routine/models/routine_history.dart';

class RoutineHistoryView extends StatelessWidget {
  final CheckRoutineItem routine;

  const RoutineHistoryView({
    super.key,
    required this.routine,
  });

  // 시작일부터 오늘까지의 모든 달 목록 생성
  List<DateTime> _getMonthsFromStartToToday() {
    final now = DateTime.now();
    final start = DateTime(routine.startDate.year, routine.startDate.month, 1);
    final today = DateTime(now.year, now.month, 1);

    List<DateTime> months = [];
    DateTime current = start;

    while (current.isBefore(today) || current.isAtSameMomentAs(today)) {
      months.add(current);
      current = DateTime(current.year, current.month + 1, 1);
    }

    return months;
  }

  // 해당 날짜가 루틴 요일인지 확인
  bool _isRoutineDay(DateTime date) {
    final dayOfWeek = date.weekday % 7; // 0: 일요일, 1: 월요일, ... 6: 토요일
    if (routine.daysOfWeek.length != 7) return true;
    return routine.daysOfWeek[dayOfWeek];
  }

  // 해당 날짜에 루틴이 완료되었는지 확인
  bool _isRoutineCompleted(DateTime date, Box<RoutineHistory> historyBox) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final allHistory = historyBox.values.where((h) => h.routineId == routine.id).toList();

    return allHistory.any((h) {
      final historyDate = DateTime(h.completedDate.year, h.completedDate.month, h.completedDate.day);
      return historyDate.isAtSameMomentAs(dateOnly);
    });
  }

  // 해당 날짜가 루틴 활성 범위 내인지 확인
  bool _isRoutineActiveOnDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(routine.startDate.year, routine.startDate.month, routine.startDate.day);

    // 시작일 이전이면 비활성
    if (dateOnly.isBefore(startOnly)) return false;

    // 종료일이 설정되어 있고, 종료일 이후면 비활성
    if (routine.endDate != null) {
      final endOnly = DateTime(routine.endDate!.year, routine.endDate!.month, routine.endDate!.day);
      if (dateOnly.isAfter(endOnly)) return false;
    }

    return true;
  }

  // 오늘 날짜인지 확인
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // 해당 월의 달력 위젯 생성
  Widget _buildMonthCalendar(DateTime month, Box<RoutineHistory> historyBox) {
    final List<String> weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7;

    // 달력 날짜 목록 생성 (첫 주 공백 포함)
    final List<DateTime?> calendarDays = List.generate(
      daysInMonth + firstWeekday,
      (index) {
        if (index < firstWeekday) return null;
        return DateTime(month.year, month.month, index - firstWeekday + 1);
      },
    );

    // 주별로 그룹화
    final List<List<DateTime?>> weeks = [];
    for (int i = 0; i < calendarDays.length; i += 7) {
      final end = i + 7;
      final week = calendarDays.sublist(i, end > calendarDays.length ? calendarDays.length : end);
      if (week.length < 7) {
        week.addAll(List.generate(7 - week.length, (_) => null));
      }
      weeks.add(week);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 월 제목
            Text(
              DateFormat('yyyy년 MM월').format(month),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // 요일 헤더
            Row(
              children: weekdays
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),

            // 달력 그리드
            ...weeks.map((week) {
              return Row(
                children: week.map((date) {
                  if (date == null) {
                    return const Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: SizedBox.shrink(),
                      ),
                    );
                  }

                  final isCurrentMonth = date.month == month.month;
                  final isToday = _isToday(date);
                  final isCompleted = _isRoutineCompleted(date, historyBox);
                  final isActiveOnDate = _isRoutineActiveOnDate(date);
                  final isRoutineDay = _isRoutineDay(date);

                  return Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: !isCurrentMonth
                              ? Colors.transparent
                              : !isActiveOnDate || !isRoutineDay
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
                              fontSize: 11,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: !isCurrentMonth
                                  ? Colors.grey.shade300
                                  : !isActiveOnDate || !isRoutineDay
                                      ? Colors.grey.shade400
                                      : isCompleted
                                          ? Colors.white
                                          : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final months = _getMonthsFromStartToToday();

    // Hive box가 열려있는지 확인
    if (!Hive.isBoxOpen('routineHistoryBox')) {
      return Scaffold(
        appBar: AppBar(
          title: Text(routine.content),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          routine.content,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: ValueListenableBuilder<Box<RoutineHistory>>(
        valueListenable: Hive.box<RoutineHistory>('routineHistoryBox').listenable(),
        builder: (context, historyBox, _) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.start,
                spacing: 12,
                runSpacing: 12,
                children: months
                    .map((month) => SizedBox(
                          width: (MediaQuery.of(context).size.width - 44) / 2,
                          child: _buildMonthCalendar(month, historyBox),
                        ))
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}

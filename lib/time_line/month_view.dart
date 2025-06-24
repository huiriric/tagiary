import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:tagiary/component/slide_up_container.dart';
import 'package:tagiary/provider.dart';
import 'package:tagiary/tables/data_models/event.dart';
import 'package:tagiary/tables/schedule/schedule_item.dart';
import 'package:tagiary/tables/schedule_routine/schedule_routine_item.dart';
import 'package:tagiary/time_line/add_schedule.dart';
import 'package:tagiary/time_line/view_schedule/schedule_details.dart';

class MonthView extends StatefulWidget {
  final DateTime selectedDate;

  const MonthView({
    super.key,
    required this.selectedDate,
  });

  @override
  State<MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends State<MonthView> {
  final ScheduleRoutineRepository srRepo = ScheduleRoutineRepository();
  final ScheduleRepository sRepo = ScheduleRepository();

  // 날짜별 일정
  Map<DateTime, List<Event>> _monthEvents = {};

  // 현재 달의 모든 날짜
  List<DateTime> _daysInMonth = [];

  // 요일 헤더 텍스트
  final List<String> weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  // 선택된 날짜 상태
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.selectedDate;
    _initializeData();
    _calculateMonthDays();
  }

  @override
  void didUpdateWidget(MonthView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate.month != widget.selectedDate.month || oldWidget.selectedDate.year != widget.selectedDate.year) {
      setState(() {
        _selectedDay = widget.selectedDate;
      });
      _calculateMonthDays();
      _loadMonthEvents();
    }
  }

  // 데이터 초기화
  Future<void> _initializeData() async {
    await srRepo.init();
    await sRepo.init();
    _loadMonthEvents();
  }

  // 현재 월의 모든 날짜 계산
  void _calculateMonthDays() {
    List<DateTime> days = [];

    // 선택된 달의 첫 날짜
    final DateTime firstDayOfMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month, 1);

    // 선택된 달의 마지막 날짜
    final DateTime lastDayOfMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month + 1, 0);

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

  // 월간 일정 로드
  Future<void> _loadMonthEvents() async {
    Map<DateTime, List<Event>> monthEvents = {};

    // 날짜별로 일정 로드
    for (DateTime day in _daysInMonth) {
      // 해당 날짜 키 생성 (시간 정보 제거)
      DateTime dateKey = DateTime(day.year, day.month, day.day);

      // 해당 날짜의 일반 일정
      List<Event> dateEvents = sRepo.getDateItems(day).toList();

      // 해당 요일의 루틴 일정
      // DateTime.weekday는 1(월요일)~7(일요일)이고
      // daysOfWeek는 [일,월,화,수,목,금,토] 순서이므로 변환 필요
      int routineIndex;
      routineIndex = day.weekday % 7;

      List<Event> routineEvents = srRepo.getItemsByDayWithTime(routineIndex).toList();
      List<Event> routineNoTimeEvents = srRepo.getItemsByDayWithoutTime(routineIndex).toList();

      // 모든 일정 합치기 (시간 있는/없는 일정 모두 포함)
      monthEvents[dateKey] = [
        ...dateEvents,
        ...routineNoTimeEvents,
        ...routineEvents,
      ];

      // 일정 정렬 (시간 없는 루틴 우선, 시간 있는 루틴 우선, 그 다음 시간순)
      monthEvents[dateKey]!.sort((a, b) {
        // 시간 정보가 없는 루틴이 우선
        if (a.isRoutine && !a.hasTimeSet && b.isRoutine && !b.hasTimeSet) {
          return 0; // 둘 다 시간 정보가 없는 루틴이면 동일하게 처리
        } else if (a.isRoutine && !a.hasTimeSet) {
          return -1; // a가 시간 정보가 없는 루틴이면 a가 우선
        } else if (b.isRoutine && !b.hasTimeSet) {
          return 1; // b가 시간 정보가 없는 루틴이면 b가 우선
        } else if (a.isRoutine != b.isRoutine) {
          return a.isRoutine ? -1 : 1;
        } else if (!a.hasTimeSet && !b.hasTimeSet) {
          return 0;
        } else if (!a.hasTimeSet) {
          return -1;
        } else if (!b.hasTimeSet) {
          return 1;
        } else {
          return a.startMinutes.compareTo(b.startMinutes);
        }
      });
    }

    if (mounted) {
      setState(() {
        _monthEvents = monthEvents;
      });
    }
  }

  // 월 변경 메서드
  void _changeMonth(int months) {
    final newDate = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month + months,
      1,
    );

    // 부모 위젯의 selectedDate 업데이트 (필요 시 콜백을 통해 구현)
    if (mounted) {
      setState(() {
        _selectedDay = DateTime(newDate.year, newDate.month, 1);
      });

      // Navigator.pushReplacement를 사용하는 대신 부모 위젯의 상태 변경을 위한 콜백 필요
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // 새 날짜로 화면 다시 그리기
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 부모 위젯에 알림 (TimelineScreen에서 구현 필요)
        Provider.of<DataProvider>(context, listen: false).updateDate(newDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 스와이프로 월 변경
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          // 오른쪽으로 스와이프 -> 이전 월
          _changeMonth(-1);
        } else if (details.primaryVelocity! < 0) {
          // 왼쪽으로 스와이프 -> 다음 월
          _changeMonth(1);
        }
      },
      child: Column(
        children: [
          // 월 표시 (화살표 버튼 추가)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 이전 월 버튼
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),

                // 현재 월 표시
                GestureDetector(
                  onTap: () async {
                    // 연/월 선택 다이얼로그 (필요 시 구현)
                  },
                  child: Text(
                    '${widget.selectedDate.year}년 ${widget.selectedDate.month}월',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // 다음 월 버튼
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),

          // 요일 헤더
          Row(
            children: weekdays
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          // textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: day == '일' ? Colors.red : (day == '토' ? Colors.blue : Colors.black87),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),

          // 달력 그리드
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.6, // 비율 조정으로 날짜 셀 높이 확보
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: _daysInMonth.length,
              itemBuilder: (context, index) {
                final day = _daysInMonth[index];
                final isCurrentMonth = day.month == widget.selectedDate.month;
                final isToday = _isToday(day);
                final isSelected = _isSameDay(day, _selectedDay);

                // 해당 날짜의 이벤트 가져오기
                final dateKey = DateTime(day.year, day.month, day.day);
                final events = _monthEvents[dateKey] ?? [];

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDay = day;
                    });

                    // Provider의 날짜도 업데이트
                    Provider.of<DataProvider>(context, listen: false).updateDate(day).then((_) {
                      if (mounted) {
                        setState(() {
                          // UI 업데이트
                        });
                      }
                    });

                    if (events.isNotEmpty) {
                      _showDayEvents(context, day, events);
                    }
                  },
                  onLongPress: () async {
                    // 일정 추가 다이얼로그 표시
                    void asdf = await _showAddScheduleDialog(context, day);
                    setState(() {
                      _selectedDay = day;
                      // 일정 추가 후 월간 일정 다시 로드
                      _loadMonthEvents();
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.7) : Colors.transparent,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        // 날짜 표시
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
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isToday ? Theme.of(context).primaryColor : Colors.transparent,
                              ),
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: !isCurrentMonth
                                        ? Colors.grey.shade400
                                        : isToday
                                            ? Colors.white
                                            : day.weekday == 7 // 일요일
                                                ? Colors.red
                                                : day.weekday == 6 // 토요일
                                                    ? Colors.blue
                                                    : Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 일정 표시 (최대 3개)
                        if (events.isNotEmpty)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.0),
                              child: Column(
                                children: [
                                  // 최대 3개의 일정만 표시
                                  ...events.take(3).map((event) => _buildEventDot(event)),

                                  // 더 많은 일정이 있으면 '...' 표시
                                  // if (events.length > 3)
                                  //   Padding(
                                  //     padding: const EdgeInsets.only(top: 2.0),
                                  //     child: Text(
                                  //       '+ ${events.length - 3}',
                                  //       style: TextStyle(
                                  //         fontSize: 10,
                                  //         color: Colors.grey.shade600,
                                  //       ),
                                  //     ),
                                  //   ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 일정 도트 표시
  Widget _buildEventDot(Event event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Container(
        height: 16,
        decoration: BoxDecoration(
          color: event.color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.clip,
                  maxLines: 1,
                ),
              ),
              if (event.isRoutine)
                const Icon(
                  Icons.repeat,
                  size: 8,
                  color: Colors.white,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 특정 날짜의 모든 일정 표시
  void _showDayEvents(BuildContext context, DateTime date, List<Event> events) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return SlideUpContainer(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 날짜 헤더
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${date.year}년 ${date.month}월 ${date.day}일 (${weekdays[date.weekday % 7]})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.black87),
                        onPressed: () async {
                          Navigator.pop(context);
                          void asdf = await _showAddScheduleDialog(context, date);
                          setState(() {
                            // 일정 추가 후 상태 업데이트
                            _loadMonthEvents();
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // 일정 목록
                Expanded(
                  child: ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return ListTile(
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: event.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(
                          event.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: event.hasTimeSet ? Text('${_formatTime(event.startTime!)} - ${_formatTime(event.endTime!)}') : const Text('하루 종일'),
                        trailing: event.isRoutine ? const Icon(Icons.repeat, size: 16, color: Colors.grey) : null,
                        onTap: () {
                          Navigator.pop(context);
                          _showEvent(context, event);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 일정 추가 다이얼로그
  Future<void> _showAddScheduleDialog(BuildContext context, DateTime date) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AnimatedPadding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        duration: const Duration(milliseconds: 0),
        curve: Curves.decelerate,
        child: SingleChildScrollView(
          child: SlideUpContainer(
            child: AddSchedule(
              date: date,
              start: TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: 0),
              end: TimeOfDay(hour: TimeOfDay.now().hour + 2, minute: 0),
              onScheduleAdded: () {
                // 일정 추가 후 월간 일정 다시 로드
                _loadMonthEvents();
              },
            ),
          ),
        ),
      ),
    );
  }

  // 이벤트 상세 보기
  void _showEvent(BuildContext context, Event event) {
    // 최신 정보 다시 가져오기
    Event? updatedEvent;

    if (event.isRoutine) {
      // 루틴일 경우 최신 정보 가져오기
      final routineRepo = ScheduleRoutineRepository();
      routineRepo.init().then((_) {
        final item = routineRepo.getItem(event.id);
        if (item != null) {
          updatedEvent = item.toEvent();
        }

        _showEventDetails(context, updatedEvent ?? event);
      });
    } else {
      // 일반 일정일 경우 최신 정보 가져오기
      final scheduleRepo = ScheduleRepository();
      scheduleRepo.init().then((_) {
        final item = scheduleRepo.getItem(event.id);
        if (item != null) {
          updatedEvent = item.toEvent();
        }

        _showEventDetails(context, updatedEvent ?? event);
      });
    }
  }

  void _showEventDetails(BuildContext context, Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AnimatedPadding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        duration: const Duration(milliseconds: 0),
        curve: Curves.decelerate,
        child: SlideUpContainer(
          child: ScheduleDetails(
            event: event,
            onUpdate: () {
              // 일정이 수정되거나 삭제되었을 때 데이터를 다시 로드
              _loadMonthEvents();
            },
          ),
        ),
      ),
    );
  }

  // 시간 포맷팅
  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // 오늘 날짜인지 확인 (년월일이 모두 같은 경우만)
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // 같은 날짜인지 확인
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

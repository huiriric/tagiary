import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:mrplando/component/slide_up_container.dart';
import 'package:mrplando/provider.dart';
import 'package:mrplando/tables/data_models/event.dart';
import 'package:mrplando/tables/schedule/schedule_item.dart';
import 'package:mrplando/tables/schedule_routine/schedule_routine_item.dart';
import 'package:mrplando/schedule/add_schedule.dart';
import 'package:mrplando/schedule/schedule_details.dart';

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
  final segmentPadding = 3.0; // 이벤트 바 양쪽 여백
  final segmentHeight = 16.0; // 이벤트 바 높이

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
            child: FutureBuilder(
              future: _initializeData(),
              builder: (context, snapshot) {
                return !snapshot.hasData
                    ? const SizedBox()
                    : Stack(
                        children: [
                          // 기간 일정 오버레이 레이어
                          ..._buildMultiDayEventBars(),
                          // 기본 달력 그리드 (날짜 + 단일 이벤트)
                          GridView.builder(
                            physics: const NeverScrollableScrollPhysics(), // 스크롤 비활성화
                            // padding: const EdgeInsets.symmetric(vertical: 16.0),
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
                              final allEvents = _monthEvents[dateKey] ?? [];

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

                                  if (allEvents.isNotEmpty) {
                                    _showDayEvents(context, day, allEvents);
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
                                      // 날짜 표시만 남기고 모든 이벤트는 오버레이에서 처리
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        decoration: const BoxDecoration(
                                          color: Colors.transparent,
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
                                      // 나머지 공간은 오버레이를 위해 비워둠
                                      Expanded(child: Container()),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 데이터 초기화
  Future<bool> _initializeData() async {
    await srRepo.init();
    await sRepo.init();
    await _loadMonthEvents();
    return true;
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

      // 해당 날짜의 일반 일정 (단일 날짜 + 기간 일정 포함)
      List<Event> dateEvents = _getEventsForDay(day);

      // 해당 요일의 루틴 일정
      // DateTime.weekday는 1(월요일)~7(일요일)이고
      // daysOfWeek는 [일,월,화,수,목,금,토] 순서이므로 변환 필요
      int routineIndex;
      routineIndex = day.weekday % 7;

      List<Event> routineEvents = srRepo.getItemsByDayWithTime(routineIndex).where((event) {
        final routineItem = srRepo.getItem(event.id);
        if (routineItem == null) return false;

        // startDate 체크 (startDate가 있으면 해당 날짜 이후만 표시)
        if (routineItem.startDate != null) {
          final startDateOnly = DateTime(routineItem.startDate!.year, routineItem.startDate!.month, routineItem.startDate!.day);
          if (dateKey.isBefore(startDateOnly)) return false;
        }

        // endDate 체크 (endDate가 있으면 해당 날짜 이전만 표시)
        if (routineItem.endDate != null) {
          final endDateOnly = DateTime(routineItem.endDate!.year, routineItem.endDate!.month, routineItem.endDate!.day);
          if (dateKey.isAfter(endDateOnly)) return false;
        }

        return true;
      }).toList();
      List<Event> routineNoTimeEvents = srRepo.getItemsByDayWithoutTime(routineIndex).where((event) {
        final routineItem = srRepo.getItem(event.id);
        if (routineItem == null) return false;

        // startDate 체크 (startDate가 있으면 해당 날짜 이후만 표시)
        if (routineItem.startDate != null) {
          final startDateOnly = DateTime(routineItem.startDate!.year, routineItem.startDate!.month, routineItem.startDate!.day);
          if (dateKey.isBefore(startDateOnly)) return false;
        }

        // endDate 체크 (endDate가 있으면 해당 날짜 이전만 표시)
        if (routineItem.endDate != null) {
          final endDateOnly = DateTime(routineItem.endDate!.year, routineItem.endDate!.month, routineItem.endDate!.day);
          if (dateKey.isAfter(endDateOnly)) return false;
        }

        return true;
      }).toList();

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

  // 특정 날짜의 일정 가져오기 (단일 날짜 + 기간 일정 포함)
  List<Event> _getEventsForDay(DateTime day) {
    List<Event> events = [];

    // 모든 일정을 가져와서 해당 날짜에 포함되는지 확인
    List<ScheduleItem> allSchedules = sRepo.getAllItems();

    for (ScheduleItem schedule in allSchedules) {
      DateTime startDate = DateTime(schedule.year, schedule.month, schedule.date);
      DateTime? endDate = schedule.hasMultiDay ? DateTime(schedule.endYear!, schedule.endMonth!, schedule.endDate!) : null;

      // 해당 날짜가 일정 기간에 포함되는지 확인
      if (_isDateInRange(day, startDate, endDate ?? startDate)) {
        events.add(schedule.toEvent());
      }
    }

    return events;
  }

  // 날짜가 기간에 포함되는지 확인
  bool _isDateInRange(DateTime date, DateTime startDate, DateTime endDate) {
    DateTime dateOnly = DateTime(date.year, date.month, date.day);
    DateTime startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    DateTime endOnly = DateTime(endDate.year, endDate.month, endDate.day);

    return (dateOnly.isAtSameMomentAs(startOnly) || dateOnly.isAfter(startOnly)) && (dateOnly.isAtSameMomentAs(endOnly) || dateOnly.isBefore(endOnly));
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

  // 특정 날짜의 모든 일정 표시
  void _showDayEvents(BuildContext context, DateTime date, List<Event> events) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return SlideUpContainer(
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
                          await _showAddScheduleDialog(context, date);
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
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
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

  // 모든 이벤트 바 생성 (단일 + 기간 일정)
  List<Widget> _buildMultiDayEventBars() {
    List<Widget> eventBars = [];

    // 현재 달의 모든 일정 가져오기 (단일 + 기간)
    List<Event> allEvents = _getAllEventsForMonth();

    // 이벤트 레이어 구성 (겹치는 이벤트 처리)
    Map<int, List<Event>> layers = _organizeEventLayers(allEvents);

    // 각 레이어별로 이벤트 바 생성
    layers.forEach((layerIndex, events) {
      for (Event event in events) {
        if (event.hasMultiDay) {
          // 기간 일정: 연속된 바 형태로 표시
          List<_EventBarSegment> segments = _calculateEventSegments(event, layerIndex);

          for (_EventBarSegment segment in segments) {
            eventBars.add(
              Positioned(
                left: segment.startX,
                top: segment.y,
                width: segment.width,
                height: segmentHeight, // 이벤트 바 높이
                child: GestureDetector(
                  onTap: () => _showEvent(context, event),
                  child: Container(
                    decoration: BoxDecoration(
                      color: event.color.withOpacity(0.8),
                      borderRadius: BorderRadius.horizontal(
                        left: segment.isStart ? const Radius.circular(4) : Radius.zero,
                        right: segment.isEnd ? const Radius.circular(4) : Radius.zero,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          if (segment.isStart) // 시작 부분에만 제목 표시
                            Expanded(
                              child: Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.clip,
                                maxLines: 1,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
        } else {
          // 단일 날짜 일정: 해당 날짜에만 도트 형태로 표시
          List<_EventBarSegment> segments = _calculateSingleEventSegments(event, layerIndex);

          for (_EventBarSegment segment in segments) {
            eventBars.add(
              Positioned(
                left: segment.startX,
                top: segment.y,
                width: segment.width,
                height: segmentHeight, // 단일 이벤트 높이
                child: Container(
                  decoration: BoxDecoration(
                    color: event.color.withOpacity(0.8),
                    borderRadius: BorderRadius.horizontal(
                      left: segment.isStart ? const Radius.circular(4) : Radius.zero,
                      right: segment.isEnd ? const Radius.circular(4) : Radius.zero,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.clip,
                            maxLines: 1,
                          ),
                        ),
                        if (event.isRoutine)
                          const Icon(
                            Icons.repeat,
                            size: 7,
                            color: Colors.white,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        }
      }
    });

    // 3개 레이어를 초과하는 이벤트가 있는 날짜에 "+더보기" 표시 추가
    eventBars.addAll(_buildMoreIndicators(allEvents, layers));

    return eventBars;
  }

  // 숨겨진 이벤트 개수 표시
  List<Widget> _buildMoreIndicators(List<Event> allEvents, Map<int, List<Event>> displayedLayers) {
    List<Widget> indicators = [];

    // 표시된 이벤트들 수집
    Set<Event> displayedEvents = {};
    for (var events in displayedLayers.values) {
      displayedEvents.addAll(events);
    }

    // 날짜별로 숨겨진 이벤트 개수 계산
    Map<DateTime, int> hiddenCounts = {};

    for (Event event in allEvents) {
      if (!displayedEvents.contains(event)) {
        DateTime eventDate = event.date!;
        if (event.hasMultiDay) {
          // 기간 일정의 경우 시작일에만 카운트
          if (_daysInMonth.any((day) => _isSameDay(day, eventDate))) {
            hiddenCounts[eventDate] = (hiddenCounts[eventDate] ?? 0) + 1;
          }
        } else {
          // 단일 날짜 일정
          hiddenCounts[eventDate] = (hiddenCounts[eventDate] ?? 0) + 1;
        }
      }
    }

    // 숨겨진 이벤트가 있는 날짜에 "더보기" 표시
    hiddenCounts.forEach((date, count) {
      int dayIndex = _daysInMonth.indexWhere((day) => _isSameDay(day, date));
      if (dayIndex != -1) {
        int weekIndex = dayIndex ~/ 7;
        int dayOfWeek = dayIndex % 7;

        double cellWidth = (MediaQuery.of(context).size.width) / 7;
        double cellHeight = cellWidth / 0.6;

        indicators.add(
          Positioned(
            left: dayOfWeek * cellWidth + cellWidth - 18 - segmentPadding,
            top: (weekIndex + 1) * cellHeight - segmentPadding * 2.5 - 18, // 3번째 레이어 아래
            width: 18,
            height: 18,
            child: GestureDetector(
              onTap: () {
                // 해당 날짜의 모든 이벤트 보기
                final dateKey = DateTime(date.year, date.month, date.day);
                final allDayEvents = _monthEvents[dateKey] ?? [];
                if (allDayEvents.isNotEmpty) {
                  _showDayEvents(context, date, allDayEvents);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    '+$count',
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    });

    return indicators;
  }

  // 현재 달의 모든 일정 가져오기 (단일 + 기간)
  List<Event> _getAllEventsForMonth() {
    List<Event> allEvents = [];

    List<ScheduleItem> allSchedules = sRepo.getAllItems();
    DateTime monthStart = DateTime(widget.selectedDate.year, widget.selectedDate.month, 1);
    DateTime monthEnd = DateTime(widget.selectedDate.year, widget.selectedDate.month + 1, 0);

    for (ScheduleItem schedule in allSchedules) {
      DateTime eventStart = DateTime(schedule.year, schedule.month, schedule.date);

      if (schedule.hasMultiDay) {
        // 기간 일정
        DateTime eventEnd = DateTime(schedule.endYear!, schedule.endMonth!, schedule.endDate!);

        // 이벤트가 현재 월과 겹치는지 확인
        if (eventStart.isBefore(monthEnd.add(const Duration(days: 1))) && eventEnd.isAfter(monthStart.subtract(const Duration(days: 1)))) {
          allEvents.add(schedule.toEvent());
        }
      } else {
        // 단일 날짜 일정
        if (eventStart.month == widget.selectedDate.month && eventStart.year == widget.selectedDate.year) {
          allEvents.add(schedule.toEvent());
        }
      }
    }

    // 루틴 일정도 추가
    for (DateTime day in _daysInMonth) {
      if (day.month == widget.selectedDate.month) {
        int routineIndex = day.weekday % 7;
        List<Event> routineEvents = srRepo.getItemsByDayWithTime(routineIndex).where((event) {
          final routineItem = srRepo.getItem(event.id);
          if (routineItem == null) return false;

          // startDate 체크 (startDate가 있으면 해당 날짜 이후만 표시)
          if (routineItem.startDate != null) {
            final startDateOnly = DateTime(routineItem.startDate!.year, routineItem.startDate!.month, routineItem.startDate!.day);
            if (day.isBefore(startDateOnly)) return false;
          }

          // endDate 체크 (endDate가 있으면 해당 날짜 이전만 표시)
          if (routineItem.endDate != null) {
            final endDateOnly = DateTime(routineItem.endDate!.year, routineItem.endDate!.month, routineItem.endDate!.day);
            if (day.isAfter(endDateOnly)) return false;
          }

          return true;
        }).toList();

        List<Event> routineNoTimeEvents = srRepo.getItemsByDayWithoutTime(routineIndex).where((event) {
          final routineItem = srRepo.getItem(event.id);
          if (routineItem == null) return false;

          // startDate 체크 (startDate가 있으면 해당 날짜 이후만 표시)
          if (routineItem.startDate != null) {
            final startDateOnly = DateTime(routineItem.startDate!.year, routineItem.startDate!.month, routineItem.startDate!.day);
            if (day.isBefore(startDateOnly)) return false;
          }

          // endDate 체크 (endDate가 있으면 해당 날짜 이전만 표시)
          if (routineItem.endDate != null) {
            final endDateOnly = DateTime(routineItem.endDate!.year, routineItem.endDate!.month, routineItem.endDate!.day);
            if (day.isAfter(endDateOnly)) return false;
          }

          return true;
        }).toList();

        // 루틴 일정들을 해당 날짜로 설정
        for (Event routine in [...routineEvents, ...routineNoTimeEvents]) {
          Event dayRoutine = Event(
            id: routine.id,
            title: routine.title,
            description: routine.description,
            date: day, // 해당 날짜로 설정
            endDate: null, // 단일 날짜
            daysOfWeek: routine.daysOfWeek,
            startTime: routine.startTime,
            endTime: routine.endTime,
            color: routine.color,
            isRoutine: routine.isRoutine,
            hasTimeSet: routine.hasTimeSet,
            hasMultiDay: false, // 루틴은 단일 날짜
          );
          allEvents.add(dayRoutine);
        }
      }
    }

    return allEvents;
  }

  // 단일 날짜 이벤트 세그먼트 계산
  List<_EventBarSegment> _calculateSingleEventSegments(Event event, int layerIndex) {
    List<_EventBarSegment> segments = [];

    // 해당 날짜가 달력에 표시되는지 확인
    int dayIndex = _daysInMonth.indexWhere((day) => _isSameDay(day, event.date!));
    if (dayIndex == -1) return segments;

    int weekIndex = dayIndex ~/ 7;
    int dayOfWeek = dayIndex % 7;

    // 셀 크기 계산
    double cellWidth = (MediaQuery.of(context).size.width) / 7; // 패딩 고려
    double cellHeight = cellWidth / 0.6; // childAspectRatio 0.6 사용

    segments.add(_EventBarSegment(
      startX: dayOfWeek * cellWidth + segmentPadding, // 약간의 여백
      y: weekIndex * cellHeight + 16 + (layerIndex * 20) + 16, // 날짜 텍스트 아래
      width: cellWidth - (segmentPadding * 2), // 양쪽 여백
      isStart: true,
      isEnd: true,
    ));

    return segments;
  }

  // 이벤트 레이어 구성 (겹치는 이벤트 처리) - 최대 3개 레이어
  Map<int, List<Event>> _organizeEventLayers(List<Event> events) {
    Map<int, List<Event>> layers = {};

    // 시작일 기준으로 정렬
    events.sort((a, b) => a.date!.compareTo(b.date!));

    for (Event event in events) {
      // 겹치지 않는 레이어 찾기 (최대 3개 레이어까지만)
      int layer = 0;
      bool layerFound = false;

      while (layer < 3) {
        // 최대 3개 레이어 제한
        if (layers[layer]?.any((e) => _eventsOverlap(e, event)) ?? false) {
          layer++;
        } else {
          layerFound = true;
          break;
        }
      }

      // 3개 레이어 내에서 배치 가능한 경우만 추가
      if (layerFound && layer < 3) {
        layers[layer] ??= [];
        layers[layer]!.add(event);
      }
      // layer >= 3인 경우는 표시하지 않음 (자동으로 무시됨)
    }

    return layers;
  }

  // 두 이벤트가 겹치는지 확인
  bool _eventsOverlap(Event a, Event b) {
    DateTime aStart = a.date!;
    DateTime aEnd = a.endDate ?? aStart; // 단일 날짜 일정은 시작일과 종료일이 동일
    DateTime bStart = b.date!;
    DateTime bEnd = b.endDate ?? bStart; // 단일 날짜 일정은

    return aStart.isBefore(bEnd.add(const Duration(days: 1))) && bStart.isBefore(aEnd.add(const Duration(days: 1)));
  }

  // 이벤트 세그먼트 계산
  List<_EventBarSegment> _calculateEventSegments(Event event, int layerIndex) {
    List<_EventBarSegment> segments = [];

    DateTime eventStart = event.date!;
    DateTime eventEnd = event.endDate!;

    // 달력에서 보이는 범위로 제한
    DateTime displayStart = eventStart;
    DateTime displayEnd = eventEnd;

    if (_daysInMonth.isNotEmpty) {
      DateTime calendarStart = _daysInMonth.first;
      DateTime calendarEnd = _daysInMonth.last;

      if (displayStart.isBefore(calendarStart)) {
        displayStart = calendarStart;
      }
      if (displayEnd.isAfter(calendarEnd)) {
        displayEnd = calendarEnd;
      }
    }

    DateTime current = displayStart;
    while (current.isBefore(displayEnd.add(const Duration(days: 1)))) {
      // 현재 날짜가 속한 주의 정보
      int dayIndex = _daysInMonth.indexWhere((day) => _isSameDay(day, current));
      if (dayIndex == -1) {
        current = current.add(const Duration(days: 1));
        continue;
      }

      int weekIndex = dayIndex ~/ 7;
      int dayOfWeek = dayIndex % 7;

      // 이 주에서 이벤트가 끝나는 위치 계산
      DateTime weekEnd = _daysInMonth[weekIndex * 7 + 6];
      DateTime segmentEnd = displayEnd.isBefore(weekEnd) ? displayEnd : weekEnd;

      // 세그먼트 끝 요일 계산 (정확한 날짜 기준)
      int segmentEndDayIndex = _daysInMonth.indexWhere((day) => _isSameDay(day, segmentEnd));
      int endDayOfWeek = segmentEndDayIndex % 7;

      // 셀 크기 계산 (실제 렌더링 시의 크기를 추정)
      double cellWidth = (MediaQuery.of(context).size.width) / 7; // 패딩 고려
      double cellHeight = cellWidth / 0.6; // childAspectRatio 0.6 사용

      segments.add(_EventBarSegment(
        startX: dayOfWeek * cellWidth + segmentPadding, // 약간의 여백
        y: weekIndex * cellHeight + 16 + (layerIndex * 20) + 16, // 날짜 텍스트(32px) + 여백(12px) 아래
        width: (endDayOfWeek - dayOfWeek + 1) * cellWidth - (segmentPadding * 2), // 양쪽 여백
        isStart: _isSameDay(current, eventStart),
        isEnd: _isSameDay(segmentEnd, eventEnd),
      ));

      // 다음 주로 이동
      current = weekEnd.add(const Duration(days: 1));
    }

    return segments;
  }
}

// 이벤트 바 세그먼트 클래스
class _EventBarSegment {
  final double startX;
  final double y;
  final double width;
  final bool isStart;
  final bool isEnd;

  _EventBarSegment({
    required this.startX,
    required this.y,
    required this.width,
    required this.isStart,
    required this.isEnd,
  });
}

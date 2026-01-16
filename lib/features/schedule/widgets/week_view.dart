import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:mrplando/shared/widgets/slide_up_container.dart';
import 'package:mrplando/shared/models/category_manager_interface.dart';
import 'package:mrplando/core/providers/provider.dart';
import 'package:mrplando/shared/models/event.dart';
import 'package:mrplando/features/schedule/models/schedule_item.dart';
import 'package:mrplando/features/schedule/models/schedule_routine_item.dart';
import 'package:mrplando/features/schedule/widgets/add_schedule.dart';
import 'package:mrplando/features/schedule/widgets/schedule_details.dart';

class WeekView extends StatefulWidget {
  final DateTime selectedDate;
  final int? selectedCategoryId; // 선택된 카테고리 ID
  final List<CategoryInfo> categories; // 카테고리 목록
  final VoidCallback? onCategoryUpdated; // 카테고리 변경 콜백

  const WeekView({
    super.key,
    required this.selectedDate,
    this.selectedCategoryId,
    this.categories = const [],
    this.onCategoryUpdated,
  });

  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> {
  final ScheduleRoutineRepository srRepo = ScheduleRoutineRepository();
  final ScheduleRepository sRepo = ScheduleRepository();

  // 요일 헤더 텍스트
  final List<String> weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  // 현재 주와 이전/다음 주를 위한 컨트롤러
  late PageController _pageController;

  // 페이지 인덱스 (0: 이전 주, 1: 현재 주, 2: 다음 주)
  int _currentPage = 1;

  // 3주치 날짜 정보 (이전 주, 현재 주, 다음 주)
  List<DateTime> _weekStarts = [];
  List<DateTime> _weekEnds = [];

  // 각 주별 이벤트 데이터
  List<Map<int, List<Event>>> _weeklyEvents = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
    _initializeWeeks();
    _initializeData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WeekView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _initializeWeeks(); // 날짜 변경 시 주 정보 다시 계산
      _loadAllWeeksEvents(); // 모든 주 데이터 다시 로드
    }
  }

  // 데이터 초기화
  Future<void> _initializeData() async {
    await srRepo.init();
    await sRepo.init();
    _loadAllWeeksEvents();
  }

  // 현재 주와 이전/다음 주의 시작일과 종료일 계산
  void _initializeWeeks() {
    _weekStarts = [];
    _weekEnds = [];

    for (int offset = -1; offset <= 1; offset++) {
      // 기준 날짜에서 offset주 만큼 이동
      final baseDate = widget.selectedDate.add(Duration(days: 7 * offset));

      // 해당 주의 시작일 (일요일)
      final weekday = baseDate.weekday % 7; // 1->1(월), 2->2(화)..., 7->0(일)
      final weekStart = baseDate.subtract(Duration(days: weekday));

      // 해당 주의 종료일 (토요일)
      final weekEnd = weekStart.add(const Duration(days: 6));

      _weekStarts.add(weekStart);
      _weekEnds.add(weekEnd);
    }
  }

  // 3주치 이벤트 전부 로드
  Future<void> _loadAllWeeksEvents() async {
    if (_weekStarts.isEmpty || !mounted) return;

    try {
      // 이전 주, 현재 주, 다음 주의 이벤트 로드
      final prevWeekEvents = await _loadWeekEventsFor(_weekStarts[0]);
      final currentWeekEvents = await _loadWeekEventsFor(_weekStarts[1]);
      final nextWeekEvents = await _loadWeekEventsFor(_weekStarts[2]);

      if (mounted) {
        setState(() {
          _weeklyEvents = [prevWeekEvents, currentWeekEvents, nextWeekEvents];
        });
      }
    } catch (e) {
      print('주간 일정 로드 오류: $e');
      // 오류 처리 (필요시 추가)
    }
  }

  // 특정 주의 이벤트 로드
  Future<Map<int, List<Event>>> _loadWeekEventsFor(DateTime weekStart) async {
    Map<int, List<Event>> weekEvents = {};

    // 일요일(0)부터 토요일(6)까지의 일정 로드
    for (int i = 0; i < 7; i++) {
      DateTime currentDate = weekStart.add(Duration(days: i));
      int dayOfWeek = i; // 0: 일요일, 1: 월요일, ..., 6: 토요일

      // 해당 날짜의 일반 일정
      List<Event> dateEvents = sRepo.getDateItems(currentDate).toList();

      // 해당 요일의 루틴 일정 (날짜 범위 필터링 적용)
      // ScheduleRoutineRepository.getItemsByDay는 dayIndex: 0(일요일) ~ 6(토요일) 순서 사용
      final dateKey = DateTime(currentDate.year, currentDate.month, currentDate.day);

      List<Event> routineEvents = srRepo.getItemsByDayWithTime(dayOfWeek).where((event) {
        final routineItem = srRepo.getItem(event.id);
        if (routineItem == null) return false;

        // startDate 체크 (startDate가 있으면 해당 날짜 이후만 표시)
        if (routineItem.startDate != null) {
          final startDateOnly =
              DateTime(routineItem.startDate!.year, routineItem.startDate!.month, routineItem.startDate!.day);
          if (dateKey.isBefore(startDateOnly)) return false;
        }

        // endDate 체크 (endDate가 있으면 해당 날짜 이전만 표시)
        if (routineItem.endDate != null) {
          final endDateOnly = DateTime(routineItem.endDate!.year, routineItem.endDate!.month, routineItem.endDate!.day);
          if (dateKey.isAfter(endDateOnly)) return false;
        }

        return true;
      }).toList();
      List<Event> noTimeRoutineEvents = srRepo.getItemsByDayWithoutTime(dayOfWeek).where((event) {
        final routineItem = srRepo.getItem(event.id);
        if (routineItem == null) return false;

        // startDate 체크 (startDate가 있으면 해당 날짜 이후만 표시)
        if (routineItem.startDate != null) {
          final startDateOnly =
              DateTime(routineItem.startDate!.year, routineItem.startDate!.month, routineItem.startDate!.day);
          if (dateKey.isBefore(startDateOnly)) return false;
        }

        // endDate 체크 (endDate가 있으면 해당 날짜 이전만 표시)
        if (routineItem.endDate != null) {
          final endDateOnly = DateTime(routineItem.endDate!.year, routineItem.endDate!.month, routineItem.endDate!.day);
          if (dateKey.isAfter(endDateOnly)) return false;
        }

        return true;
      }).toList();

      // 시간 있는 일정과 없는 일정 모두 포함
      List<Event> allDayEvents = [
        ...dateEvents,
        ...noTimeRoutineEvents,
        ...routineEvents,
      ];

      // 카테고리 필터링 적용
      if (widget.selectedCategoryId != null) {
        allDayEvents = allDayEvents.where((event) => event.categoryId == widget.selectedCategoryId).toList();
      }

      weekEvents[dayOfWeek] = allDayEvents;

      // 시간 기준으로 정렬
      weekEvents[dayOfWeek]!.sort((a, b) {
        if (!a.hasTimeSet && !b.hasTimeSet) {
          return 0; // 둘 다 시간 없으면 순서 유지
        } else if (!a.hasTimeSet) {
          return -1; // a가 시간 없으면 먼저
        } else if (!b.hasTimeSet) {
          return 1; // b가 시간 없으면 a가 나중에
        } else {
          return a.startMinutes.compareTo(b.startMinutes); // 시간 있으면 시작 시간순
        }
      });
    }

    return weekEvents;
  }

  // 페이지 변경 시 호출
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    // 페이지가 0이나 2로 변경되면 추가 주 로드 및 재조정
    if (page == 0 || page == 2) {
      _updateAfterPageChange(page);
    }
  }

  // 페이지 변경 후 데이터 업데이트
  void _updateAfterPageChange(int page) {
    // 애니메이션 완료 후 실행되도록 지연
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      // 새로운 기준 날짜 (이전 또는 다음 주의 중간 날짜)
      final newBaseDate = (page == 0)
          ? _weekStarts[0].add(const Duration(days: 3)) // 이전 주
          : _weekStarts[2].add(const Duration(days: 3)); // 다음 주

      // 주 정보 재계산
      List<DateTime> newWeekStarts = [];
      List<DateTime> newWeekEnds = [];

      for (int offset = -1; offset <= 1; offset++) {
        final offsetDate = newBaseDate.add(Duration(days: 7 * offset));

        // 해당 주의 시작일 (일요일)
        final weekday = offsetDate.weekday % 7; // 1->1(월), 2->2(화)..., 7->0(일)
        final weekStart = offsetDate.subtract(Duration(days: weekday));

        final weekEnd = weekStart.add(const Duration(days: 6));

        newWeekStarts.add(weekStart);
        newWeekEnds.add(weekEnd);
      }

      // 기존 데이터 재활용
      if (page == 0) {
        // 이전 => 현재로 변경된 경우: 이전 주 데이터 유지, 이전의 이전 주 로드, 다음 주 데이터 유지
        _loadWeekEventsFor(newWeekStarts[0]).then((newPrevWeekEvents) {
          if (mounted) {
            setState(() {
              _weeklyEvents = [
                newPrevWeekEvents, // 새 이전 주
                _weeklyEvents[0], // 기존 이전 주 => 새 현재 주
                _weeklyEvents[1], // 기존 현재 주 => 새 다음 주
              ];
              _weekStarts = newWeekStarts;
              _weekEnds = newWeekEnds;
              _currentPage = 1; // 현재 페이지로 리셋
            });

            // 페이지 컨트롤러 리셋 (애니메이션 없이)
            _pageController.jumpToPage(1);

            // 부모 위젯에 알림
            Provider.of<DataProvider>(context, listen: false).updateDate(newBaseDate);
          }
        });
      } else {
        // page == 2
        // 다음 => 현재로 변경된 경우: 이전 주 데이터 유지, 다음 주 데이터 유지, 다음의 다음 주 로드
        _loadWeekEventsFor(newWeekStarts[2]).then((newNextWeekEvents) {
          if (mounted) {
            setState(() {
              _weeklyEvents = [
                _weeklyEvents[1], // 기존 현재 주 => 새 이전 주
                _weeklyEvents[2], // 기존 다음 주 => 새 현재 주
                newNextWeekEvents, // 새 다음 주
              ];
              _weekStarts = newWeekStarts;
              _weekEnds = newWeekEnds;
              _currentPage = 1; // 현재 페이지로 리셋
            });

            // 페이지 컨트롤러 리셋 (애니메이션 없이)
            _pageController.jumpToPage(1);

            // 부모 위젯에 알림
            Provider.of<DataProvider>(context, listen: false).updateDate(newBaseDate);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 날짜 헤더 표시
        _buildWeekHeader(),

        // 주간 일정 페이지 뷰
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: 3, // 이전 주, 현재 주, 다음 주
            itemBuilder: (context, index) {
              // 해당 주의 이벤트 데이터가 아직 로드되지 않은 경우
              if (_weeklyEvents.length <= index || _weeklyEvents[index].isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              // 해당 주의 주간 뷰 위젯 반환
              return _buildWeekEventsView(index);
            },
          ),
        ),
      ],
    );
  }

  // 주간 헤더 (날짜 표시)
  Widget _buildWeekHeader() {
    // 현재 보고 있는 주의 시작일
    final weekStart = (_currentPage < _weekStarts.length)
        ? _weekStarts[_currentPage]
        : _weekStarts.isNotEmpty
            ? _weekStarts.last
            : DateTime.now().subtract(Duration(days: DateTime.now().weekday % 7));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(7, (index) {
          DateTime date = weekStart.add(Duration(days: index));
          bool isToday = _isToday(date);
          bool isSelected = _isSameDay(date, widget.selectedDate);

          return Expanded(
            child: GestureDetector(
              onTap: () {
                // 날짜 선택 시 Provider 업데이트 및 상태 업데이트
                Provider.of<DataProvider>(context, listen: false).updateDate(date).then((_) {
                  if (mounted) {
                    setState(() {
                      // 선택된 날짜가 변경되었으므로 위젯 다시 렌더링
                    });
                  }
                });
              },
              child: Column(
                children: [
                  Text(
                    weekdays[index],
                    style: TextStyle(
                      color: isToday ? Theme.of(context).primaryColor : Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isToday ? Border.all(color: Theme.of(context).primaryColor, width: 2.0) : null,
                      color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? Theme.of(context).primaryColor
                                  : Colors.black,
                          fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // 주간 일정 목록 뷰
  Widget _buildWeekEventsView(int pageIndex) {
    // 해당 주의 시작일
    final weekStart = (_weekStarts.length > pageIndex)
        ? _weekStarts[pageIndex]
        : DateTime.now().subtract(Duration(days: DateTime.now().weekday % 7));

    // 해당 주의 이벤트 데이터
    final weekEvents = (_weeklyEvents.length > pageIndex) ? _weeklyEvents[pageIndex] : <int, List<Event>>{};

    return ListView(
      children: List.generate(7, (i) {
        final date = weekStart.add(Duration(days: i));
        final events = weekEvents[i] ?? [];
        return _buildDaySection(i, date, events);
      }),
    );
  }

  // 요일별 일정 섹션
  Widget _buildDaySection(int dayIndex, DateTime date, List<Event> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜 표시
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '${weekdays[dayIndex]} (${date.month}/${date.day})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),

        // 일정이 없는 경우
        if (events.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('일정이 없습니다.')),
          ),

        // 일정 목록
        if (events.isNotEmpty) ...events.map((event) => _buildEventItem(event, date)),

        const Divider(height: 1),
      ],
    );
  }

  // 개별 일정 아이템
  Widget _buildEventItem(Event event, DateTime date) {
    // 시간 없는 일정과 있는 일정 스타일 분리
    return InkWell(
      onTap: () => _showEvent(context, event),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // 색상 마커
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: event.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),

            // 일정 내용
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (event.hasTimeSet)
                    Text(
                      '${_formatTime(event.startTime!)} - ${_formatTime(event.endTime!)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  if (!event.hasTimeSet)
                    Text(
                      '하루 종일',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            // 루틴 표시
            if (event.isRoutine)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(
                  Icons.repeat,
                  size: 16,
                  color: Colors.grey,
                ),
              ),
          ],
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
              _loadAllWeeksEvents();
            },
            onCategoryUpdated: () {
              // 카테고리 정보가 변경되었을 때 데이터를 다시 로드
              widget.onCategoryUpdated?.call();
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

  // 오늘 날짜인지 확인 (년월일 모두 같은 경우만)
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // 같은 날짜인지 확인
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

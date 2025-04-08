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

class TimeLine extends StatefulWidget {
  final DateTime date;
  const TimeLine({super.key, required this.date});

  @override
  State<TimeLine> createState() => _TimeLineState();
}

class _TimeLineState extends State<TimeLine> {
  //타임 라인 설정
  late ScrollController _timelineCont;
  late int _startHour; // Provider에서 가져올 시작 시간
  late int _endHour; // Provider에서 가져올 종료 시간
  final double _hourHeight = 70.0; // 시간당 높이
  final double _timelineWidth = 40.0; // 타임라인 폭
  final double padding = 12.0;
  final double eventHorizontalPadding = 10;
  final double eventFontSize = 12;
  final double timelineOffset = 9.0; // 시간 라인 위치 보정값 상수화

  final ScheduleRoutineRepository srRepo = ScheduleRoutineRepository();
  final ScheduleRepository sRepo = ScheduleRepository();
  List<Event> _events = [];

  @override
  void initState() {
    super.initState();

    // Provider에서 시작/종료 시간 가져오기
    final provider = Provider.of<DataProvider>(context, listen: false);
    _startHour = provider.startHour;
    _endHour = provider.endHour;

    // 비동기 초기화를 별도 메서드로 분리
    _initializeData();
    _timelineCont = ScrollController();
  }

  @override
  void didUpdateWidget(TimeLine oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 날짜가 변경되었을 때만 데이터 다시 로드
    if (oldWidget.date != widget.date) {
      _loadEventsForDate();
    }
  }

  Future<void> _initializeData() async {
    // 비동기 작업 수행
    await srRepo.init();
    await sRepo.init();

    // 데이터 로드
    _loadEventsForDate();
  }

  Future<void> _loadEventsForDate() async {
    // 항상 초기화 호출 (이미 초기화되어 있으면 내부적으로 처리됨)
    await srRepo.init();
    await sRepo.init();

    // 선택된 날짜에 해당하는 요일의 루틴 가져오기
    // DateTime.weekday는 1(월요일)~7(일요일)이지만
    // daysOfWeek는 [일,월,화,수,목,금,토] 순서이므로 적절히 변환
    final dayOfWeek = widget.date.weekday % 7; // 1->1(월), 2->2(화)..., 7->0(일)

    // 데이터 박스 최신화 (새로운 아이템이 추가되었을 수 있음)
    if (mounted) {
      // 데이터 로드 후 상태 업데이트
      setState(() {
        // 선택된 요일의 루틴 이벤트 가져오기
        _events = srRepo.getItemsByDay(dayOfWeek).toList();

        // 선택된 날짜의 일반 일정 이벤트 가져오기
        _events = [..._events, ...sRepo.getDateItems(widget.date)];

        // 이벤트를 시작 시간순으로 정렬
        _events.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 최신 시작/종료 시간 가져오기 (Provider에서 변경되었을 경우 반영)
    final provider = Provider.of<DataProvider>(context);
    _startHour = provider.startHour;
    _endHour = provider.endHour;
    
    final double screenWidth = MediaQuery.of(context).size.width;
    final double eventWidth = (screenWidth / 2) - padding - _timelineWidth; // 일정 카드 폭
    final int totalHours = _endHour - _startHour + 1;
    final double totalHeight = totalHours * _hourHeight;

    return SingleChildScrollView(
      controller: _timelineCont,
      child: Stack(
        children: [
          Container(
            height: totalHeight,
            margin: EdgeInsets.only(left: _timelineWidth),
            // decoration: BoxDecoration(
            //   border: Border(
            //     left: BorderSide(
            //       color: Colors.grey.shade300,
            //       width: 2,
            //     ),
            //   ),
            // ),
          ),

          // 시간 마커와 구분선
          ...List.generate(totalHours, (index) {
            final hour = _startHour + index;
            return Positioned(
              left: 0,
              top: index * _hourHeight,
              child: Row(
                children: [
                  SizedBox(
                    width: _timelineWidth,
                    child: Text(
                      '$hour:00',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: eventFontSize),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width - _timelineWidth,
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                ],
              ),
            );
          }),
          // 시간 사이 버튼 (터치 시 일정 추가)
          ...List.generate(totalHours - 1, (index) {
            return Positioned(
                top: timelineOffset + index * _hourHeight,
                left: 0 - padding,
                child: InkWell(
                  // borderRadius: BorderRadius.circular(5),
                  onLongPress: () {
                    TimeOfDay start = TimeOfDay(hour: _startHour + index, minute: 0);
                    TimeOfDay end = TimeOfDay(hour: _startHour + index + 1, minute: 0);

                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => AnimatedPadding(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                        duration: const Duration(milliseconds: 0),
                        curve: Curves.decelerate,
                        child: SingleChildScrollView(
                          child: SlideUpContainer(
                            child: AddSchedule(
                              date: widget.date,
                              start: start,
                              end: end,
                              onScheduleAdded: _loadEventsForDate, // 일정 추가 후 이벤트 다시 로드
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: (screenWidth / 2),
                    height: _hourHeight - 1,
                    decoration: BoxDecoration(
                      // color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ));
          }),
          // 일정 아이템
          ...List.generate(_events.length, (index) {
            final event = _events[index];
            final startMinutes = event.startMinutes;
            final endMinutes = event.endMinutes;

            // 타임라인 기준으로 위치 계산
            final topPosition = (startMinutes - _startHour * 60) / 60 * _hourHeight;
            final height = (endMinutes - startMinutes) / 60 * _hourHeight;

            return Positioned(
              left: _timelineWidth + eventHorizontalPadding,
              top: topPosition + timelineOffset, // 일관된 오프셋 사용
              child: GestureDetector(
                onTap: () => _showEvent(context, event),
                child: Container(
                  width: eventWidth - (2 * eventHorizontalPadding),
                  height: height,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: event.color,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // 텍스트를 그릴 때 사용할 TextPainter
                      final textPainter = TextPainter(
                        text: TextSpan(
                          text: event.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: eventFontSize,
                          ),
                        ),
                        maxLines: 1,
                        textDirection: TextDirection.ltr,
                      );

                      // 레이아웃 계산
                      textPainter.layout(maxWidth: constraints.maxWidth);

                      // 텍스트가 너비를 초과하는지 확인
                      final overflowed = textPainter.didExceedMaxLines;

                      return Text(
                        event.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: eventFontSize,
                        ),
                        overflow: overflowed ? TextOverflow.clip : TextOverflow.ellipsis,
                      );
                    },
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, int hour) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("길게 눌렀음"),
          content: Text('$hour - ${hour + 1}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("닫기"),
            ),
          ],
        );
      },
    );
  }

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
              _loadEventsForDate();
            },
          ),
        ),
      ),
    );
  }

  // Future<void> addSchedule() async {
  //   final item = ScheduleItem(
  //     year: 2025,
  //     month: 3,
  //     date: 11,
  //     title: '첫 일별 스케줄',
  //     description: '첫 일별 스케줄입니다.',
  //     startHour: 15,
  //     startMinute: 0,
  //     endHour: 16,
  //     endMinute: 30,
  //     colorValue: Colors.orange.value,
  //   );

  //   ScheduleRepository repo = ScheduleRepository();
  //   await repo.init();

  //   int id = await repo.addItem(item);
  //   final firstSchedule = repo.getItem(id);
  //   print(firstSchedule?.key);
  //   print(firstSchedule?.title);
  // }
}

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
  final bool fromScreen;
  const TimeLine({super.key, required this.date, required this.fromScreen});

  @override
  State<TimeLine> createState() => _TimeLineState();
}

class _TimeLineState extends State<TimeLine> {
  //타임 라인 설정
  late ScrollController _timelineCont;
  late int _startHour; // Provider에서 가져올 시작 시간
  late int _endHour; // Provider에서 가져올 종료 시간
  final double _hourHeight = 70.0; // 시간당 높이
  final double _timelineWidth = 20.0; // 타임라인 폭
  final double padding = 12.0;
  final double eventHorizontalPadding = 10;
  final double eventFontSize = 12;
  final double timelineOffset = 8.0; // 시간 라인 위치 보정값 상수화

  final ScheduleRoutineRepository srRepo = ScheduleRoutineRepository();
  final ScheduleRepository sRepo = ScheduleRepository();
  List<Event> _events = []; // 시간이 있는 이벤트들
  List<Event> _noTimeEvents = []; // 시간 정보가 없는 이벤트들

  // 드래그 관련 변수
  Event? _draggingEvent;
  double? _dragStartY;
  double? _dragCurrentY; // 현재 드래그 위치 저장
  double? _originalTopPosition;
  TimeOfDay? _originalStartTime;
  TimeOfDay? _originalEndTime;

  // 충돌 감지를 위한 변수
  bool _hasConflict = false;
  Event? _conflictEvent;

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
    // srRepo.getItemsByDay는 0(일요일)~6(토요일) 순서이므로 적절히 변환
    final dayOfWeek = widget.date.weekday % 7; // 1->1(월), 2->2(화)..., 7->0(일)

    // 데이터 박스 최신화 (새로운 아이템이 추가되었을 수 있음)
    if (mounted) {
      // 선택된 날짜의 모든 일정 이벤트 가져오기
      final allScheduleEvents = sRepo.getDateItems(widget.date).toList();
      // 선택된 요일의 루틴 이벤트 가져오기
      final routineEvents = srRepo.getItemsByDay(dayOfWeek).toList();

      // 시간 있는 이벤트와 없는 이벤트 구분
      final timeEvents = allScheduleEvents.where((e) => e.hasTimeSet).toList();
      final noTimeEvents = allScheduleEvents.where((e) => !e.hasTimeSet).toList();

      setState(() {
        // 시간 정보가 있는 일정만 타임라인에 표시
        _events = [...routineEvents, ...timeEvents];
        // 이벤트를 시작 시간순으로 정렬
        _events.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

        // 시간 정보가 없는 일정
        _noTimeEvents = noTimeEvents;
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
    final double eventWidth = (widget.fromScreen ? screenWidth : screenWidth / 2) - padding - _timelineWidth; // 일정 카드 폭
    final int totalHours = _endHour - _startHour + 1;
    final double totalHeight = totalHours * _hourHeight;

    return Column(
      children: [
        // 시간 정보 없는 일정 섹션 (있을 경우에만 표시)
        if (_noTimeEvents.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              spacing: 8,
              runSpacing: 8,
              children: _noTimeEvents.map((event) {
                // 타임 테이블 항목과 비슷한 컨테이너 생성
                return GestureDetector(
                  onTap: () => _showEvent(context, event),
                  child: Container(
                    width: (screenWidth / 2) - 24, // 화면 절반에서 여백 제외
                    height: 35, // 요청한 높이
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: event.color,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        // 타임라인 섹션
        Expanded(
          child: SingleChildScrollView(
            controller: _timelineCont,
            child: Stack(
              children: [
                Container(
                  height: totalHeight,
                  margin: EdgeInsets.only(left: _timelineWidth),
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
                            '$hour',
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
                                  height: 450,
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
                          width: widget.fromScreen ? screenWidth : (screenWidth / 2),
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

                  // 메인 일정 위젯 반환
                  return Positioned(
                    left: _timelineWidth + eventHorizontalPadding,
                    top: topPosition + timelineOffset, // 일관된 오프셋 사용
                    child: GestureDetector(
                      child: Stack(
                        children: [
                          // 드래그 중에는 원래 이벤트 위에 그림자 표시
                          if (_draggingEvent == event && _dragCurrentY != null && _dragStartY != null) _buildDragShadow(event, eventWidth, height),

                          // 기존 컨테이너 (실제 이벤트 표시)
                          Container(
                            width: eventWidth - (2 * eventHorizontalPadding),
                            height: height,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (_draggingEvent == event && _hasConflict)
                                  ? Colors.red.withOpacity(0.7) // 충돌 시 빨간색 표시
                                  : (_draggingEvent == event)
                                      ? event.color.withOpacity(0.7) // 드래그 중
                                      : event.color, // 일반 상태
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

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: eventFontSize,
                                      ),
                                      overflow: overflowed ? TextOverflow.clip : TextOverflow.ellipsis,
                                    ),
                                    // 드래그 중에는 원래 시간 표시 (더이상 변경된 시간을 텍스트로 표시하지 않음)
                                    // 40분 초과 일정에만 시간 표시 (높이 기준이 아닌 실제 기간으로 판단)
                                    if (event.durationMinutes > 40)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          '${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _showEvent(context, event),
                      onLongPressStart: (details) {
                        // 루틴은 드래그 불가
                        if (event.isRoutine) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('루틴은 드래그할 수 없습니다'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _draggingEvent = event;
                          _dragStartY = details.globalPosition.dy;
                          _originalTopPosition = topPosition;
                          _originalStartTime = event.startTime;
                          _originalEndTime = event.endTime;
                          _hasConflict = false;
                          _conflictEvent = null;
                        });
                      },
                      onLongPressMoveUpdate: (details) {
                        if (_draggingEvent != event || _dragStartY == null || _originalTopPosition == null) {
                          return;
                        }

                        // 현재 드래그 위치 저장
                        _dragCurrentY = details.globalPosition.dy;

                        // 이동한 거리 계산
                        final dragDeltaY = _dragCurrentY! - _dragStartY!;

                        // 5분 단위 스냅 계산 (5분 = _hourHeight / 12)
                        final snapToGridDeltaY = (dragDeltaY / (_hourHeight / 12)).round() * (_hourHeight / 12);

                        // 새 위치 계산
                        final newTopPosition = _originalTopPosition! + snapToGridDeltaY;

                        // 범위 검사 (타임라인 밖으로 나가지 않도록)
                        if (newTopPosition < 0 || newTopPosition + height > totalHeight) {
                          return;
                        }

                        // 새 시간 계산 (분 단위)
                        final newStartMinutes = (newTopPosition - timelineOffset) / _hourHeight * 60 + _startHour * 60;

                        // 5분 단위로 반올림
                        final roundedStartMinutes = (newStartMinutes / 5).round() * 5;

                        // 이벤트 길이 유지 (분 단위)
                        final durationMinutes = event.durationMinutes;
                        final newEndMinutes = roundedStartMinutes + durationMinutes;

                        // 새 시간 객체 생성
                        final newStartTime = TimeOfDay(
                          hour: (roundedStartMinutes / 60).floor(),
                          minute: roundedStartMinutes % 60,
                        );

                        final newEndTime = TimeOfDay(
                          hour: (newEndMinutes / 60).floor(),
                          minute: newEndMinutes % 60,
                        );

                        // 충돌 감지
                        _checkConflictForDrag(event, newStartTime, newEndTime);

                        // 화면 업데이트 (드래그 중인 이벤트 위치 변경)
                        setState(() {});
                      },
                      onLongPressEnd: (details) {
                        if (_draggingEvent != event ||
                            _dragStartY == null ||
                            _originalTopPosition == null ||
                            _originalStartTime == null ||
                            _originalEndTime == null) {
                          return;
                        }

                        // 이동한 거리 계산
                        final dragDeltaY = details.globalPosition.dy - _dragStartY!;

                        // 5분 단위 스냅 계산
                        final snapToGridDeltaY = (dragDeltaY / (_hourHeight / 12)).round() * (_hourHeight / 12);

                        // 새 위치 계산
                        final newTopPosition = _originalTopPosition! + snapToGridDeltaY;

                        // 범위 검사
                        if (newTopPosition < 0 || newTopPosition + height > totalHeight) {
                          _resetDragState();
                          return;
                        }

                        // 새 시간 계산 (분 단위)
                        final newStartMinutes = (newTopPosition - timelineOffset) / _hourHeight * 60 + _startHour * 60;

                        // 5분 단위로 반올림
                        final roundedStartMinutes = (newStartMinutes / 5).round() * 5;

                        // 이벤트 길이 유지 (분 단위)
                        final durationMinutes = event.durationMinutes;
                        final newEndMinutes = roundedStartMinutes + durationMinutes;

                        // 새 시간 객체 생성
                        final newStartTime = TimeOfDay(
                          hour: (roundedStartMinutes / 60).floor(),
                          minute: roundedStartMinutes % 60,
                        );

                        final newEndTime = TimeOfDay(
                          hour: (newEndMinutes / 60).floor(),
                          minute: newEndMinutes % 60,
                        );

                        // 충돌 확인
                        if (_hasConflict) {
                          // 충돌이 있으면 원래 시간으로 복원
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_conflictEvent != null
                                  ? '${_formatTime(_conflictEvent!.startTime)}~${_formatTime(_conflictEvent!.endTime)}의 "${_conflictEvent!.title}" 일정과 충돌합니다'
                                  : '다른 일정과 시간이 중복됩니다'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          _resetDragState();
                          return;
                        }

                        // 이벤트 시간 업데이트
                        _updateEventTime(event, newStartTime, newEndTime);

                        // 드래그 상태 초기화
                        _resetDragState();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
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

  // 드래그 상태 초기화
  void _resetDragState() {
    setState(() {
      _draggingEvent = null;
      _dragStartY = null;
      _originalTopPosition = null;
      _originalStartTime = null;
      _originalEndTime = null;
      _hasConflict = false;
      _conflictEvent = null;
    });
  }

  // 드래그 중인 이벤트의 새 시간 계산
  Map<String, TimeOfDay> _calculateDraggedTime(Event event, double startY, double currentY) {
    if (_originalTopPosition == null || _originalStartTime == null || _originalEndTime == null) {
      return {
        'start': event.startTime,
        'end': event.endTime,
      };
    }

    // 이동한 거리 계산
    final dragDeltaY = currentY - startY;

    // 5분 단위 스냅 계산
    final snapToGridDeltaY = (dragDeltaY / (_hourHeight / 12)).round() * (_hourHeight / 12);

    // 새 위치 계산
    final newTopPosition = _originalTopPosition! + snapToGridDeltaY;

    // 새 시간 계산 (분 단위)
    final newStartMinutes = (newTopPosition - timelineOffset) / _hourHeight * 60 + _startHour * 60;

    // 5분 단위로 반올림
    final roundedStartMinutes = (newStartMinutes / 5).round() * 5;

    // 이벤트 길이 유지 (분 단위)
    final durationMinutes = event.durationMinutes;
    final newEndMinutes = roundedStartMinutes + durationMinutes;

    // 새 시간 객체 생성
    final newStartTime = TimeOfDay(
      hour: (roundedStartMinutes / 60).floor(),
      minute: roundedStartMinutes % 60,
    );

    final newEndTime = TimeOfDay(
      hour: (newEndMinutes / 60).floor(),
      minute: newEndMinutes % 60,
    );

    return {
      'start': newStartTime,
      'end': newEndTime,
    };
  }

  // 일정 시간 업데이트 메서드
  Future<void> _updateEventTime(Event event, TimeOfDay newStartTime, TimeOfDay newEndTime) async {
    if (event.isRoutine) {
      // 루틴은 수정하지 않음
      return;
    }

    // 일반 일정 업데이트
    final scheduleRepo = ScheduleRepository();
    await scheduleRepo.init();

    final item = scheduleRepo.getItem(event.id);
    if (item == null) {
      return;
    }

    // 새 ScheduleItem 생성 (기존 정보 유지, 시간만 변경)
    final updatedItem = ScheduleItem(
      year: item.year,
      month: item.month,
      date: item.date,
      title: item.title,
      description: item.description,
      startHour: newStartTime.hour,
      startMinute: newStartTime.minute,
      endHour: newEndTime.hour,
      endMinute: newEndTime.minute,
      colorValue: item.colorValue,
    );

    // ID 설정
    updatedItem.id = item.id;

    // 업데이트 실행
    await scheduleRepo.updateItem(updatedItem);

    // 이벤트 목록 새로고침
    _loadEventsForDate();
  }

  // 드래그 중 충돌 감지
  void _checkConflictForDrag(Event event, TimeOfDay newStartTime, TimeOfDay newEndTime) async {
    if (event.isRoutine) {
      return;
    }

    // 충돌 감지 로직
    final newStartMinutes = newStartTime.hour * 60 + newStartTime.minute;
    final newEndMinutes = newEndTime.hour * 60 + newEndTime.minute;

    // 현재 표시 중인 이벤트와 충돌 확인 (자기 자신 제외)
    bool hasConflict = false;
    Event? conflictingEvent;

    for (var otherEvent in _events) {
      // 자기 자신은 건너뛰기
      if (otherEvent.id == event.id && otherEvent.isRoutine == event.isRoutine) {
        continue;
      }

      final otherStartMinutes = otherEvent.startMinutes;
      final otherEndMinutes = otherEvent.endMinutes;

      // 충돌 조건 검사
      if ((newStartMinutes >= otherStartMinutes && newStartMinutes < otherEndMinutes) || // 시작 시간이 다른 일정 내에 있음
          (newEndMinutes > otherStartMinutes && newEndMinutes <= otherEndMinutes) || // 종료 시간이 다른 일정 내에 있음
          (newStartMinutes <= otherStartMinutes && newEndMinutes >= otherEndMinutes)) {
        // 다른 일정을 완전히 포함
        hasConflict = true;
        conflictingEvent = otherEvent;
        break;
      }
    }

    setState(() {
      _hasConflict = hasConflict;
      _conflictEvent = conflictingEvent;
    });
  }

  // 드래그 그림자 위젯 생성 메서드
  // 드래그 중인 일정의 그림자(가상 위치 표시기) 생성
  Widget _buildDragShadow(Event event, double width, double height) {
    if (_dragStartY == null || _dragCurrentY == null) {
      return const SizedBox.shrink();
    }

    // 드래그된 새 위치 계산
    final draggedTimes = _calculateDraggedTime(event, _dragStartY ?? 0, _dragCurrentY ?? 0);
    final newStartMinutes = draggedTimes['start']!.hour * 60 + draggedTimes['start']!.minute;

    // 타임라인 기준으로 새 위치 계산
    final newTopPosition = (newStartMinutes - _startHour * 60) / 60 * _hourHeight + timelineOffset;
    final currentTopPosition = ((event.startMinutes - _startHour * 60) / 60 * _hourHeight) + timelineOffset;
    final deltaY = newTopPosition - currentTopPosition;

    return Transform.translate(
      offset: Offset(0, deltaY), // Y축으로만 이동
      child: Container(
        width: width - (2 * eventHorizontalPadding),
        height: height,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _hasConflict ? Colors.red.withOpacity(0.4) : event.color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: _hasConflict ? Colors.red.shade700 : event.color.withAlpha(200),
            width: 2,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: _hasConflict ? Colors.red.withOpacity(0.5) : Colors.black.withOpacity(0.2),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _hasConflict ? Colors.white : Colors.white.withOpacity(0.9),
                fontSize: eventFontSize,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            // 40분 초과 일정에만 그림자에도 시간 표시
            if (event.durationMinutes > 40) ...[
              const SizedBox(height: 4),
              Text(
                '${_formatTime(draggedTimes['start']!)} - ${_formatTime(draggedTimes['end']!)}',
                style: TextStyle(
                  color: _hasConflict ? Colors.white : Colors.white.withOpacity(0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 시간 포맷팅 메서드
  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // 이벤트 시간 포맷팅 메서드
  String _formatEventTime(Event event, Map<String, TimeOfDay> times) {
    final start = times['start'] ?? event.startTime;
    final end = times['end'] ?? event.endTime;
    return '${_formatTime(start)} - ${_formatTime(end)}';
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
          height: 450,
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
}

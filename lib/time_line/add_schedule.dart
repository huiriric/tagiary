import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:tagiary/component/day_picker/day_picker.dart';
import 'package:tagiary/constants/colors.dart';
import 'package:tagiary/main.dart';
import 'package:tagiary/screens/home_screen.dart';
import 'package:tagiary/tables/check/check_enum.dart';
import 'package:tagiary/tables/check/check_item.dart';
import 'package:tagiary/tables/check_routine/check_routine_item.dart';
import 'package:tagiary/tables/data_models/event.dart';
import 'package:tagiary/tables/schedule/schedule_item.dart';
import 'package:tagiary/tables/schedule_routine/schedule_routine_item.dart';
import 'package:tagiary/tables/schedule_links/schedule_link_item.dart';

class AddSchedule extends StatefulWidget {
  DateTime date;
  TimeOfDay start;
  TimeOfDay end;
  final VoidCallback? onScheduleAdded; // 일정 추가 후 호출할 콜백 함수

  AddSchedule({super.key, required this.date, required this.start, required this.end, this.onScheduleAdded});

  @override
  State<AddSchedule> createState() => _AddScheduleState();
}

// 색상 리스트는 constants/colors.dart로 이동했습니다

class _AddScheduleState extends State<AddSchedule> {
  /*
  반복여부 - true: 루틴으로 schedule_routine에 저장, false: 날짜와 함께 schedule에 저장
  title
  description
  startHour
  startMinute
  endHour
  endMinute
  colorValue
   */

  String title = '';
  String description = '';

  bool hasMultiDay = false; // 멀티데이 여부
  late DateTime date; // 시작 날짜
  DateTime? endDate; // 멀티데이 종료 날짜

  late TextEditingController titleCont;
  late TextEditingController descriptionCont;

  // FocusNode 추가
  final FocusNode titleFocus = FocusNode();
  final FocusNode descriptionFocus = FocusNode();

  bool isRoutine = false;
  List<bool> selectedDays = List.generate(7, (index) => false);
  bool hasTimeSet = true; // 시간 설정 여부 체크박스

  late TimeOfDay start;
  late TimeOfDay end;

  late Color selectedColor;
  bool isLoading = false;

  // 충돌 감지를 위한 변수
  Event? _conflictEvent;

  @override
  void initState() {
    super.initState();
    titleCont = TextEditingController();
    descriptionCont = TextEditingController();
    date = widget.date;
    start = widget.start;
    end = widget.end;
    selectedColor = scheduleColors[0];
  }

  @override
  void dispose() {
    // FocusNode 해제
    titleFocus.dispose();
    descriptionFocus.dispose();

    // 컨트롤러 해제
    titleCont.dispose();
    descriptionCont.dispose();

    super.dispose(); // super.dispose()를 마지막에 호출
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 15.0, bottom: 2),
          child: GestureDetector(
            // 빈 영역 터치 시 키보드 숨기기
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextFormField(
                  onChanged: (value) {
                    title = value;
                  },
                  controller: titleCont,
                  focusNode: titleFocus, // FocusNode 연결
                  autofocus: true,
                  // 키 이벤트 처리 추가
                  onEditingComplete: () {
                    descriptionFocus.requestFocus(); // 다음 필드로 포커스 이동
                  },
                  decoration: const InputDecoration(
                    hintText: '일정',
                    // 언더라인 완전 제거
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    // 힌트 스타일 커스터마이징
                    hintStyle: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextFormField(
                  onChanged: (value) {
                    description = value;
                  },
                  controller: descriptionCont,
                  focusNode: descriptionFocus, // FocusNode 연결
                  // 키보드 유형 명시적 설정 (멀티라인)
                  keyboardType: TextInputType.multiline,
                  maxLines: null, // 여러 줄 입력 가능
                  // 다음 액션 설정
                  textInputAction: TextInputAction.done,
                  onEditingComplete: () {
                    // 키보드 숨기기
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  decoration: const InputDecoration(
                    hintText: '노트',
                    // 언더라인 완전 제거
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    // 힌트 스타일 커스터마이징
                    hintStyle: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Divider(
                  height: 5,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),

                // 옵션 섹션
                Row(
                  children: [
                    // 반복 옵션
                    const Text(
                      '반복',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Checkbox(
                      value: isRoutine,
                      activeColor: Colors.indigo,
                      shape: const CircleBorder(),
                      onChanged: (value) {
                        setState(() {
                          isRoutine = value!;
                        });
                      },
                    ),
                    const Spacer(),

                    // 시간 설정 옵션
                    const Text(
                      '시간 설정',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Checkbox(
                      value: hasTimeSet,
                      activeColor: Colors.indigo,
                      shape: const CircleBorder(),
                      onChanged: (value) {
                        setState(() {
                          hasTimeSet = value!;
                        });
                      },
                    ),
                  ],
                ),
                // 날짜 선택 (isRoutine이 false일 때) 또는 요일 선택 (isRoutine이 true일 때)
                !isRoutine
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          TextButton(
                            onPressed: () async {
                              final selectedDate = await showBlackWhiteDatePicker(
                                context: context,
                                initialDate: date,
                              );
                              if (selectedDate != null) {
                                setState(() {
                                  date = selectedDate;
                                });
                              }
                            },
                            child: Text(
                              '${endDate != null ? '시작 ' : ''}${formatDate(date)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: endDate != null ? 15 : 16,
                                color: const Color(0xFF40608A),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: endDate != null ? const Color(0x00000000) : const Color(0x1140608A),
                            ),
                            onPressed: () async {
                              final selectedDate = await showBlackWhiteDatePicker(
                                context: context,
                                initialDate: endDate, // 종료일 선택 시 기본값은 시작일 다음 날
                              );
                              if (selectedDate != null) {
                                setState(() {
                                  endDate = selectedDate;
                                });
                              }
                            },
                            child: Text(
                              endDate != null ? '종료 ${formatDate(endDate!)}' : '종료일 선택',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: endDate != null ? 15 : 16,
                                color: const Color(0xFF40608A),
                              ),
                            ),
                          ),
                          if (endDate != null)
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    endDate = null; // 종료일 초기화
                                  });
                                },
                                icon: const Icon(
                                  Icons.cancel_rounded,
                                  color: Color(0x2240608A),
                                ))
                        ],
                      )
                    : DayPicker(
                        selectedDays: selectedDays,
                        onDaysChanged: (days) {
                          setState(() {
                            selectedDays = days;
                          });
                        },
                      ),
                // 시간 설정이 체크된 경우에만 시간 선택 위젯 표시
                if (hasTimeSet) TimePicker(startTime: start, endTime: end),
                // 색상 선택
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '색상',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          // 첫 번째 줄 (색상 0-5)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(6, (index) {
                              final color = scheduleColors[index];
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedColor = color;
                                  });
                                },
                                child: Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: selectedColor == color ? Border.all(color: Colors.black, width: 2) : null,
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 12),
                          // 두 번째 줄 (색상 6-11)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(6, (index) {
                              final color = scheduleColors[index + 6];
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedColor = color;
                                  });
                                },
                                child: Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: selectedColor == color ? Border.all(color: Colors.black, width: 2) : null,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 15,
          right: 20,
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                )
              : IconButton(
                  onPressed: _saveSchedule,
                  icon: const Icon(
                    Icons.check,
                    color: Colors.green,
                    size: 32,
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _saveSchedule() async {
    // 입력 검증
    if (title.isEmpty) {
      _showToast('제목을 입력해주세요');
      return;
    }

    // 종료일이 설정되어 있을 때 시작일과 종료일 비교
    if (endDate != null && date.isAfter(endDate!)) {
      _showToast('종료일은 시작일보다 나중이어야 합니다');
      return;
    }

    // 시간 설정이 있을 때만 시간 유효성 검사
    if (hasTimeSet && (start.hour > end.hour || (start.hour == end.hour && start.minute >= end.minute))) {
      _showToast('종료 시간은 시작 시간보다 나중이어야 합니다');
      return;
    }

    if (isRoutine && !selectedDays.contains(true)) {
      _showToast('반복할 요일을 최소 하나 이상 선택해주세요');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (isRoutine) {
        // 요일 기반 일정 (루틴)
        await _saveRoutineSchedule();
      } else {
        // 날짜 기반 일정
        if (hasTimeSet) {
          // 케이스 1: 날짜 + 시간 - 타임라인에 추가
          await _saveNormalSchedule();

          // 할 일에도 추가할지 묻기
          // final addToTodo = await _showAddToTodoDialog();
          // if (addToTodo) {
          //   await _addToTodo();
          // }
        } else {
          // 케이스 2: 날짜 + 시간 없음 - 일정에 시간 없이 저장
          await _saveNormalScheduleWithoutTime();

          // 할 일에도 추가할지 묻기
          // final addToTodo = await _showAddToTodoDialog();
          // if (addToTodo) {
          //   await _addToTodo();
          // }
        }
      }

      if (widget.onScheduleAdded != null) {
        widget.onScheduleAdded!();
        print('callback called');
      }

      // Future.delayed(const Duration(microseconds: 300));

      if (mounted) {
        Navigator.pop(context, true); // 저장 성공 시 화면 닫기
        print('pop');
      }
    } catch (e) {
      _showToast('저장 중 오류가 발생했습니다: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // 할 일에도 추가할지 묻는 다이얼로그
  Future<bool> _showAddToTodoDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('할 일 추가'),
        content: const Text('이 일정을 할 일에도 추가하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('아니요'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('추가하기'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // 루틴에 추가할지 묻는 다이얼로그
  Future<bool> _showAddToRoutineDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('루틴 추가'),
        content: const Text('이 일정을 루틴에도 추가하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('아니요'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('추가하기'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // 시간 없는 요일 선택 시 루틴으로 분류됨을 안내하는 다이얼로그
  Future<bool> _showAddToRoutineOnlyDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('루틴으로 분류'),
        content: const Text('시간이 설정되지 않은 요일 기반 일정은 루틴으로 분류됩니다. 루틴에 추가하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('추가하기'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // 시간 정보 없는 일정 저장 메서드
  Future<void> _saveNormalScheduleWithoutTime() async {
    final scheduleRepository = ScheduleRepository();
    await scheduleRepository.init();

    final newSchedule = ScheduleItem(
      year: date.year,
      month: date.month,
      date: date.day,
      endYear: endDate?.year,
      endMonth: endDate?.month,
      endDate: endDate?.day, // 멀티데이 종료 날짜
      title: title,
      description: description,
      startHour: null, // 시간 정보 null로 설정
      startMinute: null,
      endHour: null,
      endMinute: null,
      colorValue: selectedColor.value,
    );

    await scheduleRepository.addItem(newSchedule);
  }

  // Todo에 추가하는 메서드 (일반 일정일 때)
  Future<void> _addToTodo() async {
    final checkRepository = CheckRepository();
    await checkRepository.init();

    final newTodo = CheckItem(
      id: 0, // 저장소에서 할당
      content: title,
      dueDate: date.toIso8601String(), // 현재 날짜 사용
      startDate: null, // 시작 날짜도 현재 날짜로 설정
      doneDate: null, // 완료 날짜는 null로 설정
      colorValue: selectedColor.value,
      check: CheckEnum.pending,
    );

    final todoId = await checkRepository.addItem(newTodo);

    // 일정과 할 일 사이의 연결 정보 저장
    final scheduleRepository = ScheduleRepository();
    await scheduleRepository.init();

    // 가장 최근 추가된 일정 ID 가져오기
    final schedules = scheduleRepository.getAllItems();
    final latestSchedule = schedules.isNotEmpty ? schedules.last : null;

    if (latestSchedule != null) {
      final linkRepo = ScheduleLinkRepository();
      await linkRepo.init();

      final newLink = ScheduleLinkItem(
        scheduleId: latestSchedule.id,
        isRoutine: false,
        linkedItemId: todoId,
        linkedItemType: LinkItemType.todo,
      );

      await linkRepo.addItem(newLink);
    }
  }

  // Todo Routine에 추가하는 메서드 (루틴 일정일 때)
  Future<void> _addToTodoRoutine() async {
    final checkRoutineRepository = CheckRoutineRepository();
    await checkRoutineRepository.init();

    final newRoutine = CheckRoutineItem(
        id: 0, // 저장소에서 할당
        content: title,
        colorValue: selectedColor.value,
        check: false,
        updated: DateTime.now(),
        daysOfWeek: selectedDays);

    final routineId = await checkRoutineRepository.addItem(newRoutine);

    // 일정과 루틴 사이의 연결 정보 저장
    final routineRepository = ScheduleRoutineRepository();
    await routineRepository.init();

    // 가장 최근 추가된 루틴 ID 가져오기
    final routines = routineRepository.getAllItems();
    final latestRoutine = routines.isNotEmpty ? routines.last : null;

    if (latestRoutine != null) {
      final linkRepo = ScheduleLinkRepository();
      await linkRepo.init();

      final newLink = ScheduleLinkItem(
        scheduleId: latestRoutine.id,
        isRoutine: true,
        linkedItemId: routineId,
        linkedItemType: LinkItemType.todoRoutine,
      );

      await linkRepo.addItem(newLink);
    }
  }

  Future<void> _saveNormalSchedule() async {
    // 일정 중복 체크
    _conflictEvent = null; // 충돌 정보 초기화

    if (hasTimeSet && await _checkNormalScheduleConflict()) {
      if (_conflictEvent != null) {
        // 충돌하는 이벤트 정보를 포함한 에러 메시지
        String conflictType = _conflictEvent!.isRoutine ? "루틴" : "일정";
        throw Exception(
            '${formatTime(_conflictEvent!.startTime!)}~${formatTime(_conflictEvent!.endTime!)}에 "${_conflictEvent!.title}" $conflictType과(와) 시간이 중복됩니다');
      } else {
        throw Exception('해당 시간에 이미 일정이 있습니다');
      }
    }

    final scheduleRepository = ScheduleRepository();
    await scheduleRepository.init();

    final newSchedule = ScheduleItem(
      year: date.year,
      month: date.month,
      date: date.day,
      endYear: endDate?.year,
      endMonth: endDate?.month,
      endDate: endDate?.day, // 멀티데이 종료 날짜
      title: title,
      description: description,
      startHour: start.hour,
      startMinute: start.minute,
      endHour: end.hour,
      endMinute: end.minute,
      colorValue: selectedColor.value,
    );

    await scheduleRepository.addItem(newSchedule);
  }

  Future<void> _saveRoutineSchedule() async {
    // 루틴 일정 중복 체크
    _conflictEvent = null; // 충돌 정보 초기화

    if (hasTimeSet && await _checkRoutineScheduleConflict()) {
      if (_conflictEvent != null) {
        // 충돌하는 이벤트 정보를 포함한 에러 메시지
        String conflictType = _conflictEvent!.isRoutine ? "루틴" : "일정";
        throw Exception(
            '선택한 요일 중 "${_conflictEvent!.title}" $conflictType과(와) 시간이 중복됩니다 (${formatTime(_conflictEvent!.startTime!)}~${formatTime(_conflictEvent!.endTime!)})');
      } else {
        throw Exception('선택한 요일 중 하나 이상에서 이미 같은 시간에 일정이 있습니다');
      }
    }

    final routineRepository = ScheduleRoutineRepository();
    await routineRepository.init();

    final newRoutine = ScheduleRoutineItem(
      title: title,
      description: description,
      daysOfWeek: selectedDays,
      startHour: hasTimeSet ? start.hour : null,
      startMinute: hasTimeSet ? start.minute : null,
      endHour: hasTimeSet ? end.hour : null,
      endMinute: hasTimeSet ? end.minute : null,
      colorValue: selectedColor.value,
    );

    await routineRepository.addItem(newRoutine);
  }

  Future<bool> _checkNormalScheduleConflict() async {
    // 일정 중복 확인 로직
    final scheduleRepository = ScheduleRepository();
    await scheduleRepository.init();

    final routineRepository = ScheduleRoutineRepository();
    await routineRepository.init();

    // 1. 해당 날짜의 모든 일반 일정 가져오기
    final dateEvents = scheduleRepository.getDateItems(date);

    // 시간 충돌 확인
    if (_hasTimeConflict(dateEvents)) {
      return true;
    }

    // 2. 해당 날짜의 요일에 해당하는 루틴 일정 확인
    final dayOfWeek = date.weekday % 7; // 0(일)~6(토) 범위로 변환
    final routineEvents = routineRepository.getItemsByDayWithTime(dayOfWeek);

    // 루틴 일정과의 시간 충돌 확인
    return _hasTimeConflict(routineEvents);
  }

  Future<bool> _checkRoutineScheduleConflict() async {
    // 루틴 중복 확인 로직
    final routineRepository = ScheduleRoutineRepository();
    await routineRepository.init();

    final scheduleRepository = ScheduleRepository();
    await scheduleRepository.init();

    // 선택된 각 요일별로 확인
    for (int i = 0; i < selectedDays.length; i++) {
      if (!selectedDays[i]) continue; // 선택되지 않은 요일은 건너뛰기

      // 1. 해당 요일의 모든 루틴 가져오기
      final routineEvents = routineRepository.getItemsByDayWithTime(i);

      // 시간 충돌 확인
      if (_hasTimeConflict(routineEvents)) {
        return true;
      }

      // 2. 해당 요일에 해당하는 일반 일정 확인 (6개월 범위로 검색)
      final today = DateTime.now();
      final sixMonthsLater = today.add(const Duration(days: 180));

      // 오늘부터 6개월 동안의 날짜 중 선택한 요일에 해당하는 날짜들 찾기
      for (DateTime date = today; date.isBefore(sixMonthsLater); date = date.add(const Duration(days: 1))) {
        // 날짜의 요일이 현재 확인 중인 요일과 일치하는지 확인
        if (date.weekday % 7 == i) {
          // 해당 날짜의 일반 일정 가져오기
          final scheduleEvents = scheduleRepository.getTimeItems(date);

          // 시간 충돌 확인
          if (_hasTimeConflict(scheduleEvents)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  bool _hasTimeConflict(Iterable<Event> events) {
    // 시작/종료 시간을 분 단위로 변환
    final newStartMinutes = start.hour * 60 + start.minute;
    final newEndMinutes = end.hour * 60 + end.minute;

    // 모든 이벤트와 시간 충돌 확인
    for (var event in events) {
      final eventStartMinutes = event.startTime!.hour * 60 + event.startTime!.minute;
      final eventEndMinutes = event.endTime!.hour * 60 + event.endTime!.minute;

      // 충돌 조건:
      // 1. 새 이벤트의 시작이 기존 이벤트 기간 내에 있거나
      // 2. 새 이벤트의 종료가 기존 이벤트 기간 내에 있거나
      // 3. 새 이벤트가 기존 이벤트를 완전히 포함하는 경우
      // 충돌이 있는 경우 이벤트 정보를 저장
      if ((newStartMinutes >= eventStartMinutes && newStartMinutes < eventEndMinutes) ||
          (newEndMinutes > eventStartMinutes && newEndMinutes <= eventEndMinutes) ||
          (newStartMinutes <= eventStartMinutes && newEndMinutes >= eventEndMinutes)) {
        _conflictEvent = event; // 충돌하는 이벤트 저장
        return true;
      }
    }

    return false;
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

  Widget TimePicker({
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '시간',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // start hour
              SizedBox(
                width: 50,
                height: 55,
                child: CupertinoPicker(
                  itemExtent: 30,
                  scrollController: FixedExtentScrollController(initialItem: start.hour),
                  onSelectedItemChanged: (i) => setState(() {
                    start = TimeOfDay(hour: i, minute: start.minute);
                  }),
                  children: List.generate(
                    24,
                    (int i) => Center(
                      child: Text(
                        formatEachTime(i),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF40608A),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Text(
                ':',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              // start minute
              SizedBox(
                width: 50,
                height: 55,
                child: CupertinoPicker(
                  itemExtent: 30,
                  scrollController: FixedExtentScrollController(initialItem: start.minute),
                  onSelectedItemChanged: (i) => setState(() {
                    start = TimeOfDay(hour: start.hour, minute: i * 5);
                  }),
                  children: List.generate(
                    12,
                    (int i) => Center(
                      child: Text(
                        formatEachTime(i * 5),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF40608A),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Text(
                ' ~ ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF40608A),
                ),
              ),
              // end hour
              SizedBox(
                width: 50,
                height: 55,
                child: CupertinoPicker(
                  itemExtent: 30,
                  scrollController: FixedExtentScrollController(initialItem: end.hour),
                  onSelectedItemChanged: (i) => setState(() {
                    end = TimeOfDay(hour: i, minute: end.minute);
                  }),
                  children: List.generate(
                    24,
                    (int i) => Center(
                      child: Text(
                        formatEachTime(i),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF40608A),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Text(
                ':',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              // end minute
              SizedBox(
                width: 50,
                height: 55,
                child: CupertinoPicker(
                  itemExtent: 30,
                  scrollController: FixedExtentScrollController(initialItem: end.minute),
                  onSelectedItemChanged: (i) => setState(() {
                    end = TimeOfDay(hour: end.hour, minute: i * 5);
                  }),
                  children: List.generate(
                    12,
                    (int i) => Center(
                      child: Text(
                        formatEachTime(i * 5),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF40608A),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String formatDate(DateTime date) {
  final DateTime now = DateTime.now();
  List<String> week = ['일', '월', '화', '수', '목', '금', '토'];
  return '${now.year == date.year ? '' : {'${date.year}년 '}}${date.month}월 ${date.day}일 (${week[date.weekday % 7]})';
}

String formatTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

String formatEachTime(int time) {
  return time.toString().padLeft(2, '0');
}

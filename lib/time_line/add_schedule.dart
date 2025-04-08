import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:tagiary/component/day_picker/day_picker.dart';
import 'package:tagiary/constants/colors.dart';
import 'package:tagiary/main.dart';
import 'package:tagiary/tables/data_models/event.dart';
import 'package:tagiary/tables/schedule/schedule_item.dart';
import 'package:tagiary/tables/schedule_routine/schedule_routine_item.dart';

class AddSchedule extends StatefulWidget {
  DateTime date;
  TimeOfDay start;
  TimeOfDay end;
  final VoidCallback? onScheduleAdded; // 일정 추가 후 호출할 콜백 함수

  AddSchedule({
    super.key, 
    required this.date, 
    required this.start, 
    required this.end, 
    this.onScheduleAdded
  });

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

  late TextEditingController titleCont;
  late TextEditingController descriptionCont;

  bool isRoutine = false;
  List<bool> selectedDays = List.generate(7, (index) => false);

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

    start = widget.start;
    end = widget.end;
    selectedColor = scheduleColors[0];
  }

  @override
  void dispose() {
    super.dispose();
    titleCont.dispose();
    descriptionCont.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TextFormField(
              onChanged: (value) {
                title = value;
              },
              controller: titleCont,
              decoration: const InputDecoration(
                hintText: '일정 제목',
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
            Row(
              children: [
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
              ],
            ),
            // 날짜 선택 (isRoutine이 false일 때) 또는 요일 선택 (isRoutine이 true일 때)
            !isRoutine
                ? TextButton(
                    onPressed: () async {
                      final selectedDate = await showBlackWhiteDatePicker(
                        context: context,
                        initialDate: widget.date,
                      );
                      if (selectedDate != null) {
                        setState(() {
                          widget.date = selectedDate;
                        });
                      }
                    },
                    child: Text(
                      _formatDate(widget.date),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF40608A),
                      ),
                    ),
                  )
                : DayPicker(
                    selectedDays: selectedDays,
                    onDaysChanged: (days) {
                      setState(() {
                        selectedDays = days;
                      });
                    },
                  ),
            // 시간 선택
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
                          _formatEachTime(i),
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
                      start = TimeOfDay(hour: start.hour, minute: i);
                    }),
                    children: List.generate(
                      60,
                      (int i) => Center(
                        child: Text(
                          _formatEachTime(i),
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
                          _formatEachTime(i),
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
                      end = TimeOfDay(hour: end.hour, minute: i);
                    }),
                    children: List.generate(
                      60,
                      (int i) => Center(
                        child: Text(
                          _formatEachTime(i),
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
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: scheduleColors.map((color) {
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
                    }).toList(),
                  ),
                ],
              ),
            ),

            // 저장 버튼
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveSchedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '저장',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSchedule() async {
    // 입력 검증
    if (title.isEmpty) {
      _showToast('제목을 입력해주세요');
      return;
    }

    if (start.hour > end.hour || (start.hour == end.hour && start.minute >= end.minute)) {
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
        // 루틴 저장 로직
        await _saveRoutineSchedule();
      } else {
        // 일반 일정 저장 로직
        await _saveNormalSchedule();
      }

      // 저장 성공 시 콜백 함수 호출
      if (widget.onScheduleAdded != null) {
        widget.onScheduleAdded!();
      }
      
      Navigator.pop(context); // 저장 성공 시 화면 닫기
    } catch (e) {
      _showToast('저장 중 오류가 발생했습니다: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveNormalSchedule() async {
    // 일정 중복 체크
    _conflictEvent = null; // 충돌 정보 초기화

    if (await _checkNormalScheduleConflict()) {
      if (_conflictEvent != null) {
        // 충돌하는 이벤트 정보를 포함한 에러 메시지
        String conflictType = _conflictEvent!.isRoutine ? "루틴" : "일정";
        throw Exception(
            '${_formatTime(_conflictEvent!.startTime)}~${_formatTime(_conflictEvent!.endTime)}에 "${_conflictEvent!.title}" $conflictType과(와) 시간이 중복됩니다');
      } else {
        throw Exception('해당 시간에 이미 일정이 있습니다');
      }
    }

    final scheduleRepository = ScheduleRepository();
    await scheduleRepository.init();

    final newSchedule = ScheduleItem(
      year: widget.date.year,
      month: widget.date.month,
      date: widget.date.day,
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

    if (await _checkRoutineScheduleConflict()) {
      if (_conflictEvent != null) {
        // 충돌하는 이벤트 정보를 포함한 에러 메시지
        String conflictType = _conflictEvent!.isRoutine ? "루틴" : "일정";
        throw Exception(
            '선택한 요일 중 "${_conflictEvent!.title}" $conflictType과(와) 시간이 중복됩니다 (${_formatTime(_conflictEvent!.startTime)}~${_formatTime(_conflictEvent!.endTime)})');
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
      startHour: start.hour,
      startMinute: start.minute,
      endHour: end.hour,
      endMinute: end.minute,
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
    final dateEvents = scheduleRepository.getDateItems(widget.date);

    // 시간 충돌 확인
    if (_hasTimeConflict(dateEvents)) {
      return true;
    }

    // 2. 해당 날짜의 요일에 해당하는 루틴 일정 확인
    final dayOfWeek = widget.date.weekday % 7; // 0(일)~6(토) 범위로 변환
    final routineEvents = routineRepository.getItemsByDay(dayOfWeek);

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
      final routineEvents = routineRepository.getItemsByDay(i);

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
          final scheduleEvents = scheduleRepository.getDateItems(date);

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
      final eventStartMinutes = event.startTime.hour * 60 + event.startTime.minute;
      final eventEndMinutes = event.endTime.hour * 60 + event.endTime.minute;

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
}

String _formatDate(DateTime date) {
  final DateTime now = DateTime.now();
  List<String> week = ['일', '월', '화', '수', '목', '금', '토'];
  return '${now.year == date.year ? '' : {'${date.year}년 '}}${date.month}월 ${date.day}일 (${week[date.weekday]})';
}

String _formatTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

String _formatEachTime(int time) {
  return time.toString().padLeft(2, '0');
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:tagiary/component/day_picker/day_picker.dart';
import 'package:tagiary/constants/colors.dart';
import 'package:tagiary/main.dart';
import 'package:tagiary/screens/home_screen.dart';
import 'package:tagiary/tables/data_models/event.dart';
import 'package:tagiary/tables/schedule/schedule_item.dart';
import 'package:tagiary/tables/schedule_routine/schedule_routine_item.dart';
import 'package:tagiary/tables/check/check_item.dart';
import 'package:tagiary/tables/check_routine/check_routine_item.dart';
import 'package:tagiary/tables/schedule_links/schedule_link_item.dart';
import 'package:tagiary/time_line/add_schedule.dart';

class ScheduleDetails extends StatefulWidget {
  final Event event;
  final Function onUpdate; // 일정 변경시 호출할 콜백 함수

  const ScheduleDetails({
    super.key,
    required this.event,
    required this.onUpdate,
  });

  @override
  State<ScheduleDetails> createState() => _ScheduleDetailsState();
}

class _ScheduleDetailsState extends State<ScheduleDetails> {
  bool _isEditing = false;
  bool _isLoading = false;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late FocusNode _titleFocusNode;
  late FocusNode _descriptionFocusNode;
  late DateTime? _date; // 날짜 정보\
  late List<bool>? selectedDays;
  late TimeOfDay? _startTime;
  late TimeOfDay? _endTime;
  late Color _selectedColor;
  late bool _isRoutine;
  late bool _hasTimeSet; // 시간 설정 여부
  late Key _dayPickerKey;

  late FixedExtentScrollController _startHourController;
  late FixedExtentScrollController _startMinuteController;
  late FixedExtentScrollController _endHourController;
  late FixedExtentScrollController _endMinuteController;

  DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(text: widget.event.description);
    _titleFocusNode = FocusNode();
    _descriptionFocusNode = FocusNode();
    _date = widget.event.date;
    _startTime = widget.event.startTime;
    _endTime = widget.event.endTime;
    _selectedColor = widget.event.color;
    _isRoutine = widget.event.isRoutine;
    _hasTimeSet = widget.event.hasTimeSet;
    selectedDays = widget.event.daysOfWeek;
    _dayPickerKey = UniqueKey();
    _initializeControllers();
  }

  void _initializeControllers() {
    _startHourController = FixedExtentScrollController(initialItem: _startTime!.hour);
    _startMinuteController = FixedExtentScrollController(initialItem: _startTime!.minute ~/ 5);
    _endHourController = FixedExtentScrollController(initialItem: _endTime!.hour);
    _endMinuteController = FixedExtentScrollController(initialItem: _endTime!.minute ~/ 5);
  }

  void _resetTimePickers() {
    print(_startTime);
    print(_endTime);
    // setState(() {
    //   _startTime = widget.event.startTime;
    //   _endTime = widget.event.endTime;
    // });
    print((widget.event.startTime!.hour).toDouble());
    print((widget.event.startTime!.minute ~/ 5).toDouble());
    print((widget.event.endTime!.hour).toDouble());
    print((widget.event.endTime!.minute ~/ 5).toDouble());

    // 스크롤 위치도 원래대로 되돌리기
    _startHourController.animateToItem(
      widget.event.startTime!.hour,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _startMinuteController.animateToItem(
      widget.event.startTime!.minute ~/ 5,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _endHourController.animateToItem(
      widget.event.endTime!.hour,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _endMinuteController.animateToItem(
      widget.event.endTime!.minute ~/ 5,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _startHourController.dispose();
    _startMinuteController.dispose();
    _endHourController.dispose();
    _endMinuteController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (detectDiff() && !_isEditing) {
      // 편집 모드로 전환
      setState(() {
        _isEditing = true;
      });
    } else if (!detectDiff() && _isEditing) {
      // 편집 모드 종료
      setState(() {
        _isEditing = false;
      });
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GestureDetector(
          onTap: () {
            // 터치 시 키보드 내리기
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // 헤더와 삭제 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 일정 이름
                  Expanded(
                    child: TextFormField(
                      onChanged: (value) {
                        setState(() {
                          _titleController.text = value;
                        });
                      },
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      // autofocus: true,
                      onEditingComplete: () {
                        _descriptionFocusNode.requestFocus();
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
                  ),

                  Row(
                    children: [
                      if (_isEditing)
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              // 편집 취소시 원래 값으로 복원
                              _titleController.text = widget.event.title;
                              _descriptionController.text = widget.event.description;
                              selectedDays = widget.event.daysOfWeek;
                              _date = widget.event.date;
                              _hasTimeSet = widget.event.hasTimeSet;
                              _isRoutine = widget.event.isRoutine;
                              _selectedColor = widget.event.color;
                              _isEditing = false;
                              _dayPickerKey = UniqueKey(); // DayPicker 새로고침
                              if (_hasTimeSet) {
                                print(_startTime);
                                print(_endTime);
                                _startTime = widget.event.startTime;
                                _endTime = widget.event.endTime;
                                _resetTimePickers();
                              }
                            });
                          },
                          color: Colors.grey,
                          tooltip: '편집 취소',
                        ),
                      if (_isEditing)
                        IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: _isLoading
                              ? null
                              : () {
                                  _updateSchedule();
                                },
                          color: Colors.green,
                          tooltip: '저장',
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: _isLoading
                            ? null
                            : () async {
                                final confirm = await _showConfirmDialog('정말 이 일정을 삭제하시겠습니까?');

                                if (confirm) {
                                  _deleteSchedule();
                                }
                              },
                        color: Colors.red,
                        tooltip: '삭제',
                      ),
                    ],
                  ),
                ],
              ),

              TextFormField(
                onChanged: (value) {
                  setState(() {
                    _descriptionController.text = value;
                  });
                },
                controller: _descriptionController,
                focusNode: _descriptionFocusNode,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                textInputAction: TextInputAction.done,
                onEditingComplete: () {
                  // 키보드 내리기
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

              !_isRoutine
                  ? TextButton(
                      onPressed: () async {
                        final selectedDate = await showBlackWhiteDatePicker(
                          context: context,
                          initialDate: _date,
                        );
                        if (selectedDate != null) {
                          setState(() {
                            _date = selectedDate;
                          });
                        }
                      },
                      child: Text(
                        formatDate(_date!),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF40608A),
                        ),
                      ),
                    )
                  : DayPicker(
                      key: _dayPickerKey,
                      selectedDays: selectedDays!,
                      onDaysChanged: (days) {
                        setState(() {
                          selectedDays = days;
                        });
                      },
                    ),
              _isRoutine
                  //
                  ? _hasTimeSet
                      ? GestureDetector(
                          onTap: () => _showToast('반복 일정은 시간을 수정할 수 없습니다.'),
                          // TimePicker 위젯을 클릭할 수 없도록 하기
                          child: AbsorbPointer(child: timePicker()),
                        )
                      : const SizedBox.shrink()
                  : _hasTimeSet
                      ? timePicker()
                      : const SizedBox.shrink(),
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
                                  _selectedColor = color;
                                });
                              },
                              child: Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: _selectedColor == color ? Border.all(color: Colors.black, width: 2) : null,
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
                                  _selectedColor = color;
                                });
                              },
                              child: Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: _selectedColor == color ? Border.all(color: Colors.black, width: 2) : null,
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

              // 로딩 표시
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool detectDiff() {
    // 제목, 설명, 시간, 색상 변경 여부 확인
    final isTitleChanged = _titleController.text != widget.event.title;
    final isDescriptionChanged = _descriptionController.text != widget.event.description;
    final isDateChanged = _date != widget.event.date;
    final isRoutineChanged = selectedDays != widget.event.daysOfWeek;
    final isStartTimeChanged = _startTime != widget.event.startTime;
    final isEndTimeChanged = _endTime != widget.event.endTime;
    final isColorChanged = _selectedColor != widget.event.color;

    return isTitleChanged || isDescriptionChanged || isDateChanged || isRoutineChanged || isStartTimeChanged || isEndTimeChanged || isColorChanged;
  }

  Widget timePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '시간',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              if (_isRoutine)
                const Text(
                  '반복 일정은 시간을 수정할 수 없습니다',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
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
                  scrollController: _startHourController,
                  onSelectedItemChanged: (i) => setState(() {
                    // print(_startTime);
                    _startTime = TimeOfDay(hour: i, minute: _startTime!.minute);
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
                  scrollController: _startMinuteController,
                  onSelectedItemChanged: (i) => setState(() {
                    _startTime = TimeOfDay(hour: _startTime!.hour, minute: i * 5);
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
                  scrollController: _endHourController,
                  onSelectedItemChanged: (i) => setState(() {
                    _endTime = TimeOfDay(hour: i, minute: _endTime!.minute);
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
                  scrollController: _endMinuteController,
                  onSelectedItemChanged: (i) => setState(() {
                    _endTime = TimeOfDay(hour: _endTime!.hour, minute: i * 5);
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

  // 일정 삭제 함수
  Future<void> _deleteSchedule() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 연결된 루틴/할일 항목 체크
      final linkRepo = ScheduleLinkRepository();
      await linkRepo.init();

      final linkedItems = linkRepo.getLinksForSchedule(widget.event.id, widget.event.isRoutine);

      // 연결된 항목이 있는 경우 함께 삭제할지 확인
      bool deleteLinkedItems = false;

      if (linkedItems.isNotEmpty) {
        deleteLinkedItems = await _showDeleteLinkedItemsDialog(linkedItems);
      }

      // 일정 삭제
      if (widget.event.isRoutine) {
        // 루틴 일정 삭제
        final routineRepo = ScheduleRoutineRepository();
        await routineRepo.init();
        await routineRepo.deleteItem(widget.event.id);
      } else {
        // 일반 일정 삭제
        final scheduleRepo = ScheduleRepository();
        await scheduleRepo.init();
        await scheduleRepo.deleteItem(widget.event.id);
      }

      // 연결된 항목들 삭제
      if (deleteLinkedItems) {
        await _deleteLinkedItems(linkedItems);
      } else {
        // 연결 정보만 삭제
        await linkRepo.deleteLinksForSchedule(widget.event.id, widget.event.isRoutine);
      }

      // 삭제 성공 알림
      _showToast('일정이 삭제되었습니다');

      // 콜백 호출하여 메인 화면 업데이트
      widget.onUpdate();

      // 상세 화면 닫기
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showToast('삭제 중 오류가 발생했습니다: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 연결된 항목들을 삭제할지 물어보는 다이얼로그
  Future<bool> _showDeleteLinkedItemsDialog(List<ScheduleLinkItem> linkedItems) async {
    // 연결된 항목 정보 구성
    int todoCount = 0;
    int routineCount = 0;

    for (var link in linkedItems) {
      if (link.linkedItemType == LinkItemType.todo) {
        todoCount++;
      } else if (link.linkedItemType == LinkItemType.todoRoutine) {
        routineCount++;
      }
    }

    // 다이얼로그 메시지 구성
    String message = '이 일정에 연결된 ';

    if (todoCount > 0 && routineCount > 0) {
      message += '할 일 $todoCount개와 루틴 $routineCount개';
    } else if (todoCount > 0) {
      message += '할 일 $todoCount개';
    } else if (routineCount > 0) {
      message += '루틴 $routineCount개';
    }

    message += '도 함께 삭제하시겠습니까?';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('연결된 항목 삭제'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('연결만 해제'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('함께 삭제'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // 연결된 항목들 삭제
  Future<void> _deleteLinkedItems(List<ScheduleLinkItem> linkedItems) async {
    final checkRepo = CheckRepository();
    await checkRepo.init();

    final routineRepo = CheckRoutineRepository();
    await routineRepo.init();

    for (var link in linkedItems) {
      if (link.linkedItemType == LinkItemType.todo) {
        // 할 일 삭제
        await checkRepo.deleteItem(link.linkedItemId);
      } else if (link.linkedItemType == LinkItemType.todoRoutine) {
        // 루틴 할 일 삭제
        await routineRepo.deleteItem(link.linkedItemId);
      }
    }

    // 연결 정보 삭제
    final linkRepo = ScheduleLinkRepository();
    await linkRepo.init();
    await linkRepo.deleteLinksForSchedule(widget.event.id, widget.event.isRoutine);
  }

  // 일정 수정 함수
  Future<void> _updateSchedule() async {
    final originalTitle = widget.event.title;
    final originalDescription = widget.event.description;
    final originalStartTime = widget.event.startTime ?? const TimeOfDay(hour: 0, minute: 0);
    final originalEndTime = widget.event.endTime ?? const TimeOfDay(hour: 0, minute: 30);
    final originalColor = widget.event.color;

    // 입력 검증
    if (_titleController.text.isEmpty) {
      _showToast('제목을 입력해주세요');
      return;
    }

    // 시간 설정이 켜져있을 때만 시간 검증
    // if (_hasTimeSet && (_startTime.hour > _endTime.hour || (_startTime.hour == _endTime.hour && _startTime.minute >= _endTime.minute))) {
    //   _showToast('종료 시간은 시작 시간보다 나중이어야 합니다');
    //   return;
    // }

    setState(() {
      _isLoading = true;
    });

    try {
      // 연결된 루틴/할일 항목 체크
      // final linkRepo = ScheduleLinkRepository();
      // await linkRepo.init();

      // final linkedItems = linkRepo.getLinksForSchedule(widget.event.id, widget.event.isRoutine);

      // 연결된 항목이 있는지 확인
      // bool hasLinkedItems = linkedItems.isNotEmpty;
      // bool updateLinkedItems = false;

      // 연결된 항목이 있으면 함께 수정할지 확인
      // if (hasLinkedItems) {
      //   updateLinkedItems = await _showUpdateLinkedItemsDialog(linkedItems);
      // }

      // 일정 정보 업데이트
      if (widget.event.isRoutine) {
        // 루틴 일정 수정
        await _updateRoutineSchedule();
      } else {
        // 일반 일정 수정
        await _updateNormalSchedule();
      }

      // 연결된 항목들도 함께 수정
      // if (updateLinkedItems) {
      //   await _updateLinkedItems(linkedItems);
      // }

      // 수정 성공 알림
      _showToast('일정이 수정되었습니다');

      // 콜백 호출하여 메인 화면 업데이트
      widget.onUpdate();

      // 상세 화면 닫기 후 다시 열기 (이렇게 하면 최신 정보로 갱신됨)
      Navigator.of(context).pop();
    } catch (e) {
      _showToast('수정 중 오류가 발생했습니다: $e');

      // 원래 값으로 되돌리기
      _titleController.text = originalTitle;
      _descriptionController.text = originalDescription;
      _startTime = originalStartTime;
      _endTime = originalEndTime;
      _selectedColor = originalColor;

      // 편집 모드 종료 및 로딩 상태 해제
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
      }
    }
  }

  // 연결된 항목들을 수정할지 물어보는 다이얼로그
  Future<bool> _showUpdateLinkedItemsDialog(List<ScheduleLinkItem> linkedItems) async {
    // 연결된 항목 정보 구성
    int todoCount = 0;
    int routineCount = 0;

    for (var link in linkedItems) {
      if (link.linkedItemType == LinkItemType.todo) {
        todoCount++;
      } else if (link.linkedItemType == LinkItemType.todoRoutine) {
        routineCount++;
      }
    }

    // 다이얼로그 메시지 구성
    String message = '이 일정에 연결된 ';

    if (todoCount > 0 && routineCount > 0) {
      message += '할 일 $todoCount개와 루틴 $routineCount개';
    } else if (todoCount > 0) {
      message += '할 일 $todoCount개';
    } else if (routineCount > 0) {
      message += '루틴 $routineCount개';
    }

    message += '의 제목과 색상도 함께 수정하시겠습니까?';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('연결된 항목 수정'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('아니요'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('함께 수정'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // 연결된 항목들 수정
  Future<void> _updateLinkedItems(List<ScheduleLinkItem> linkedItems) async {
    final checkRepo = CheckRepository();
    await checkRepo.init();

    final routineRepo = CheckRoutineRepository();
    await routineRepo.init();

    for (var link in linkedItems) {
      if (link.linkedItemType == LinkItemType.todo) {
        // 할 일 수정
        final item = checkRepo.getItem(link.linkedItemId);
        if (item != null) {
          final updatedItem = CheckItem(
            id: item.id,
            content: _titleController.text, // 제목 동기화
            dueDate: item.dueDate, // 기존 마감일 유지
            startDate: item.startDate, // 기존 시작일 유지
            doneDate: item.doneDate, // 기존 완료일 유지
            colorValue: _selectedColor.value, // 색상 동기화
            check: item.check, // 완료 상태 유지
          );
          await checkRepo.updateItem(updatedItem);
        }
      } else if (link.linkedItemType == LinkItemType.todoRoutine) {
        // 루틴 할 일 수정
        final item = routineRepo.getItem(link.linkedItemId);
        if (item != null) {
          final updatedItem = CheckRoutineItem(
            id: item.id,
            content: _titleController.text, // 제목 동기화
            colorValue: _selectedColor.value, // 색상 동기화
            check: item.check, // 완료 상태 유지
            updated: item.updated, // 업데이트 시간 유지
            daysOfWeek: selectedDays!, // 요일 설정 유지
          );
          await routineRepo.updateItem(updatedItem);
        }
      }
    }
  }

  // 일반 일정 중복 확인
  Future<bool> _checkNormalScheduleConflict(int eventId, DateTime date) async {
    final scheduleRepo = ScheduleRepository();
    await scheduleRepo.init();

    final routineRepo = ScheduleRoutineRepository();
    await routineRepo.init();

    // 1. 해당 날짜의 모든 일정 가져오기 (현재 수정 중인 일정 제외)
    final allDateEvents = scheduleRepo.getDateItems(date);
    final dateEvents = allDateEvents.where((e) => e.id != eventId && e.hasTimeSet);
    // 시간 충돌 확인
    if (_hasTimeConflict(dateEvents)) {
      return true;
    }

    // 2. 해당 날짜의 요일에 해당하는 루틴 일정 확인
    final dayOfWeek = date.weekday % 7; // 0(일)~6(토) 범위로 변환
    final routineEvents = routineRepo.getItemsByDayWithTime(dayOfWeek);

    // 루틴 일정과의 시간 충돌 확인
    return _hasTimeConflict(routineEvents);
  }

  // 루틴 일정 중복 확인
  Future<bool> _checkRoutineScheduleConflict(int eventId, List<bool> daysOfWeek) async {
    final routineRepo = ScheduleRoutineRepository();
    await routineRepo.init();

    final scheduleRepo = ScheduleRepository();
    await scheduleRepo.init();

    // 선택된 각 요일별로 확인
    for (int i = 0; i < daysOfWeek.length; i++) {
      if (!daysOfWeek[i]) continue; // 선택되지 않은 요일은 건너뛰기

      // 1. 해당 요일의 모든 루틴 가져오기 (현재 수정 중인 루틴 제외)
      final allRoutineEvents = routineRepo.getItemsByDayWithTime(i);
      final routineEvents = allRoutineEvents.where((e) => e.id != eventId && e.hasTimeSet);

      // 시간 충돌 확인
      if (_hasTimeConflict(routineEvents)) {
        return true;
      }

      // 2. 해당 요일에 해당하는 일반 일정 확인 (3개월 범위로 검색)
      final today = DateTime.now();
      final threeMonthsLater = today.add(const Duration(days: 90));

      // 오늘부터 3개월 동안의 날짜 중 선택한 요일에 해당하는 날짜들 찾기
      for (DateTime date = today; date.isBefore(threeMonthsLater); date = date.add(const Duration(days: 1))) {
        // 날짜의 요일이 현재 확인 중인 요일과 일치하는지 확인
        if (date.weekday % 7 == i) {
          // 해당 날짜의 일반 일정 가져오기
          final scheduleEvents = scheduleRepo.getTimeItems(date);

          // 시간 충돌 확인
          if (_hasTimeConflict(scheduleEvents)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  // 일반 일정 업데이트
  Future<void> _updateNormalSchedule() async {
    final scheduleRepo = ScheduleRepository();
    await scheduleRepo.init();

    // 기존 일정 가져오기
    ScheduleItem? item = scheduleRepo.getItem(widget.event.id);

    if (item == null) {
      throw Exception('일정을 찾을 수 없습니다');
    }

    // 일정 날짜 가져오기
    final date = DateTime(_date!.year, _date!.month, _date!.day);

    // 시간 설정이 있는 경우에만 중복 체크
    if (_hasTimeSet && await _checkNormalScheduleConflict(widget.event.id, date)) {
      throw Exception('해당 시간에 중복되는 일정이 있습니다');
    }

    // 새 일정 정보로 업데이트
    print('새 일정 정보: ${_titleController.text}, ${_descriptionController.text}, $_startTime, $_endTime, $_selectedColor');
    final updatedItem = ScheduleItem(
      year: _date!.year,
      month: _date!.month,
      date: _date!.day,
      title: _titleController.text,
      description: _descriptionController.text,
      // 시간 설정 여부에 따라 시간 정보 저장 방식 결정
      startHour: _hasTimeSet ? _startTime!.hour : null,
      startMinute: _hasTimeSet ? _startTime!.minute : null,
      endHour: _hasTimeSet ? _endTime!.hour : null,
      endMinute: _hasTimeSet ? _endTime!.minute : null,
      colorValue: _selectedColor.value,
    );

    // ID 설정 (Hive에서 필요)
    updatedItem.id = item.id;

    // 저장
    await scheduleRepo.updateItem(updatedItem);
  }

  // 루틴 일정 업데이트
  Future<void> _updateRoutineSchedule() async {
    final routineRepo = ScheduleRoutineRepository();
    await routineRepo.init();

    // 기존 루틴 가져오기
    ScheduleRoutineItem? item = routineRepo.getItem(widget.event.id);

    if (item == null) {
      throw Exception('루틴을 찾을 수 없습니다');
    }

    // 중복 체크
    if (_hasTimeSet && await _checkRoutineScheduleConflict(widget.event.id, selectedDays!)) {
      throw Exception('선택한 요일에 중복되는 일정이 있습니다');
    }

    // 새 루틴 정보로 업데이트
    final updatedItem = ScheduleRoutineItem(
      title: _titleController.text,
      description: _descriptionController.text,
      daysOfWeek: selectedDays!, // 요일은 변경하지 않음
      startHour: _hasTimeSet ? _startTime!.hour : null,
      startMinute: _hasTimeSet ? _startTime!.minute : null,
      endHour: _hasTimeSet ? _endTime!.hour : null,
      endMinute: _hasTimeSet ? _endTime!.minute : null,
      colorValue: _selectedColor.value,
    );

    // ID 설정 (Hive에서 필요)
    updatedItem.id = item.id;

    // 저장
    await routineRepo.updateItem(updatedItem);
  }

  // 일정 충돌 확인 로직
  bool _hasTimeConflict(Iterable<Event> events) {
    // 시작/종료 시간을 분 단위로 변환
    final newStartMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final newEndMinutes = _endTime!.hour * 60 + _endTime!.minute;

    // 모든 이벤트와 시간 충돌 확인
    for (var event in events) {
      final eventStartMinutes = event.startTime!.hour * 60 + event.startTime!.minute;
      final eventEndMinutes = event.endTime!.hour * 60 + event.endTime!.minute;

      // 충돌 조건:
      // 1. 새 이벤트의 시작이 기존 이벤트 기간 내에 있거나
      // 2. 새 이벤트의 종료가 기존 이벤트 기간 내에 있거나
      // 3. 새 이벤트가 기존 이벤트를 완전히 포함하는 경우
      if ((newStartMinutes >= eventStartMinutes && newStartMinutes < eventEndMinutes) ||
          (newEndMinutes > eventStartMinutes && newEndMinutes <= eventEndMinutes) ||
          (newStartMinutes <= eventStartMinutes && newEndMinutes >= eventEndMinutes)) {
        return true;
      }
    }

    return false;
  }

  // 확인 다이얼로그 표시
  Future<bool> _showConfirmDialog(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('확인'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // 토스트 메시지 표시
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

String _formatTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

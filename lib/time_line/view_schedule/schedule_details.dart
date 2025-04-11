import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:tagiary/constants/colors.dart';
import 'package:tagiary/main.dart';
import 'package:tagiary/tables/data_models/event.dart';
import 'package:tagiary/tables/schedule/schedule_item.dart';
import 'package:tagiary/tables/schedule_routine/schedule_routine_item.dart';
import 'package:tagiary/tables/check/check_item.dart';
import 'package:tagiary/tables/check_routine/check_routine_item.dart';
import 'package:tagiary/tables/schedule_links/schedule_link_item.dart';

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
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late Color _selectedColor;
  bool _hasTimeSet = true; // 시간 설정 여부

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(text: widget.event.description);
    _startTime = widget.event.startTime;
    _endTime = widget.event.endTime;
    _selectedColor = widget.event.color;
    _hasTimeSet = widget.event.hasTimeSet;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
    // 원래 값 저장
    final originalTitle = widget.event.title;
    final originalDescription = widget.event.description;
    final originalStartTime = widget.event.startTime;
    final originalEndTime = widget.event.endTime;
    final originalColor = widget.event.color;

    // 입력 검증
    if (_titleController.text.isEmpty) {
      _showToast('제목을 입력해주세요');
      return;
    }

    // 시간 설정이 켜져있을 때만 시간 검증
    if (_hasTimeSet && (_startTime.hour > _endTime.hour || (_startTime.hour == _endTime.hour && _startTime.minute >= _endTime.minute))) {
      _showToast('종료 시간은 시작 시간보다 나중이어야 합니다');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 연결된 루틴/할일 항목 체크
      final linkRepo = ScheduleLinkRepository();
      await linkRepo.init();
      
      final linkedItems = linkRepo.getLinksForSchedule(
        widget.event.id, 
        widget.event.isRoutine
      );
      
      // 연결된 항목이 있는지 확인
      bool hasLinkedItems = linkedItems.isNotEmpty;
      bool updateLinkedItems = false;
      
      // 연결된 항목이 있으면 함께 수정할지 확인
      if (hasLinkedItems) {
        updateLinkedItems = await _showUpdateLinkedItemsDialog(linkedItems);
      }
      
      // 일정 정보 업데이트
      if (widget.event.isRoutine) {
        // 루틴 일정 수정
        await _updateRoutineSchedule();
      } else {
        // 일반 일정 수정
        await _updateNormalSchedule();
      }
      
      // 연결된 항목들도 함께 수정
      if (updateLinkedItems) {
        await _updateLinkedItems(linkedItems);
      }

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
            content: _titleController.text,  // 제목 동기화
            endDate: item.endDate,  // 기존 마감일 유지
            colorValue: _selectedColor.value,  // 색상 동기화
            check: item.check,  // 완료 상태 유지
          );
          await checkRepo.updateItem(updatedItem);
        }
      } else if (link.linkedItemType == LinkItemType.todoRoutine) {
        // 루틴 할 일 수정
        final item = routineRepo.getItem(link.linkedItemId);
        if (item != null) {
          final updatedItem = CheckRoutineItem(
            id: item.id,
            content: _titleController.text,  // 제목 동기화
            colorValue: _selectedColor.value,  // 색상 동기화
            check: item.check,  // 완료 상태 유지
            updated: item.updated,  // 업데이트 시간 유지
            daysOfWeek: item.daysOfWeek,  // 요일 설정 유지
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
    final dateEvents = allDateEvents.where((e) => e.id != eventId);

    // 시간 충돌 확인
    if (_hasTimeConflict(dateEvents)) {
      return true;
    }

    // 2. 해당 날짜의 요일에 해당하는 루틴 일정 확인
    final dayOfWeek = date.weekday % 7; // 0(일)~6(토) 범위로 변환
    final routineEvents = routineRepo.getItemsByDay(dayOfWeek);

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
      final allRoutineEvents = routineRepo.getItemsByDay(i);
      final routineEvents = allRoutineEvents.where((e) => e.id != eventId);

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
          final scheduleEvents = scheduleRepo.getDateItems(date);

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
    final date = DateTime(item.year, item.month, item.date);

    // 시간 설정이 있는 경우에만 중복 체크
    if (_hasTimeSet && await _checkNormalScheduleConflict(widget.event.id, date)) {
      throw Exception('해당 시간에 중복되는 일정이 있습니다');
    }

    // 새 일정 정보로 업데이트
    final updatedItem = ScheduleItem(
      year: item.year,
      month: item.month,
      date: item.date,
      title: _titleController.text,
      description: _descriptionController.text,
      // 시간 설정 여부에 따라 시간 정보 저장 방식 결정
      startHour: _hasTimeSet ? _startTime.hour : null,
      startMinute: _hasTimeSet ? _startTime.minute : null,
      endHour: _hasTimeSet ? _endTime.hour : null,
      endMinute: _hasTimeSet ? _endTime.minute : null,
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
    if (await _checkRoutineScheduleConflict(widget.event.id, item.daysOfWeek)) {
      throw Exception('선택한 요일에 중복되는 일정이 있습니다');
    }

    // 새 루틴 정보로 업데이트
    final updatedItem = ScheduleRoutineItem(
      title: _titleController.text,
      description: _descriptionController.text,
      daysOfWeek: item.daysOfWeek, // 요일은 변경하지 않음
      startHour: _startTime.hour,
      startMinute: _startTime.minute,
      endHour: _endTime.hour,
      endMinute: _endTime.minute,
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
    final newStartMinutes = _startTime.hour * 60 + _startTime.minute;
    final newEndMinutes = _endTime.hour * 60 + _endTime.minute;

    // 모든 이벤트와 시간 충돌 확인
    for (var event in events) {
      final eventStartMinutes = event.startTime.hour * 60 + event.startTime.minute;
      final eventEndMinutes = event.endTime.hour * 60 + event.endTime.minute;

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

  @override
  Widget build(BuildContext context) {
    final isRoutine = widget.event.isRoutine;
    final typeText = isRoutine ? '루틴 일정' : '일반 일정';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더와 삭제 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? '일정 수정' : '일정 상세',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
                            _startTime = widget.event.startTime;
                            _endTime = widget.event.endTime;
                            _selectedColor = widget.event.color;
                            _isEditing = false;
                          });
                        },
                        color: Colors.grey,
                        tooltip: '편집 취소',
                      ),
                    IconButton(
                      icon: Icon(_isEditing ? Icons.check : Icons.edit),
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_isEditing) {
                                _updateSchedule();
                              } else {
                                setState(() {
                                  _isEditing = true;
                                });
                              }
                            },
                      color: _isEditing ? Colors.green : Colors.blue,
                      tooltip: _isEditing ? '저장' : '수정',
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

            const SizedBox(height: 10),

            // 일정 유형 표시
            Chip(
              label: Text(typeText),
              backgroundColor: isRoutine ? Colors.purple.shade100 : Colors.blue.shade100,
            ),

            const SizedBox(height: 20),

            // 제목
            if (_isEditing)
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '제목',
                  border: OutlineInputBorder(),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '제목',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    widget.event.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // 설명
            if (_isEditing)
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '설명',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 5,
              )
            else if (widget.event.description.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '설명',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    widget.event.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // 시간 정보가 있거나 편집 모드에서 시간 설정이 켜져 있는 경우 표시
            if (widget.event.hasTimeSet || (_isEditing && _hasTimeSet)) ...[
              const Text(
                '시간',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Row(
                children: [
                  if (_isEditing) ...[
                    // 편집 모드일 때 시간 선택기
                    Expanded(
                      child: Row(
                        children: [
                          // 시작 시간
                          SizedBox(
                            width: 50,
                            height: 55,
                            child: CupertinoPicker(
                              itemExtent: 30,
                              scrollController: FixedExtentScrollController(
                                initialItem: _startTime.hour,
                              ),
                              onSelectedItemChanged: (i) => setState(() {
                                _startTime = TimeOfDay(hour: i, minute: _startTime.minute);
                              }),
                              children: List.generate(
                                24,
                                (int i) => Center(
                                  child: Text(
                                    i.toString().padLeft(2, '0'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Text(':'),
                          // 시작 분
                          SizedBox(
                            width: 50,
                            height: 55,
                            child: CupertinoPicker(
                              itemExtent: 30,
                              scrollController: FixedExtentScrollController(
                                initialItem: (_startTime.minute / 5).floor(),
                              ),
                              onSelectedItemChanged: (i) => setState(() {
                                _startTime = TimeOfDay(hour: _startTime.hour, minute: i * 5);
                              }),
                              children: List.generate(
                                12,
                                (int i) => Center(
                                  child: Text(
                                    (i * 5).toString().padLeft(2, '0'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const Text(' ~ '),

                          // 종료 시간
                          SizedBox(
                            width: 50,
                            height: 55,
                            child: CupertinoPicker(
                              itemExtent: 30,
                              scrollController: FixedExtentScrollController(
                                initialItem: _endTime.hour,
                              ),
                              onSelectedItemChanged: (i) => setState(() {
                                _endTime = TimeOfDay(hour: i, minute: _endTime.minute);
                              }),
                              children: List.generate(
                                24,
                                (int i) => Center(
                                  child: Text(
                                    i.toString().padLeft(2, '0'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Text(':'),
                          // 종료 분
                          SizedBox(
                            width: 50,
                            height: 55,
                            child: CupertinoPicker(
                              itemExtent: 30,
                              scrollController: FixedExtentScrollController(
                                initialItem: (_endTime.minute / 5).floor(),
                              ),
                              onSelectedItemChanged: (i) => setState(() {
                                _endTime = TimeOfDay(hour: _endTime.hour, minute: i * 5);
                              }),
                              children: List.generate(
                                12,
                                (int i) => Center(
                                  child: Text(
                                    (i * 5).toString().padLeft(2, '0'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    // 읽기 모드일 때 시간 표시
                    Text(
                      '${_formatTime(_startTime)} ~ ${_formatTime(_endTime)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],

            if (_isEditing) ...[
              const SizedBox(height: 20),

              // 일정만 시간 설정 체크박스 추가 (루틴은 항상 시간이 있어야 함)
              if (!widget.event.isRoutine)
                Row(
                  children: [
                    const Text(
                      '시간 설정',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Checkbox(
                      value: _hasTimeSet,
                      activeColor: Colors.indigo,
                      shape: const CircleBorder(),
                      onChanged: (value) {
                        setState(() {
                          _hasTimeSet = value!;
                          // 시간 설정 활성화 시 기본 시간 설정
                          if (_hasTimeSet) {
                            _startTime = const TimeOfDay(hour: 9, minute: 0);
                            _endTime = const TimeOfDay(hour: 10, minute: 0);
                          }
                        });
                      },
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // 색상 선택
              const Text(
                '색상',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (Color color in scheduleColors)
                    GestureDetector(
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
                          border: _selectedColor.value == color.value ? Border.all(color: Colors.black, width: 2) : null,
                        ),
                      ),
                    ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // 로딩 표시
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

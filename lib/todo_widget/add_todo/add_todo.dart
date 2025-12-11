import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mrplando/constants/colors.dart';
import 'package:mrplando/tables/check/check_enum.dart';
import 'package:mrplando/tables/check/check_item.dart';
import 'package:mrplando/tables/schedule/schedule_item.dart';
import 'package:mrplando/tables/schedule_links/schedule_link_item.dart';
import 'package:mrplando/screens/color_management_page.dart';

class AddTodo extends StatefulWidget {
  final VoidCallback? onTodoAdded; // 할 일 추가 후 호출할 콜백 함수
  final CheckItem? todoToEdit; // 수정할 할 일 (없으면 새로 추가)

  const AddTodo({super.key, this.onTodoAdded, this.todoToEdit});

  @override
  State<AddTodo> createState() => _AddTodoState();
}

class _AddTodoState extends State<AddTodo> {
  String content = '';
  late TextEditingController contentCont;

  // FocusNode 추가
  final FocusNode contentFocus = FocusNode();

  // 마감일 설정
  DateTime? selectedDate;

  // 색상 선택
  late Color selectedColor;
  bool isLoading = false;
  double colorPadding = 20;
  double colorSize = 35;

  @override
  void initState() {
    super.initState();

    // 수정 모드인 경우 기존 데이터로 초기화
    if (widget.todoToEdit != null) {
      content = widget.todoToEdit!.content;
      selectedDate = widget.todoToEdit!.dueDate != null ? DateTime.parse(widget.todoToEdit!.dueDate!) : null;
      selectedColor = Color(widget.todoToEdit!.colorValue);
    } else {
      selectedColor = scheduleColors[0];
    }

    contentCont = TextEditingController(text: content);
  }

  @override
  void dispose() {
    contentFocus.dispose();
    contentCont.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 빈 영역 터치 시 키보드 숨기기
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // 할 일 제목 입력
                  TextFormField(
                    onChanged: (value) {
                      content = value;
                    },
                    controller: contentCont,
                    focusNode: contentFocus,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onEditingComplete: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    decoration: const InputDecoration(
                      hintText: '할 일',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    style: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w700),
                  ),

                  Divider(height: 20, thickness: 1, color: Colors.grey.shade300),

                  // 마감일 선택
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('마감일', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate ?? DateTime.now(),
                                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                  );

                                  if (date != null) {
                                    setState(() {
                                      selectedDate = date;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        selectedDate != null ? '${selectedDate!.year}년 ${selectedDate!.month}월 ${selectedDate!.day}일' : '마감일 선택 (선택사항)',
                                        style: TextStyle(color: selectedDate != null ? Colors.black : Colors.grey, fontSize: 14),
                                      ),
                                      Icon(Icons.calendar_today, size: 16, color: selectedDate != null ? Colors.black : Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (selectedDate != null)
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () {
                                  setState(() {
                                    selectedDate = null;
                                  });
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 색상 선택
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('색상', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: colorPadding),
                          child: Wrap(
                            spacing: (MediaQuery.of(context).size.width - (colorPadding * 4 + colorSize * 6)) / 5,
                            runSpacing: 12,
                            children: [
                              ...scheduleColors.map((color) {
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
                                      border: selectedColor.value == color.value ? Border.all(color: Colors.black, width: 2) : null,
                                    ),
                                  ),
                                );
                              }),
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.push(context, MaterialPageRoute(builder: (context) => const ColorManagementPage()));
                                  setState(() {});
                                },
                                child: Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
                                  child: const Icon(Icons.add, color: Colors.grey, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 우측 상단에 저장 버튼 (초록색 체크 아이콘)
              Positioned(
                top: 0,
                right: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.green)),
                      )
                    else
                      IconButton(
                        onPressed: _saveTodo,
                        icon: const Icon(Icons.check, color: Colors.green, size: 32),
                      ),
                    // 수정 모드일 때만 삭제 버튼 표시
                    if (widget.todoToEdit != null && !isLoading)
                      IconButton(
                        onPressed: () => _deleteTodo(widget.todoToEdit!),
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveTodo() async {
    // 입력 검증
    if (content.isEmpty) {
      _showToast('제목을 입력해주세요');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // 할 일 저장 로직
      final repository = CheckRepository();
      await repository.init();

      int todoId;

      if (widget.todoToEdit != null) {
        // 수정 모드 - 기존 완료 상태 유지
        final updatedTodo = CheckItem(
          id: widget.todoToEdit!.id,
          content: content,
          dueDate: selectedDate?.toIso8601String(),
          startDate: widget.todoToEdit!.startDate, // 기존 시작일 그대로 유지
          doneDate: widget.todoToEdit!.doneDate, // 기존 완료일 그대로 유지
          colorValue: selectedColor.value,
          check: widget.todoToEdit!.check, // 기존 완료 상태 그대로 유지
        );

        await repository.updateItem(updatedTodo);
        todoId = widget.todoToEdit!.id;
      } else {
        // 새로 추가 - 완료 상태는 항상 false로 설정
        final newTodo = CheckItem(
          id: 0, // 저장소에서 ID 할당
          content: content,
          dueDate: selectedDate?.toIso8601String(),
          startDate: null, // 시작일은 현재 시간으로 설정
          doneDate: null, // 신규 추가 시 완료일은 null로 설정
          colorValue: selectedColor.value,
          check: CheckEnum.pending, // 신규 추가 시 항상 false로 설정
        );

        todoId = await repository.addItem(newTodo);
      }

      // 마감일이 설정된 경우 스케줄에도 추가할지 확인
      if (selectedDate != null && widget.todoToEdit == null) {
        final addToSchedule = await _showAddToScheduleDialog();
        if (addToSchedule) {
          await _addToSchedule(todoId);
        }
      }

      // 저장 성공 시 콜백 함수 호출
      if (widget.onTodoAdded != null) {
        widget.onTodoAdded!();
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

  // 스케줄에도 추가할지 묻는 다이얼로그
  Future<bool> _showAddToScheduleDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정에 추가'),
        content: const Text('이 할 일을 스케줄에도 추가하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('아니요')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('추가하기')),
        ],
      ),
    );
    return result ?? false;
  }

  // 스케줄에 추가하는 메서드 (시간 설정 없이)
  Future<void> _addToSchedule(int todoId) async {
    final scheduleRepository = ScheduleRepository();
    await scheduleRepository.init();

    // 시간 설정 없이 일정 추가
    final newSchedule = ScheduleItem(
      year: selectedDate!.year,
      month: selectedDate!.month,
      date: selectedDate!.day,
      title: content,
      description: '',
      startHour: null, // 시간 정보 null로 설정
      startMinute: null,
      endHour: null,
      endMinute: null,
      colorValue: selectedColor.value,
    );

    final scheduleId = await scheduleRepository.addItem(newSchedule);

    // 일정과 할 일 사이의 연결 정보 저장
    final linkRepo = ScheduleLinkRepository();
    await linkRepo.init();

    final newLink = ScheduleLinkItem(scheduleId: scheduleId, isRoutine: false, linkedItemId: todoId, linkedItemType: LinkItemType.todo);

    await linkRepo.addItem(newLink);
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  void _deleteTodo(CheckItem todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('할 일 삭제'),
        content: const Text('이 할 일을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              final repository = CheckRepository();
              await repository.init();
              repository.deleteItem(todo.id);
              Navigator.pop(context); // 다이얼로그 닫기
              Navigator.pop(context); // AddTodo 화면 닫기
              if (widget.onTodoAdded != null) {
                widget.onTodoAdded!(); // 화면 갱신
              }
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

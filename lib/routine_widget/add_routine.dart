import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:mrplando/component/day_picker/day_picker.dart';
import 'package:mrplando/constants/colors.dart';
import 'package:mrplando/screens/home_screen.dart';
import 'package:mrplando/tables/check_routine/check_routine_item.dart';
import 'package:mrplando/schedule/add_schedule.dart';

class AddRoutine extends StatefulWidget {
  final VoidCallback? onRoutineAdded; // 루틴 추가 후 호출할 콜백 함수
  DateTime selectedDate;
  TimeOfDay start;
  TimeOfDay end;

  AddRoutine({
    super.key,
    this.onRoutineAdded,
    required this.selectedDate,
    required this.start,
    required this.end,
  });

  @override
  State<AddRoutine> createState() => _AddRoutineState();
}

class _AddRoutineState extends State<AddRoutine> {
  String content = '';
  late TextEditingController contentCont;

  // FocusNode 추가
  final FocusNode contentFocus = FocusNode();

  // bool hasTimeSet = false; // 시간 설정 여부 체크박스

  // 시작 날짜
  late DateTime startDate;

  // 종료 날짜 (null이면 무기한)
  DateTime? endDate;

  // 요일 선택 상태
  List<bool> selectedDays = List.generate(7, (index) => false);

  // 시간 선택
  late TimeOfDay start;
  late TimeOfDay end;

  // 색상 선택
  late Color selectedColor;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    contentCont = TextEditingController();
    startDate = widget.selectedDate;
    selectedColor = scheduleColors[0];
    start = widget.start;
    end = widget.end;
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
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // 루틴 제목 입력
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
                    hintText: '루틴',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
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

                Divider(
                  height: 20,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.end,
                //   children: [
                //     const Text(
                //       '시간 설정',
                //       style: TextStyle(
                //         fontSize: 16,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //     Checkbox(
                //       value: hasTimeSet,
                //       activeColor: Colors.indigo,
                //       shape: const CircleBorder(),
                //       onChanged: (value) {
                //         setState(() {
                //           hasTimeSet = value!;
                //         });
                //       },
                //     ),
                //   ],
                // ),
                // 시작 날짜와 종료 날짜를 나란히 배치
                Row(
                  children: [
                    // 시작 날짜
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '시작일',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0x1140608A),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () async {
                              final selectedDate = await showBlackWhiteDatePicker(
                                context: context,
                                initialDate: startDate,
                              );
                              if (selectedDate != null) {
                                setState(() {
                                  startDate = selectedDate;
                                  // 종료일이 시작일보다 이전이면 null로 리셋
                                  if (endDate != null && endDate!.isBefore(selectedDate)) {
                                    endDate = null;
                                  }
                                });
                              }
                            },
                            child: Text(
                              formatDate(startDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Color(0xFF40608A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 종료 날짜
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '종료일',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: endDate != null ? const Color(0x1140608A) : Colors.grey.shade200,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () async {
                              final selectedDate = await showBlackWhiteDatePicker(
                                context: context,
                                initialDate: endDate ?? startDate,
                              );
                              if (selectedDate != null) {
                                // 종료일이 시작일보다 이전이면 설정 불가
                                if (selectedDate.isBefore(startDate)) {
                                  _showToast('종료일은 시작일 이후여야 합니다');
                                } else {
                                  setState(() {
                                    endDate = selectedDate;
                                  });
                                }
                              }
                            },
                            onLongPress: () {
                              // 길게 누르면 종료일 제거 (무기한)
                              setState(() {
                                endDate = null;
                              });
                              _showToast('종료일을 제거했습니다 (무기한)');
                            },
                            child: Text(
                              endDate != null ? formatDate(endDate!) : '무기한',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: endDate != null ? const Color(0xFF40608A) : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // 요일 선택
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: DayPicker(
                    selectedDays: selectedDays,
                    onDaysChanged: (days) {
                      setState(() {
                        selectedDays = days;
                      });
                    },
                  ),
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

            // 우측 상단에 저장 버튼 (초록색 체크 아이콘)
            Positioned(
              top: 0,
              right: 0,
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
                      onPressed: _saveRoutine,
                      icon: const Icon(
                        Icons.check,
                        color: Colors.green,
                        size: 32,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRoutine() async {
    // 입력 검증
    if (content.isEmpty) {
      _showToast('제목을 입력해주세요');
      return;
    }

    if (!selectedDays.contains(true)) {
      _showToast('반복할 요일을 최소 하나 이상 선택해주세요');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // 저장 로직
      await _saveRoutineItem();

      // 저장 성공 시 콜백 함수 호출
      if (widget.onRoutineAdded != null) {
        widget.onRoutineAdded!();
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

  Future<void> _saveRoutineItem() async {
    final routineRepository = CheckRoutineRepository();
    await routineRepository.init();

    final newRoutine = CheckRoutineItem(
      id: 0, // 저장소에서 ID 할당
      content: content,
      startDate: startDate,
      colorValue: selectedColor.value,
      check: false,
      updated: DateTime.now(),
      daysOfWeek: selectedDays,
      endDate: endDate, // 종료일 추가 (null 가능)
    );

    await routineRepository.addItem(newRoutine);
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
}

String _formatEachTime(int time) {
  return time.toString().padLeft(2, '0');
}

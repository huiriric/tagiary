import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tagiary/component/day_picker/day_picker.dart';
import 'package:tagiary/constants/colors.dart';
import 'package:tagiary/tables/check_routine/check_routine_item.dart';
import 'package:tagiary/tables/check_routine/routine_history.dart';

class RoutineDetail extends StatefulWidget {
  CheckRoutineItem item;
  VoidCallback? onUpdated; // 루틴 업데이트 후 호출할 콜백 함수
  RoutineDetail({super.key, required this.item, this.onUpdated});

  @override
  State<RoutineDetail> createState() => _RoutineDetailState();
}

class _RoutineDetailState extends State<RoutineDetail> {
  bool _isEditing = false;
  bool _isLoading = false;
  late String _content;
  late int _colorValue;
  late List<bool> _daysOfWeek;
  late TextEditingController _contentController;
  late FocusNode _contentFocusNode;
  Key _dayPickerKey = UniqueKey(); // DayPicker의 상태를 유지하기 위한 키

  @override
  void initState() {
    super.initState();
    _content = widget.item.content;
    _colorValue = widget.item.colorValue;
    _daysOfWeek = widget.item.daysOfWeek;
    _contentController = TextEditingController(text: _content);
    _contentFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _contentFocusNode.dispose();
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
              mainAxisSize: MainAxisSize.min,
              children: [
                // 루틴 제목 입력
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextFormField(
                        onChanged: (value) {
                          setState(() {
                            _content = _contentController.text = value;
                          });
                        },
                        controller: _contentController,
                        focusNode: _contentFocusNode,
                        // autofocus: true,
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
                    ),
                    Row(
                      children: [
                        // 편집 모드일 때만 보이는 아이콘
                        if (_isEditing)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _contentFocusNode.unfocus(); // 포커스 해제
                                _content = _contentController.text = widget.item.content; // 원래 내용으로 되돌리기
                                _colorValue = widget.item.colorValue; // 원래 색상으로 되돌리기
                                _daysOfWeek = widget.item.daysOfWeek; // 원래 요일로 되돌리기
                                _isEditing = false;
                                _dayPickerKey = UniqueKey(); // DayPicker 상태 초기화
                              });
                            },
                            color: Colors.grey,
                            tooltip: '편집 취소',
                          ),
                        if (_isEditing)
                          IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () async {
                              _isLoading ? null : await _editRoutine(widget.onUpdated ?? () {});
                              if (mounted) {
                                setState(() {
                                  _isEditing = false;
                                  _isLoading = false;
                                  _dayPickerKey = UniqueKey(); // DayPicker 상태 초기화
                                });
                              }
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
                                    _deleteRoutine(widget.item, onRoutineChanged: widget.onUpdated);
                                  }
                                },
                          color: Colors.red,
                          tooltip: '삭제',
                        ),
                      ],
                    )
                  ],
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
                // 요일 선택기
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: DayPicker(
                    key: _dayPickerKey,
                    selectedDays: _daysOfWeek,
                    onDaysChanged: (days) {
                      setState(() {
                        _daysOfWeek = days;
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
                                    _colorValue = color.value;
                                  });
                                },
                                child: Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: _colorValue == color.value ? Border.all(color: Colors.black, width: 2) : null,
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
                                    _colorValue = color.value;
                                  });
                                },
                                child: Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: _colorValue == color.value ? Border.all(color: Colors.black, width: 2) : null,
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
            // Positioned(
            //   top: 0,
            //   right: 0,
            //   child: _isLoading
            //       ? const SizedBox(
            //           width: 24,
            //           height: 24,
            //           child: CircularProgressIndicator(
            //             strokeWidth: 2,
            //             valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            //           ),
            //         )
            //       : IconButton(
            //           onPressed: () => _editRoutine(widget.onUpdated),
            //           icon: const Icon(
            //             Icons.check,
            //             color: Colors.green,
            //             size: 32,
            //           ),
            //         ),
            // ),
          ],
        ),
      ),
    );
  }

  bool detectDiff() {
    final isContentChanged = _content != widget.item.content;
    final isColorChanged = _colorValue != widget.item.colorValue;
    final isDaysOfWeekChanged = _daysOfWeek != widget.item.daysOfWeek;
    return isContentChanged || isColorChanged || isDaysOfWeekChanged;
  }

  Future<void> _editRoutine(VoidCallback? onRoutineEdited) async {
    if (_content.isEmpty) {
      _showToast('제목을 입력해주세요');
      return;
    }

    if (!_daysOfWeek.contains(true)) {
      _showToast('반복할 요일을 최소 하나 이상 선택해주세요');
      return;
    }

    CheckRoutineRepository routineRepository = CheckRoutineRepository();
    await routineRepository.init();

    setState(() {
      _isLoading = true;
    });

    try {
      // 데이터베이스 업데이트 로직
      // widget.item.content = _content;
      // widget.item.colorValue = _colorValue;
      // widget.item.daysOfWeek = _daysOfWeek;
      CheckRoutineItem itemToUpdate = CheckRoutineItem(
        id: widget.item.id,
        content: _content,
        startDate: widget.item.startDate,
        colorValue: _colorValue,
        check: widget.item.check,
        updated: widget.item.updated,
        daysOfWeek: _daysOfWeek,
      );

      // 예시: 데이터베이스에 저장하는 코드
      await routineRepository.updateItem(itemToUpdate);
      onRoutineEdited?.call(); // 루틴이 수정되었음을 알리는 콜백 호출
      _showToast('루틴이 수정되었습니다');
      Navigator.pop(context); // 루틴 상세 페이지 닫기
    } catch (e) {
      _showToast('루틴이 수정되었습니다');
    } finally {
      setState(() {
        _isLoading = false;
        _isEditing = false;
      });
    }
  }

  void _deleteRoutine(CheckRoutineItem routine, {VoidCallback? onRoutineChanged}) {
    CheckRoutineRepository repository = CheckRoutineRepository();
    RoutineHistoryRepository historyRepository = RoutineHistoryRepository();
    repository.init();
    historyRepository.init();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('루틴 삭제'),
        content: const Text('이 루틴을 삭제하시겠습니까?\n(모든 기록도 함께 삭제됩니다)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              // 루틴 삭제
              await repository.deleteItem(routine.id);
              // 해당 루틴의 모든 기록 삭제
              await historyRepository.deleteHistoryForRoutine(routine.id);
              onRoutineChanged!(); // 루틴 변경 콜백 호출
              Navigator.pop(context);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

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

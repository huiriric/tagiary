import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tagiary/tables/check_routine/check_routine_item.dart';
import 'package:tagiary/tables/check_routine/routine_history.dart';
import 'package:tagiary/todo_routine_widget/routine_history_view.dart';

class TodoRoutineWidget extends StatefulWidget {
  const TodoRoutineWidget({super.key});

  @override
  State<TodoRoutineWidget> createState() => _TodoRoutineWidgetState();
}

class _TodoRoutineWidgetState extends State<TodoRoutineWidget> {
  late CheckRoutineRepository _repository;
  late RoutineHistoryRepository _historyRepository;

  @override
  void initState() {
    super.initState();
    _repository = CheckRoutineRepository();
    _historyRepository = RoutineHistoryRepository();
    _initRepositories();
  }

  Future<void> _initRepositories() async {
    await _repository.init();
    await _historyRepository.init();
    // 새로운 날짜가 시작될 때 루틴 초기화
    _repository.initializeRoutine();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<CheckRoutineItem>('checkRoutineBox').listenable(),
      builder: (context, Box<CheckRoutineItem> box, _) {
        final routines = box.values.toList();

        return _buildRoutineWidget(routines);
      },
    );
  }

  Widget _buildRoutineWidget(List<CheckRoutineItem> routines) {
    return GestureDetector(
      onTap: routines.isEmpty
          ? () {
              _showAddRoutineDialog(context);
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: GestureDetector(
                  onTap: () => _showAddRoutineDialog(context),
                  child: const Icon(
                    Icons.add,
                    size: 20,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            if (routines.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    '루틴을 추가하세요',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                  itemCount: routines.length,
                  itemBuilder: (context, index) {
                    final routine = routines[index];

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                      title: Text(
                        routine.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          decoration: routine.check ? TextDecoration.lineThrough : null,
                          color: routine.check ? Colors.grey : Colors.black,
                          fontSize: 13,
                        ),
                      ),
                      leading: Checkbox(
                        value: routine.check,
                        onChanged: (value) {
                          _updateRoutineCheck(routine, value!);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        activeColor: Color(routine.colorValue),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () {
                          _deleteRoutine(routine);
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RoutineHistoryView(routine: routine),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _updateRoutineCheck(CheckRoutineItem routine, bool value) {
    // 단순 체크 업데이트 대신 기록 추가 메소드 사용
    _checkRoutine(routine, value);
  }

  Future<void> _checkRoutine(CheckRoutineItem routine, bool checked) async {
    // 루틴 체크 상태 업데이트
    final updatedRoutine = CheckRoutineItem(
      id: routine.id,
      content: routine.content,
      colorValue: routine.colorValue,
      check: checked,
      updated: DateTime.now(), // 타임스탬프 업데이트
    );

    await _repository.updateItem(updatedRoutine);

    // 체크 시에만 (언체크가 아닐 때) 기록에 추가
    if (checked) {
      final history = RoutineHistory(
        id: 0, // 저장소에서 ID 할당
        routineId: routine.id,
        completedDate: DateTime.now(),
      );
      await _historyRepository.addItem(history);
    }
  }

  void _deleteRoutine(CheckRoutineItem routine) {
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
              await _repository.deleteItem(routine.id);
              // 해당 루틴의 모든 기록 삭제
              await _historyRepository.deleteHistoryForRoutine(routine.id);
              Navigator.pop(context);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showAddRoutineDialog(BuildContext context) {
    final TextEditingController contentController = TextEditingController();
    int selectedColor = Colors.blue.value;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('루틴 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              controller: contentController,
              decoration: const InputDecoration(
                labelText: '루틴 내용',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // 간단한 색상 선택기
            Wrap(
              spacing: 8,
              children: [
                Colors.blue,
                Colors.red,
                Colors.green,
                Colors.orange,
                Colors.purple,
                Colors.teal,
              ].map((color) {
                return GestureDetector(
                  onTap: () {
                    selectedColor = color.value;
                    // 리빌드 트리거
                    (context as Element).markNeedsBuild();
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.value == selectedColor ? Colors.black : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (contentController.text.isNotEmpty) {
                final newRoutine = CheckRoutineItem(
                  id: 0, // 저장소에서 ID 할당
                  content: contentController.text,
                  colorValue: selectedColor,
                  check: false,
                  updated: DateTime.now(),
                );

                _repository.addItem(newRoutine);
                Navigator.pop(context);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
}

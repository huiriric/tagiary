import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tagiary/constants/colors.dart';
import 'package:tagiary/tables/check/check_item.dart';

class TodoWidget extends StatefulWidget {
  const TodoWidget({super.key});

  @override
  State<TodoWidget> createState() => _TodoWidgetState();
}

class _TodoWidgetState extends State<TodoWidget> {
  late CheckRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = CheckRepository();
    _repository.init();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<CheckItem>('checkBox').listenable(),
      builder: (context, Box<CheckItem> box, _) {
        final todos = box.values.toList();

        return _buildTodoWidget(todos);
      },
    );
  }

  Widget _buildTodoWidget(List<CheckItem> todos) {
    final uncheckedCount = todos.where((todo) => !todo.check).length;

    return GestureDetector(
      onTap: todos.isEmpty ? () => _showAddTodoDialog(context) : () => _showTodoListDialog(context),
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
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 16, right: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 왼쪽에 제목 추가
                  const Text(
                    '할 일',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // 오른쪽에 카운터와 추가 버튼
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$uncheckedCount개',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showAddTodoDialog(context),
                        child: const Icon(
                          Icons.add,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (todos.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    '할 일을 추가하세요',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: _buildTodoPreview(todos),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoPreview(List<CheckItem> todos) {
    // Sort unchecked tasks by end date (nearest first)
    final uncheckedTodos = todos.where((todo) => !todo.check).toList()
      ..sort((a, b) {
        if (a.endDate == null && b.endDate == null) {
          return b.id.compareTo(a.id); // Newer tasks first if no end date
        } else if (a.endDate == null) {
          return 1; // b comes first
        } else if (b.endDate == null) {
          return -1; // a comes first
        } else {
          return a.endDate!.compareTo(b.endDate!);
        }
      });

    // Show at most 3 items in preview
    final previewTodos = uncheckedTodos;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      itemCount: previewTodos.length,
      itemBuilder: (context, index) {
        final todo = previewTodos[index];

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          dense: true,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          title: Text(
            todo.content,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
          leading: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Color(todo.colorValue),
              shape: BoxShape.circle,
            ),
          ),
          trailing: todo.endDate != null ? _buildDDay(todo.endDate!) : null,
        );
      },
    );
  }

  Widget _buildDDay(String dateStr) {
    final endDate = DateTime.parse(dateStr);
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final difference = endDate.difference(today).inDays;

    String text;
    Color color;

    if (difference < 0) {
      text = 'D+${-difference}';
      color = Colors.red;
    } else if (difference == 0) {
      text = 'D-Day';
      color = Colors.red;
    } else {
      text = 'D-$difference';
      color = difference <= 3 ? Colors.red : Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showTodoListDialog(BuildContext context, [bool showAddButton = false]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('할 일 목록'),
        content: SizedBox(
          width: double.maxFinite,
          child: ValueListenableBuilder(
            valueListenable: Hive.box<CheckItem>('checkBox').listenable(),
            builder: (context, Box<CheckItem> box, _) {
              final todos = box.values.toList();

              // Get unchecked items sorted by end date (closest first)
              final uncheckedTodos = todos.where((todo) => !todo.check).toList()
                ..sort((a, b) {
                  if (a.endDate == null && b.endDate == null) {
                    return b.id.compareTo(a.id); // Newer tasks first if no end date
                  } else if (a.endDate == null) {
                    return 1; // b comes first
                  } else if (b.endDate == null) {
                    return -1; // a comes first
                  } else {
                    return a.endDate!.compareTo(b.endDate!);
                  }
                });

              // Get checked items sorted by updated (most recent first)
              final checkedTodos = todos.where((todo) => todo.check).toList()..sort((a, b) => b.id.compareTo(a.id)); // Using id as proxy for update time

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (uncheckedTodos.isNotEmpty) ...[
                      const Text(
                        '미완료',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...uncheckedTodos.map((todo) => _buildTodoItem(todo)),
                      const SizedBox(height: 16),
                    ],
                    if (checkedTodos.isNotEmpty) ...[
                      const Text(
                        '완료',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...checkedTodos.map((todo) => _buildTodoItem(todo)),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          if (showAddButton)
            TextButton(
              onPressed: () {
                _showAddTodoDialog(context);
              },
              child: const Text('추가'),
            ),
        ],
      ),
    );
  }

  Widget _buildTodoItem(CheckItem todo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Checkbox(
            value: todo.check,
            onChanged: (value) {
              _updateTodoCheck(todo, value!);
              // Don't close dialog so user can toggle multiple items
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            activeColor: Color(todo.colorValue),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.content,
                  style: TextStyle(
                    decoration: todo.check ? TextDecoration.lineThrough : null,
                    color: todo.check ? Colors.grey : Colors.black,
                    fontSize: 14,
                  ),
                ),
                if (todo.endDate != null) _buildDDay(todo.endDate!),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () {
              Navigator.pop(context); // Close current dialog
              _showEditTodoDialog(context, todo);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () {
              _deleteTodo(todo);
            },
          ),
        ],
      ),
    );
  }

  void _updateTodoCheck(CheckItem todo, bool value) {
    final updatedTodo = CheckItem(
      id: todo.id,
      content: todo.content,
      endDate: todo.endDate,
      colorValue: todo.colorValue,
      check: value,
    );

    _repository.updateItem(updatedTodo);
  }

  void _deleteTodo(CheckItem todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('할 일 삭제'),
        content: const Text('이 할 일을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              _repository.deleteItem(todo.id);
              Navigator.pop(context);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context) {
    final TextEditingController contentController = TextEditingController();
    DateTime? selectedDate;
    int selectedColor = Colors.blue.value;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('할 일 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              controller: contentController,
              decoration: const InputDecoration(
                labelText: '할 일 내용',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
                        firstDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );

                      if (date != null) {
                        selectedDate = date;
                        // Trigger rebuild
                        (context as Element).markNeedsBuild();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDate != null ? '${selectedDate!.year}-${selectedDate!.month}-${selectedDate!.day}' : '마감일 선택 (선택사항)',
                            style: TextStyle(
                              color: selectedDate != null ? Colors.black : Colors.grey,
                            ),
                          ),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                if (selectedDate != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      selectedDate = null;
                      // Trigger rebuild
                      (context as Element).markNeedsBuild();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Simple color picker row - 6개씩 두 줄로 표시
            Column(
              children: [
                // 첫 번째 줄 (색상 0-5)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    final color = scheduleColors[index];
                    return GestureDetector(
                      onTap: () {
                        selectedColor = color.value;
                        // Trigger rebuild
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
                  }),
                ),
                const SizedBox(height: 8),
                // 두 번째 줄 (색상 6-11)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    final color = scheduleColors[index + 6];
                    return GestureDetector(
                      onTap: () {
                        selectedColor = color.value;
                        // Trigger rebuild
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
                  }),
                ),
              ],
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
                final newTodo = CheckItem(
                  id: 0, // Repository will assign ID
                  content: contentController.text,
                  endDate: selectedDate?.toIso8601String(),
                  colorValue: selectedColor,
                  check: false,
                );

                _repository.addItem(newTodo);
                Navigator.pop(context);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _showEditTodoDialog(BuildContext context, CheckItem todo) {
    final TextEditingController contentController = TextEditingController(text: todo.content);
    DateTime? selectedDate = todo.endDate != null ? DateTime.parse(todo.endDate!) : null;
    int selectedColor = todo.colorValue;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('할 일 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: '할 일 내용',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );

                      if (date != null) {
                        selectedDate = date;
                        // Trigger rebuild
                        (context as Element).markNeedsBuild();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDate != null ? '${selectedDate!.year}-${selectedDate!.month}-${selectedDate!.day}' : '마감일 선택 (선택사항)',
                            style: TextStyle(
                              color: selectedDate != null ? Colors.black : Colors.grey,
                            ),
                          ),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                if (selectedDate != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      selectedDate = null;
                      // Trigger rebuild
                      (context as Element).markNeedsBuild();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Simple color picker row - 6개씩 두 줄로 표시
            Column(
              children: [
                // 첫 번째 줄 (색상 0-5)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    final color = scheduleColors[index];
                    return GestureDetector(
                      onTap: () {
                        selectedColor = color.value;
                        // Trigger rebuild
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
                  }),
                ),
                const SizedBox(height: 8),
                // 두 번째 줄 (색상 6-11)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    final color = scheduleColors[index + 6];
                    return GestureDetector(
                      onTap: () {
                        selectedColor = color.value;
                        // Trigger rebuild
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
                  }),
                ),
              ],
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
                final updatedTodo = CheckItem(
                  id: todo.id,
                  content: contentController.text,
                  endDate: selectedDate?.toIso8601String(),
                  colorValue: selectedColor,
                  check: todo.check,
                );

                _repository.updateItem(updatedTodo);
                Navigator.pop(context);
              }
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }
}

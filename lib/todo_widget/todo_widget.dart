import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tagiary/component/slide_up_container.dart';
import 'package:tagiary/constants/colors.dart';
import 'package:tagiary/tables/check/check_item.dart';
import 'package:tagiary/todo_widget/add_todo/add_todo.dart';

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
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 1,
        color: Colors.white,
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
            shape: const CircleBorder(),
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
    // SlideUpContainer를 사용하여 루틴 추가와 유사한 UI로 변경
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
            child: AddTodo(
              onTodoAdded: () {
                // 할 일 목록 새로고침
                setState(() {});
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showEditTodoDialog(BuildContext context, CheckItem todo) {
    // SlideUpContainer를 사용하여 루틴 추가와 유사한 UI로 변경
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
            child: AddTodo(
              todoToEdit: todo,
              onTodoAdded: () {
                // 할 일 목록 새로고침
                setState(() {});
              },
            ),
          ),
        ),
      ),
    );
  }
}

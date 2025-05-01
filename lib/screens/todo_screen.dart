import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tagiary/component/slide_up_container.dart';
import 'package:tagiary/tables/check/check_item.dart';
import 'package:tagiary/todo_widget/add_todo/add_todo.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({Key? key}) : super(key: key);

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  late CheckRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = CheckRepository();
    _repository.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '할 일',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Color(0xBB000000)),
        onPressed: () => _showAddTodoDialog(context),
      ),
      body: ValueListenableBuilder(
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
          final checkedTodos = todos.where((todo) => todo.check).toList()
            ..sort((a, b) => b.id.compareTo(a.id)); // Using id as proxy for update time

          if (todos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_box_outline_blank,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '할 일을 추가해보세요',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (uncheckedTodos.isNotEmpty) ...[
                    const Text(
                      '진행 중',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...uncheckedTodos.map((todo) => _buildTodoItem(todo)),
                    const SizedBox(height: 24),
                  ],
                  if (checkedTodos.isNotEmpty) ...[
                    const Text(
                      '완료',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...checkedTodos.map((todo) => _buildTodoItem(todo)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTodoItem(CheckItem todo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            Checkbox(
              value: todo.check,
              onChanged: (value) {
                _updateTodoCheck(todo, value!);
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
                      fontSize: 16,
                    ),
                  ),
                  if (todo.endDate != null) _buildDDay(todo.endDate!),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                _showEditTodoDialog(context, todo);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                _deleteTodo(todo);
              },
            ),
          ],
        ),
      ),
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
      margin: const EdgeInsets.only(top: 4),
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
                setState(() {});
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showEditTodoDialog(BuildContext context, CheckItem todo) {
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
                setState(() {});
              },
            ),
          ),
        ),
      ),
    );
  }
}
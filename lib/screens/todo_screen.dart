import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tagiary/component/slide_up_container.dart';
import 'package:tagiary/tables/check/check_enum.dart';
import 'package:tagiary/tables/check/check_item.dart';
import 'package:tagiary/todo_widget/add_todo/add_todo.dart';
import 'package:tagiary/todo_widget/todo_widget.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

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
          final pendingTodos = todos.where((todo) => todo.check == CheckEnum.pending).toList()
            ..sort((a, b) {
              if (a.dueDate == null && b.dueDate == null) {
                return b.id.compareTo(a.id); // Newer tasks first if no end date
              } else if (a.dueDate == null) {
                return 1; // b comes first
              } else if (b.dueDate == null) {
                return -1; // a comes first
              } else {
                return a.dueDate!.compareTo(b.dueDate!);
              }
            });

          final inProgressTodos = todos.where((todo) => todo.check == CheckEnum.inProgress).toList()..sort((a, b) => b.id.compareTo(a.id)); // Newer tasks first

          // Get checked items sorted by updated (most recent first)
          final doneTodos = todos.where((todo) => todo.check == CheckEnum.done).toList()
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pendingTodos.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      '할 일',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...pendingTodos.map((todo) => _buildTodoItem(todo)),
                  const SizedBox(height: 24),
                ],
                if (pendingTodos.isNotEmpty && inProgressTodos.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(
                      thickness: 1,
                    ),
                  )
                else if (pendingTodos.isNotEmpty && doneTodos.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(
                      thickness: 1,
                    ),
                  ),
                if (inProgressTodos.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      '진행 중',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...inProgressTodos.map((todo) => _buildTodoItem(todo)),
                ],
                // if (pendingTodos.isNotEmpty && doneTodos.isNotEmpty)
                //   const Padding(
                //     padding: EdgeInsets.symmetric(horizontal: 16.0),
                //     child: Divider(
                //       thickness: 1,
                //     ),
                //   ),
                if (inProgressTodos.isNotEmpty && doneTodos.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(
                      thickness: 1,
                    ),
                  ),
                if (doneTodos.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      '완료',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...doneTodos.map((todo) => _buildTodoItem(todo)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  CheckEnum _getNextStatus(CheckEnum currentStatus) {
    switch (currentStatus) {
      case CheckEnum.pending:
        return CheckEnum.inProgress; // false → null
      case CheckEnum.inProgress:
        return CheckEnum.done; // null → true
      case CheckEnum.done:
        return CheckEnum.pending; // true → false
    }
  }

  Widget _buildTodoItem(CheckItem todo) {
    return InkWell(
      onTap: () => _showEditTodoDialog(context, todo),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.0),
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 0, right: 4),
          dense: true,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          leading: Checkbox(
            tristate: true,
            value: getCheckboxValue(todo.check),
            onChanged: (value) {
              _updateTodoCheckEnum(todo, _getNextStatus(todo.check));
            },
            shape: const CircleBorder(),
            activeColor: Color(todo.colorValue),
            side: BorderSide(
              color: todo.check != CheckEnum.pending ? Colors.transparent : Color(todo.colorValue),
              width: 2,
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  todo.content,
                  style: TextStyle(
                    color: todo.check == CheckEnum.done ? Colors.grey : Colors.black,
                    fontSize: 16,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (todo.dueDate != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: _buildDDay(todo.dueDate!),
                ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              _deleteTodo(todo);
            },
          ),
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

  void _updateTodoCheck(CheckItem todo, bool? value) {
    CheckEnum newCheckValue;

    if (value == true) {
      newCheckValue = CheckEnum.done;
    } else if (value == false) {
      newCheckValue = CheckEnum.pending;
    } else {
      newCheckValue = CheckEnum.inProgress;
    }

    _updateTodoCheckEnum(todo, newCheckValue);
  }

  void _updateTodoCheckEnum(CheckItem todo, CheckEnum value) {
    final updatedTodo = CheckItem(
      id: todo.id,
      content: todo.content,
      dueDate: todo.dueDate,
      startDate: todo.startDate,
      doneDate: todo.doneDate,
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

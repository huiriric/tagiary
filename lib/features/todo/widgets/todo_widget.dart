import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mrplando/shared/widgets/slide_up_container.dart';
import 'package:mrplando/core/constants/colors.dart';
import 'package:mrplando/shared/models/check_enum.dart';
import 'package:mrplando/features/todo/models/check_item.dart';
import 'package:mrplando/features/todo/widgets/add_todo.dart';
import 'package:mrplando/features/home/widgets/home_widget_provider.dart';

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
    final pendingCount = todos.where((todo) => todo.check == CheckEnum.pending).length;
    final inProgressCount = todos.where((todo) => todo.check == CheckEnum.inProgress).length;
    final doneCount = todos.where((todo) => todo.check == CheckEnum.done).length;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: todos.isEmpty ? () => _showAddTodoDialog(context) : () => _showTodoListDialog(context),
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
                          '$pendingCount개',
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

    final inProgressTodos = todos.where((todo) => todo.check == CheckEnum.inProgress).toList()
      ..sort((a, b) => b.id.compareTo(a.id)); // Using id as proxy for update time
    // Show at most 3 items in preview
    final previewTodos = [...inProgressTodos.take(3), ...pendingTodos.take(3)];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      itemCount: previewTodos.length,
      itemBuilder: (context, index) {
        final todo = previewTodos[index];

        return ListTile(
          contentPadding: const EdgeInsets.only(left: 0, right: 6),
          dense: true,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          title: Text(
            todo.content,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
          leading: Checkbox(
            tristate: true,
            value: getCheckboxValue(todo.check),
            onChanged: (value) {
              setState(() {
                _updateTodoCheckEnum(todo, _getNextStatus(todo.check));
              });
            },
            shape: const CircleBorder(),
            activeColor: Color(todo.colorValue),
            side: BorderSide(
              color: todo.check != CheckEnum.pending ? Colors.transparent : Color(todo.colorValue),
              width: 2,
            ),
          ),
          trailing: todo.dueDate != null ? _buildDDay(todo.dueDate!) : null,
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

              final inProgressTodos = todos.where((todo) => todo.check == CheckEnum.inProgress).toList()
                ..sort((a, b) => b.id.compareTo(a.id)); // Using id as proxy for update time

              // Get checked items sorted by updated (most recent first)
              final doneTodos = todos.where((todo) => todo.check == CheckEnum.done).toList()
                ..sort((a, b) => b.id.compareTo(a.id)); // Using id as proxy for update time

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pendingTodos.isNotEmpty) ...[
                      const Text(
                        '미완료',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...pendingTodos.map((todo) => _buildTodoItem(todo)),
                      const SizedBox(height: 16),
                    ],
                    if (inProgressTodos.isNotEmpty) ...[
                      const Text(
                        '진행 중',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...inProgressTodos.map((todo) => _buildTodoItem(todo)),
                      const SizedBox(height: 16),
                    ],
                    if (doneTodos.isNotEmpty) ...[
                      const Text(
                        '완료',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Checkbox(
            tristate: true,
            value: getCheckboxValue(todo.check),
            onChanged: (value) {
              _updateTodoCheckEnum(todo, _getNextStatus(todo.check));
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
                    color: todo.check == CheckEnum.done ? Colors.grey : Colors.black,
                    fontSize: 14,
                  ),
                ),
                if (todo.dueDate != null) _buildDDay(todo.dueDate!),
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

  void _updateTodoCheck(CheckItem todo, bool? value) {
    CheckEnum newCheckValue;

    if (value == true) {
      newCheckValue = CheckEnum.done;
    } else if (value == false) {
      newCheckValue = CheckEnum.pending;
    } else {
      newCheckValue = CheckEnum.inProgress;
    }

    // if (value == true) {
    //   newCheckValue = CheckEnum.done;
    // } else if (todo.check == CheckEnum.pending) {
    //   newCheckValue = CheckEnum.inProgress;
    // } else {
    //   newCheckValue = CheckEnum.pending;
    // }

    _updateTodoCheckEnum(todo, newCheckValue);
  }

  void _updateTodoCheckEnum(CheckItem todo, CheckEnum value) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    final updatedTodo = CheckItem(
      id: todo.id,
      content: todo.content,
      dueDate: todo.dueDate,
      startDate: value == CheckEnum.pending
          ? null
          : value == CheckEnum.inProgress
              ? today.toIso8601String()
              : todo.startDate,
      doneDate: value == CheckEnum.pending
          ? null
          : value == CheckEnum.inProgress
              ? null
              : today.toIso8601String(),
      colorValue: todo.colorValue,
      check: value,
    );

    _repository.updateItem(updatedTodo);
    value == CheckEnum.done
        ? _showToast('${todo.content} 완료!')
        : value == CheckEnum.inProgress
            ? _showToast('${todo.content} 시작!')
            : null;

    // 홈 화면 위젯 업데이트
    // HomeWidgetProvider.updateTodoWidget();
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

bool? getCheckboxValue(CheckEnum status) {
  switch (status) {
    case CheckEnum.pending:
      return false; // 빈 체크박스
    case CheckEnum.inProgress:
      return null; // 하이픈(-) 표시
    case CheckEnum.done:
      return true; // 체크 표시
  }
}

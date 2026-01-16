import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mrplando/shared/widgets/slide_up_container.dart';
import 'package:mrplando/shared/models/check_enum.dart';
import 'package:mrplando/shared/models/category_manager_interface.dart';
import 'package:mrplando/features/todo/models/check_item.dart';
import 'package:mrplando/features/todo/widgets/add_todo.dart';

class CategoryTodoDetailScreen extends StatefulWidget {
  final CategoryInfo category;
  final List<CategoryInfo> allCategories;

  const CategoryTodoDetailScreen({
    super.key,
    required this.category,
    required this.allCategories,
  });

  @override
  State<CategoryTodoDetailScreen> createState() => _CategoryTodoDetailScreenState();
}

class _CategoryTodoDetailScreenState extends State<CategoryTodoDetailScreen> {
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: widget.category.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.category.name,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: widget.category.color,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
        onPressed: () => _showAddTodoDialog(context),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<CheckItem>('checkBox').listenable(),
        builder: (context, Box<CheckItem> box, _) {
          // 해당 카테고리의 할 일만 필터링
          var todos = box.values.where((todo) => todo.categoryId == widget.category.id).toList();

          final pendingTodos = todos.where((todo) => todo.check == CheckEnum.pending).toList()
            ..sort((a, b) {
              if (a.dueDate == null && b.dueDate == null) {
                return b.id.compareTo(a.id);
              } else if (a.dueDate == null) {
                return 1;
              } else if (b.dueDate == null) {
                return -1;
              } else {
                return a.dueDate!.compareTo(b.dueDate!);
              }
            });

          final inProgressTodos = todos.where((todo) => todo.check == CheckEnum.inProgress).toList()
            ..sort((a, b) => b.id.compareTo(a.id));

          final doneTodos = todos.where((todo) => todo.check == CheckEnum.done).toList()
            ..sort((a, b) => b.id.compareTo(a.id));

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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '미완료',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${pendingTodos.length}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pendingTodos.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _buildTodoItem(pendingTodos[index]),
                    ),
                  ),
                ],
                if (inProgressTodos.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '진행 중',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${inProgressTodos.length}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: inProgressTodos.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _buildTodoItem(inProgressTodos[index]),
                    ),
                  ),
                ],
                if (doneTodos.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.green.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '완료',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${doneTodos.length}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: doneTodos.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _buildTodoItem(doneTodos[index]),
                    ),
                  ),
                  const SizedBox(height: 24),
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
        return CheckEnum.inProgress;
      case CheckEnum.inProgress:
        return CheckEnum.done;
      case CheckEnum.done:
        return CheckEnum.pending;
    }
  }

  Widget _buildTodoItem(CheckItem todo) {
    final Color itemColor = Color(todo.colorValue);
    final bool isDone = todo.check == CheckEnum.done;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? Colors.grey.shade200 : itemColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDone ? Colors.black.withOpacity(0.03) : itemColor.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditTodoDialog(context, todo),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDone ? Colors.grey.shade300 : itemColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Transform.scale(
                  scale: 1.1,
                  child: Checkbox(
                    tristate: true,
                    value: getCheckboxValue(todo.check),
                    onChanged: (value) {
                      _updateTodoCheckEnum(todo, _getNextStatus(todo.check));
                    },
                    shape: const CircleBorder(),
                    activeColor: itemColor,
                    side: BorderSide(
                      color: todo.check != CheckEnum.pending ? Colors.transparent : itemColor,
                      width: 2.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.content,
                        style: TextStyle(
                          color: isDone ? Colors.grey.shade500 : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          decorationColor: Colors.grey.shade400,
                          decorationThickness: 2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (todo.dueDate != null) ...[
                  const SizedBox(width: 12),
                  _buildDDay(todo.dueDate!),
                ],
              ],
            ),
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
    Color bgColor;
    Color textColor;
    IconData? icon;

    if (difference < 0) {
      text = '+${-difference}';
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      icon = Icons.warning_rounded;
    } else if (difference == 0) {
      text = 'D-Day';
      bgColor = Colors.red.shade100;
      textColor = Colors.red.shade900;
      icon = Icons.notifications_active_rounded;
    } else if (difference <= 3) {
      text = 'D-$difference';
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      icon = Icons.access_time_rounded;
    } else if (difference <= 7) {
      text = 'D-$difference';
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue.shade700;
    } else {
      text = 'D-$difference';
      bgColor = Colors.grey.shade100;
      textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: textColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 12,
              color: textColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
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
      categoryId: todo.categoryId,
    );

    _repository.updateItem(updatedTodo);
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
              categories: widget.allCategories,
              onTodoAdded: () {
                setState(() {});
              },
              category: widget.category,
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
              categories: widget.allCategories,
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

bool? getCheckboxValue(CheckEnum status) {
  switch (status) {
    case CheckEnum.pending:
      return false;
    case CheckEnum.inProgress:
      return null;
    case CheckEnum.done:
      return true;
  }
}

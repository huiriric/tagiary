import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mrplando/shared/models/category_manager_interface.dart';
import 'package:mrplando/shared/widgets/slide_up_container.dart';
import 'package:mrplando/shared/models/check_enum.dart';
import 'package:mrplando/features/todo/models/check_item.dart';
import 'package:mrplando/features/todo/models/todo_category.dart';
import 'package:mrplando/features/todo/models/todo_category_manager.dart';
import 'package:mrplando/features/todo/widgets/add_todo.dart';
import 'package:mrplando/features/todo/screens/category_todo_detail_screen.dart';
import 'package:mrplando/shared/widgets/category_management_page.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  late CheckRepository _repository;
  late TodoCategoryManager _categoryManager;
  List<CategoryInfo> _categories = [];

  @override
  void initState() {
    super.initState();
    _repository = CheckRepository();
    _repository.init();

    _categoryManager = TodoCategoryManager(
      categoryRepository: TodoCategoryRepository(),
    );
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    await _categoryManager.init();
    setState(() {
      _categories = _categoryManager.getAllCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            color: Colors.grey.shade600,
            tooltip: '카테고리 관리',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryManagementPage(
                    categoryManager: _categoryManager,
                    title: '할 일 카테고리',
                    onCategoriesUpdated: () {
                      setState(() {
                        _categories = _categoryManager.getAllCategories();
                      });
                    },
                  ),
                ),
              );
              setState(() {
                _categories = _categoryManager.getAllCategories();
              });
            },
          ),
        ],
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
          if (_categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '카테고리를 추가해보세요',
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
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _categories.map((category) {
                return _buildCategoryCard(context, category, box);
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryInfo category, Box<CheckItem> box) {
    // 해당 카테고리의 할 일들 필터링
    final categoryTodos = box.values.where((todo) => todo.categoryId == category.id).toList();
    final pendingCount = categoryTodos.where((todo) => todo.check == CheckEnum.pending).length;
    final inProgressCount = categoryTodos.where((todo) => todo.check == CheckEnum.inProgress).length;
    final doneCount = categoryTodos.where((todo) => todo.check == CheckEnum.done).length;

    // 최근 3개의 미완료/진행중 항목 미리보기
    final activeTodos = categoryTodos.where((todo) => todo.check != CheckEnum.done).toList()
      ..sort((a, b) {
        // 진행중 우선, 그 다음 마감일 가까운 순
        if (a.check != b.check) {
          return a.check == CheckEnum.inProgress ? -1 : 1;
        }
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

    final previewTodos = activeTodos.take(3).toList();
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 48) / 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 화면 너비에 따라 카드 크기 조정

        return SizedBox(
          width: cardWidth,
          height: cardWidth,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            color: Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: categoryTodos.isEmpty
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryTodoDetailScreen(
                            category: category,
                            allCategories: _categories,
                          ),
                        ),
                      );
                    },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 헤더: 카테고리 이름과 카운터
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 4.0),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: category.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: category.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$pendingCount',
                            style: TextStyle(
                              color: category.color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // const SizedBox(height: 6),
                  // 상태별 카운터
                  // Row(
                  //   children: [
                  //     _buildStatusChip('진행중', inProgressCount, Colors.orange),
                  //     const SizedBox(width: 8),
                  //     _buildStatusChip('완료', doneCount, Colors.green),
                  //   ],
                  // ),
                  // const SizedBox(height: 12),
                  // const Divider(height: 1),
                  // const SizedBox(height: 12),
                  // 할 일 미리보기
                  if (categoryTodos.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          '할 일이 없습니다',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else if (previewTodos.isEmpty && doneCount > 0)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.green[300],
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '모두 완료!',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...previewTodos.map((todo) {
                      final Color itemColor = Color(todo.colorValue);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            Checkbox(
                              tristate: true,
                              value: _getCheckboxValue(todo.check),
                              onChanged: (value) {
                                _updateTodoCheckEnum(todo, _getNextStatus(todo.check));
                              },
                              shape: const CircleBorder(),
                              activeColor: itemColor,
                              side: BorderSide(
                                color: todo.check != CheckEnum.pending ? Colors.transparent : itemColor,
                                width: 2.0,
                              ),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            Expanded(
                              child: Text(
                                todo.content,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  decoration: todo.check == CheckEnum.done ? TextDecoration.lineThrough : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  bool? _getCheckboxValue(CheckEnum status) {
    switch (status) {
      case CheckEnum.pending:
        return false;
      case CheckEnum.inProgress:
        return null;
      case CheckEnum.done:
        return true;
    }
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
              categories: _categories,
              onTodoAdded: () {
                setState(() {});
              },
              onCategoryUpdated: () {
                setState(() {
                  _loadCategories();
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}

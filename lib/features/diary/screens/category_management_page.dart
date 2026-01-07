import 'package:flutter/material.dart';
import 'package:mrplando/shared/widgets/color_picker.dart';
import 'package:mrplando/shared/widgets/slide_up_container.dart';
import 'package:mrplando/core/constants/colors.dart';
import 'package:mrplando/features/diary/models/tag_manager.dart';
import 'package:mrplando/features/settings/screens/color_management_page.dart';

class CategoryManagementPage extends StatefulWidget {
  final TagManager tagManager;

  const CategoryManagementPage({
    super.key,
    required this.tagManager,
  });

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  List<CategoryInfo> _categories = [];
  double colorPadding = 20;
  double colorSize = 35;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    setState(() {
      _categories = widget.tagManager.getAllCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '카테고리 관리',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 28),
            onPressed: _showAddCategoryDialog,
          ),
        ],
      ),
      body: _categories.isEmpty
          ? const Center(
              child: Text(
                '카테고리가 없습니다',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showEditDialog(category),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: category.color.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: category.color,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: category.color.withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                category.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade400,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // 카테고리 추가 다이얼로그
  void _showAddCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    Color selectedColor = scheduleColors.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AnimatedPadding(
              padding: MediaQuery.of(context).viewInsets,
              duration: const Duration(milliseconds: 100),
              child: GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: SlideUpContainer(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 카테고리 이름 입력
                            TextFormField(
                              controller: nameController,
                              autofocus: true,
                              textInputAction: TextInputAction.done,
                              onEditingComplete: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                              decoration: const InputDecoration(
                                hintText: '카테고리 이름',
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
                            // 색상 선택
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: ColorPicker(
                                selectedColor: selectedColor,
                                onColorChanged: (color) {
                                  setModalState(() {
                                    selectedColor = color;
                                  });
                                },
                                padding: colorPadding,
                                colorSize: colorSize,
                              ),
                            ),
                          ],
                        ),
                        // 우측 상단에 저장 버튼 (녹색 체크 아이콘)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            onPressed: () async {
                              final name = nameController.text.trim();
                              if (name.isNotEmpty) {
                                // 새 카테고리 추가
                                await widget.tagManager.addCategory(name, selectedColor);
                                Navigator.pop(context);
                                _loadCategories();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('카테고리가 추가되었습니다')),
                                  );
                                }
                              }
                            },
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
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 카테고리 삭제 확인 다이얼로그
  void _showDeleteDialog(CategoryInfo category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카테고리 삭제'),
        content: Text('${category.name} 카테고리를 삭제하시겠습니까?\n\n이 카테고리를 사용하는 기록은 남아있지만, 카테고리 목록에서는 보이지 않습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              await widget.tagManager.softDeleteCategory(category.id);
              Navigator.pop(context);
              _loadCategories();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('카테고리가 삭제되었습니다')),
                );
              }
            },
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // 카테고리 수정 다이얼로그
  void _showEditDialog(CategoryInfo category) {
    final TextEditingController nameController = TextEditingController(text: category.name);
    Color selectedColor = category.color;
    bool hasChanges = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // 변경사항 확인
            hasChanges = nameController.text.trim() != category.name ||
                         selectedColor != category.color;

            return AnimatedPadding(
              padding: MediaQuery.of(context).viewInsets,
              duration: const Duration(milliseconds: 100),
              child: GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: SlideUpContainer(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 카테고리 이름 입력
                            TextFormField(
                              controller: nameController,
                              autofocus: true,
                              textInputAction: TextInputAction.done,
                              onChanged: (value) {
                                setModalState(() {
                                  // 상태 업데이트하여 hasChanges 재계산
                                });
                              },
                              onEditingComplete: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                              decoration: const InputDecoration(
                                hintText: '카테고리 이름',
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
                            // 색상 선택
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: ColorPicker(
                                  selectedColor: selectedColor,
                                  onColorChanged: (color) {
                                    setModalState(() {
                                      selectedColor = color;
                                    });
                                  },
                                  padding: colorPadding,
                                  colorSize: colorSize),
                            ),
                          ],
                        ),
                        // 우측 상단에 저장 및 삭제 버튼
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasChanges)
                                IconButton(
                                  onPressed: () async {
                                    final name = nameController.text.trim();
                                    if (name.isNotEmpty) {
                                      await widget.tagManager.updateCategory(
                                        category.id,
                                        name,
                                        selectedColor,
                                      );
                                      Navigator.pop(context);
                                      _loadCategories();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('카테고리가 수정되었습니다')),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                    size: 32,
                                  ),
                                ),
                              IconButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showDeleteDialog(category);
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

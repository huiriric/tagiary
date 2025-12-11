import 'package:flutter/material.dart';
import 'package:mrplando/component/slide_up_container.dart';
import 'package:mrplando/constants/colors.dart';
import 'package:mrplando/tables/diary/tag_manager.dart';
import 'package:mrplando/screens/color_management_page.dart';

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
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0.5,
                  color: Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.only(
                      left: 16,
                      right: 8,
                      top: 8,
                      bottom: 8,
                    ),
                    leading: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: category.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _showDeleteDialog(category),
                    ),
                    onTap: () => _showEditDialog(category),
                  ),
                );
              },
            ),
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
                  child: SingleChildScrollView(
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
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: colorPadding),
                                      child: Wrap(
                                        spacing: (MediaQuery.of(context).size.width - (colorPadding * 4 + colorSize * 6)) / 5,
                                        runSpacing: 12,
                                        children: [
                                          ...scheduleColors.map((color) {
                                            return GestureDetector(
                                              onTap: () {
                                                setModalState(() {
                                                  selectedColor = color;
                                                });
                                              },
                                              child: Container(
                                                width: 35,
                                                height: 35,
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  shape: BoxShape.circle,
                                                  border: selectedColor.value == color.value ? Border.all(color: Colors.black, width: 2) : null,
                                                ),
                                              ),
                                            );
                                          }),
                                          GestureDetector(
                                            onTap: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => const ColorManagementPage(),
                                                ),
                                              );
                                              setModalState(() {});
                                            },
                                            child: Container(
                                              width: 35,
                                              height: 35,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade300,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.add,
                                                color: Colors.grey,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
              ),
            );
          },
        );
      },
    );
  }
}

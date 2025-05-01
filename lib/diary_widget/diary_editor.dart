import 'package:flutter/material.dart';
import 'package:tagiary/component/slide_up_container.dart';
import 'package:tagiary/constants/colors.dart';
import 'package:tagiary/diary_widget/tag_selector.dart';
import 'package:tagiary/tables/diary/diary_item.dart';
import 'package:tagiary/tables/diary/tag.dart';
import 'package:tagiary/tables/diary/tag_group.dart';
import 'package:tagiary/tables/diary/tag_manager.dart';

class DiaryEditorPage extends StatefulWidget {
  final DiaryItem? diary;
  final DateTime date;
  final TagManager tagManager;
  final Function(DiaryItem) onSave;

  const DiaryEditorPage({
    super.key,
    this.diary,
    required this.date,
    required this.tagManager,
    required this.onSave,
  });

  @override
  State<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends State<DiaryEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  int? _selectedCategoryId;
  List<int> _selectedTagIds = [];
  bool _isLoading = false;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.date; // 초기 날짜 설정

    // 수정 모드인 경우 기존 데이터로 초기화
    if (widget.diary != null) {
      _titleController = TextEditingController(text: widget.diary!.title);
      _contentController = TextEditingController(text: widget.diary!.content);
      _selectedCategoryId = widget.diary!.categoryId;
      _selectedTagIds = List<int>.from(widget.diary!.tagIds);
    } else {
      _titleController = TextEditingController();
      _contentController = TextEditingController();
    }
  }

  // 날짜 선택 다이얼로그 표시
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black, // 헤더 배경 색상
              onPrimary: Colors.white, // 헤더 텍스트 색상
              onSurface: Colors.black, // 달력 텍스트 색상
              surface: Colors.white, // 배경 색상
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black, // 버튼 텍스트 색상
              ),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.diary == null ? '새 다이어리' : '다이어리 수정'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜 선택 카드
                  InkWell(
                    onTap: _selectDate,
                    child: Card(
                      elevation: 0,
                      color: Colors.grey[100],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 제목 입력
                  TextField(
                    decoration: const InputDecoration(
                        labelText: '제목',
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        hintText: '제목을 입력하세요',
                        hintStyle: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                        )),
                    controller: _titleController,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLength: 50,
                  ),
                  const SizedBox(height: 16),

                  // 카테고리 선택
                  _buildCategorySelector(),
                  const SizedBox(height: 16),

                  // 태그 선택
                  _buildTagSelector(),
                  const SizedBox(height: 16),

                  // 내용 입력
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      labelText: '내용',
                      border: OutlineInputBorder(),
                      hintText: '오늘의 기록을 남겨보세요',
                      alignLabelWithHint: true,
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                    maxLines: 10,
                    minLines: 5,
                  ),
                  const SizedBox(height: 32),

                  // 저장 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveDiary,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        '저장하기',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCategorySelector() {
    // 카테고리(태그 그룹) 목록
    final groupInfos = widget.tagManager.getAllGroupInfo();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '카테고리',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...groupInfos.map((group) {
              final isSelected = _selectedCategoryId == group.id;
              return ChoiceChip(
                showCheckmark: false,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                label: Text(
                  group.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
                selected: isSelected,
                selectedColor: group.color,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategoryId = selected ? group.id : null;
                  });
                },
              );
            }),
            ActionChip(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              label: const Text('+ 새 카테고리'),
              onPressed: _showAddCategoryDialog,
              backgroundColor: Colors.grey[200],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagSelector() {
    // 선택된 태그 ID로부터 태그 정보 가져오기
    final selectedTags = widget.tagManager.getTagInfoList(_selectedTagIds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '태그',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // 선택된 태그 표시
        if (selectedTags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedTags.map((tag) {
              return Chip(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                side: BorderSide.none,
                label: Text(
                  tag.name,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: tag.color,
                deleteIcon: const Icon(
                  Icons.cancel,
                  size: 16,
                  color: Colors.white,
                ),
                onDeleted: () {
                  setState(() {
                    _selectedTagIds.remove(tag.id);
                  });
                },
              );
            }).toList(),
          ),

        const SizedBox(height: 8),

        // 태그 선택 버튼
        OutlinedButton.icon(
          onPressed: _showTagSelector,
          icon: const Icon(
            Icons.tag,
            size: 17,
          ),
          label: const Text('태그 선택/추가'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  void _showAddCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    Color selectedColor = scheduleColors.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('새 카테고리 추가'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '카테고리 이름',
                      hintText: '카테고리 이름을 입력하세요',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('색상 선택'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: scheduleColors.map((color) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: selectedColor == color ? Border.all(color: Colors.black, width: 2) : null,
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
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      // 새 카테고리 추가
                      final groupId = await widget.tagManager.addTagGroup(name, selectedColor);
                      setState(() {
                        _selectedCategoryId = groupId;
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('추가'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTagSelector() async {
    // 태그 선택 페이지로 이동
    final result = await Navigator.push<List<int>>(
      context,
      MaterialPageRoute(
        builder: (context) => TagSelectorPage(
          tagManager: widget.tagManager,
          selectedTagIds: List<int>.from(_selectedTagIds),
        ),
      ),
    );

    // 결과가 있으면 반영
    if (result != null) {
      setState(() {
        _selectedTagIds = result;
      });
    }
  }

  void _saveDiary() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요')),
      );
      return;
    }

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력해주세요')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 날짜는 년, 월, 일 정보만 포함하도록 설정
    final dateOnly = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    final DiaryItem newDiary = DiaryItem(
      id: widget.diary?.id ?? 0, // 신규는 0, 수정은 기존 ID
      title: title,
      date: dateOnly,
      content: content,
      categoryId: _selectedCategoryId,
      tagIds: _selectedTagIds,
    );

    try {
      await widget.onSave(newDiary);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // 수정된 다이어리를 결과로 반환하며 화면 닫기
        Navigator.pop(context, newDiary);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }
}

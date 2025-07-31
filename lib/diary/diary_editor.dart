import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tagiary/component/slide_up_container.dart';
import 'package:tagiary/constants/colors.dart';
import 'package:tagiary/diary/tag_selector.dart';
import 'package:tagiary/tables/diary/diary_item.dart';
import 'package:tagiary/tables/diary/tag.dart';
import 'package:tagiary/tables/diary/tag_manager.dart';

class DiaryEditorPage extends StatefulWidget {
  final DiaryItem? diary;
  final DateTime date;
  final TagManager tagManager;
  final bool isEdit;
  final Function(DiaryItem)? onSave;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DiaryEditorPage({
    super.key,
    this.diary,
    required this.date,
    required this.tagManager,
    required this.isEdit,
    this.onSave,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends State<DiaryEditorPage> {
  late DiaryRepository _diaryRepository;
  // late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagCont;
  late FocusNode _contentFocus;
  int? _selectedCategoryId;
  List<int> _selectedTagIds = [];
  List<String> tags = [];
  bool _isLoading = false;
  late DateTime _selectedDate;

  // 태그 검색 관련 상태
  List<TagInfo> _searchResults = [];
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.date; // 초기 날짜 설정
    _tagCont = TextEditingController(text: null);
    _diaryRepository = DiaryRepository();

    // 태그 입력 필드 변화 감지
    _tagCont.addListener(_onTagInputChanged);

    // _contentFocus auto focus
    _contentFocus = FocusNode();

    // 수정 모드인 경우 기존 데이터로 초기화
    if (widget.diary != null) {
      // _titleController = TextEditingController(text: widget.diary!.title);
      _contentController = TextEditingController(text: widget.diary!.content);
      _selectedCategoryId = widget.diary!.categoryId;
      _selectedTagIds = List<int>.from(widget.diary!.tagIds);

      // 기존 태그들을 tags 리스트에도 추가
      final existingTags = widget.tagManager.getTagInfoList(_selectedTagIds);
      tags = existingTags.map((tag) => tag.name).toList();
    } else {
      // _titleController = TextEditingController();
      _contentController = TextEditingController();
    }
  }

  @override
  void dispose() {
    // _titleController.dispose();
    _contentController.dispose();
    _tagCont.removeListener(_onTagInputChanged);
    _tagCont.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.diary == null ? '새 다이어리' : '다이어리',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (widget.isEdit)
              IconButton(
                onPressed: () => deleteDialog(widget.diary!.id),
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
              )
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                bottom: false,
                child: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    setState(() {
                      _showSearchResults = false;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 날짜 선택 카드
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
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
                            ),
                            ActionChip(
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              label: Text(_selectedCategoryId != null ? widget.tagManager.groupRepository.getGroup(_selectedCategoryId!)!.name : '카테고리'),
                              labelStyle: TextStyle(color: _selectedCategoryId != null ? Colors.white : Colors.black),
                              onPressed: _buildCategorySelector,
                              backgroundColor: _selectedCategoryId != null
                                  ? Color(widget.tagManager.groupRepository.getGroup(_selectedCategoryId!)!.colorValue)
                                  : Colors.grey[300],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 제목 입력
                        // TextField(
                        //   decoration: const InputDecoration(
                        //       labelText: '제목',
                        //       border: UnderlineInputBorder(
                        //         borderSide: BorderSide(color: Colors.grey),
                        //       ),
                        //       enabledBorder: UnderlineInputBorder(
                        //         borderSide: BorderSide(color: Colors.grey),
                        //       ),
                        //       focusedBorder: UnderlineInputBorder(
                        //         borderSide: BorderSide(color: Colors.grey),
                        //       ),
                        //       hintText: '제목을 입력하세요',
                        //       hintStyle: TextStyle(
                        //         fontSize: 17,
                        //         fontWeight: FontWeight.w400,
                        //       )),
                        //   controller: _titleController,
                        //   style: const TextStyle(
                        //     fontSize: 17,
                        //     fontWeight: FontWeight.bold,
                        //   ),
                        //   maxLength: 50,
                        // ),
                        // const SizedBox(height: 16),

                        // 내용 입력
                        Expanded(
                          child: TextField(
                            controller: _contentController,
                            focusNode: _contentFocus,
                            autofocus: widget.isEdit ? false : true,
                            onChanged: (value) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: '내용',
                              border: OutlineInputBorder(borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(),
                              hintText: '오늘의 기록을 남겨보세요',
                              alignLabelWithHint: true,
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                            ),
                            maxLines: null,
                            minLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                          ),
                        ),
                        // const SizedBox(height: 16),
                        // 태그 선택
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: _buildTagSelector(),
                        ),

                        // Expanded(child: Container()),
                        // 저장 버튼
                        if (!widget.isEdit || !noChanged())
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saveDiary,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Text(
                                  widget.isEdit ? '수정하기' : '저장하기',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // 태그 입력 변화 감지 함수
  void _onTagInputChanged() {
    final query = _tagCont.text.trim();

    if (query.isEmpty) {
      setState(() {
        _showSearchResults = false;
        _searchResults.clear();
      });
      return;
    }

    // 기존에 추가된 태그들은 제외하고 검색
    final searchResults = widget.tagManager
        .searchTags(query)
        .where((tag) => !tags.contains(tag.name))
        .take(5) // 최대 5개만 표시
        .toList();

    setState(() {
      _searchResults = searchResults;
      _showSearchResults = searchResults.isNotEmpty;
    });
  }

  // 태그 추가 함수
  void _addTag(String tagName) {
    if (tagName.trim().isEmpty || tags.contains(tagName)) return;

    setState(() {
      tags.add(tagName.trim());
      _tagCont.clear();
      _showSearchResults = false;
      _searchResults.clear();
    });
  }

  // 변경사항 확인 함수
  bool noChanged() {
    if (widget.diary == null) return true; // 새 일기는 항상 변경된 것으로 처리

    final originalDiary = widget.diary!;

    // 날짜 비교 (년, 월, 일만 비교)
    final originalDate = DateTime(originalDiary.date.year, originalDiary.date.month, originalDiary.date.day);
    final currentDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    if (originalDate != currentDate) return false;

    // 카테고리 비교
    if (originalDiary.categoryId != _selectedCategoryId) return false;

    // 내용 비교
    if (originalDiary.content != _contentController.text.trim()) return false;

    // 태그 리스트 비교
    final originalTags = widget.tagManager.getTagInfoList(originalDiary.tagIds).map((tag) => tag.name).toSet();
    final currentTags = tags.toSet();
    if (!originalTags.containsAll(currentTags) || !currentTags.containsAll(originalTags)) {
      return false;
    }

    return true; // 모든 값이 같으면 true 반환
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
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
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

  void _buildCategorySelector() {
    // 카테고리(태그 그룹) 목록
    final categoryInfos = widget.tagManager.getAllCategories();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: StatefulBuilder(
          builder: (BuildContext context, dialogSetState) {
            return SizedBox(
              width: 350,
              height: 400,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: SingleChildScrollView(
                  child: Column(
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
                          ...categoryInfos.map((group) {
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
                              onSelected: (selected) async {
                                dialogSetState(() {
                                  _selectedCategoryId = selected ? group.id : null;
                                });
                                setState(() {});
                                await Future.delayed(const Duration(milliseconds: 500));
                                Navigator.pop(context);
                              },
                            );
                          }),
                          ActionChip(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            label: const Text('+ 새 카테고리'),
                            onPressed: () {
                              Navigator.pop(context);
                              _showAddCategoryDialog(() => dialogSetState(() {}));
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTagSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'tag',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // 태그 입력 필드
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagCont,
                decoration: const InputDecoration(
                  hintText: '해시 태그 (입력 후 + 버튼을 눌러주세요)',
                  // 언더라인 완전 제거
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  // 힌트 스타일 커스터마이징
                  hintStyle: TextStyle(
                    color: Color(0xFFD7CDB9),
                  ),
                ),
                style: const TextStyle(
                  fontSize: 15,
                ),
                onTap: () {
                  // 입력 필드 포커스 시 검색 결과 표시
                  if (_tagCont.text.isNotEmpty) {
                    _onTagInputChanged();
                  }
                },
                onSubmitted: (value) => _addTag(value),
              ),
            ),
            IconButton(
              onPressed: () => _addTag(_tagCont.text),
              icon: const Icon(Icons.add_rounded, size: 24),
            )
          ],
        ),

        // 태그 입력시 검색 리스트
        if (_showSearchResults && _searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '추천 tag',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 4,
                  runSpacing: 6,
                  children: _searchResults.map((tag) {
                    return GestureDetector(
                      onTap: () => _addTag(tag.name),
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tag.name,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.add,
                              size: 16,
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // 선택된 태그 리스트
        if (tags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags
                .map(
                  (e) => GestureDetector(
                    onTap: () => setState(() {
                      tags.remove(e);
                    }),
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            e,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.clear_rounded,
                            size: 16,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          )
      ],
    );
  }

  void _showAddCategoryDialog(VoidCallback callback) {
    final TextEditingController nameController = TextEditingController();
    Color selectedColor = scheduleColors.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                  Column(
                    children: [
                      // 첫 번째 줄 (색상 0-5)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) {
                          final color = scheduleColors[index];
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
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
                        }),
                      ),
                      const SizedBox(height: 12),
                      // 두 번째 줄 (색상 6-11)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) {
                          final color = scheduleColors[index + 6];
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
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
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      // 새 카테고리 추가
                      final groupId = await widget.tagManager.addCategory(name, selectedColor);
                      Navigator.pop(context);

                      // 메인 위젯 상태 업데이트
                      setState(() {
                        _selectedCategoryId = groupId;
                      });

                      // 카테고리 선택 다이얼로그 새로 그리기
                      callback();
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

  void _saveDiary() async {
    // final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // if (title.isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('제목을 입력해주세요')),
    //   );
    //   return;
    // }

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력해주세요')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 태그 문자열들을 태그 ID로 변환
      List<int> finalTagIds = [];
      for (String tagName in tags) {
        final tagId = await widget.tagManager.addOrGetTag(tagName);
        finalTagIds.add(tagId);
      }

      // 날짜는 년, 월, 일 정보만 포함하도록 설정
      final dateOnly = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );

      final DiaryItem newDiary = DiaryItem(
        id: widget.diary?.id ?? 0, // 신규는 0, 수정은 기존 ID
        // title: title,
        date: dateOnly,
        content: content,
        categoryId: _selectedCategoryId ?? 1,
        tagIds: finalTagIds,
      );

      await _diaryRepository.init();
      if (widget.isEdit) {
        _diaryRepository.updateDiary(newDiary);
        widget.onEdit!();
      } else {
        // _diaryRepository.addDiary(newDiary);
        await widget.onSave!(newDiary);
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // 수정된 다이어리를 결과로 반환하며 화면 닫기
        Navigator.pop(context, newDiary);
        setState(() {});
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

  void deleteDiary(int id) async {
    await _diaryRepository.init();
    await _diaryRepository.deleteDiary(id);
    Navigator.pop(context);
    Navigator.pop(context);
    widget.onDelete!();
    Fluttertoast.showToast(
      msg: '다이어리가 삭제되었습니다.',
      toastLength: Toast.LENGTH_LONG, // 더 긴 시간 표시
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3, // iOS와 웹에서 3초 동안 표시
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  void deleteDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('다이어리르 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () => deleteDiary(id),
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

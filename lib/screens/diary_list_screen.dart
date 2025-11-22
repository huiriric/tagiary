import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mrplando/diary/diary_editor.dart';
import 'package:mrplando/tables/diary/diary_item.dart';
import 'package:mrplando/tables/diary/tag_manager.dart';

class DiaryListScreen extends StatefulWidget {
  final List<DiaryItem> diaries;
  final TagManager tagManager;
  final String title;
  final Function()? onUpdate;
  final int? filterCategoryId; // 카테고리 필터링용
  final DateTime? filterDate; // 날짜 필터링용

  const DiaryListScreen({
    super.key,
    required this.diaries,
    required this.tagManager,
    required this.title,
    this.onUpdate,
    this.filterCategoryId,
    this.filterDate,
  });

  @override
  State<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen> {
  late DiaryRepository _diaryRepository;
  late List<DiaryItem> _diaries;

  @override
  void initState() {
    super.initState();
    _diaries = widget.diaries;
    _initRepository();
  }

  Future<void> _initRepository() async {
    _diaryRepository = DiaryRepository();
    await _diaryRepository.init();
  }

  void _refreshDiaries() {
    if (widget.onUpdate != null) {
      widget.onUpdate!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _diaries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '기록이 없습니다',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _diaries.length,
              itemBuilder: (context, index) {
                final diary = _diaries[index];
                return _buildDiaryCard(diary);
              },
            ),
    );
  }

  Widget _buildDiaryCard(DiaryItem diary) {
    final dateFormat = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR');
    final tagInfos = widget.tagManager.getTagInfoList(diary.tagIds);
    final categoryInfo = widget.tagManager.groupRepository.getGroup(diary.categoryId!);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => _editDiary(context, diary),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 날짜와 카테고리
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(diary.date),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Chip(
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    label: Text(
                      categoryInfo!.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Color(categoryInfo.colorValue),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 내용
              Text(
                diary.content,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // 태그
              if (tagInfos.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tagInfos
                      .map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            tag.name,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _editDiary(BuildContext context, DiaryItem diary) async {
    final editRoute = MaterialPageRoute<DiaryItem>(
      builder: (context) => DiaryEditorPage(
        diary: diary,
        date: diary.date,
        tagManager: widget.tagManager,
        isEdit: true,
        onEdit: () {
          _refreshDiaries();
          setState(() {
            // 리스트 갱신
          });
        },
        onDelete: () {
          _refreshDiaries();
          setState(() {
            _diaries.removeWhere((d) => d.id == diary.id);
          });
        },
      ),
    );

    final result = await Navigator.push<DiaryItem>(context, editRoute);

    if (result != null && mounted) {
      setState(() {
        final index = _diaries.indexWhere((d) => d.id == result.id);
        if (index != -1) {
          // 카테고리 필터링 화면인 경우: 카테고리가 변경되면 리스트에서 제거
          if (widget.filterCategoryId != null && result.categoryId != widget.filterCategoryId) {
            _diaries.removeAt(index);
          }
          // 날짜 필터링 화면인 경우: 날짜가 변경되면 리스트에서 제거
          else if (widget.filterDate != null &&
              (result.date.year != widget.filterDate!.year ||
                  result.date.month != widget.filterDate!.month ||
                  result.date.day != widget.filterDate!.day)) {
            _diaries.removeAt(index);
          }
          // 필터 조건을 만족하면 업데이트
          else {
            _diaries[index] = result;
          }
        }
      });
    }
  }
}

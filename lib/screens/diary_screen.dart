import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:tagiary/diary_widget/diary_editor.dart';
import 'package:tagiary/diary_widget/diary_detail.dart';
import 'package:tagiary/tables/diary/diary_item.dart';
import 'package:tagiary/tables/diary/tag.dart';
import 'package:tagiary/tables/diary/tag_group.dart';
import 'package:tagiary/tables/diary/tag_manager.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({Key? key}) : super(key: key);

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late DiaryRepository _diaryRepository;
  late TagManager _tagManager;
  late DateTime _selectedDate;
  final DateFormat _monthFormat = DateFormat('yyyy년 MM월');
  List<DiaryItem> _diaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // 다이어리 리포지토리 초기화
      _diaryRepository = DiaryRepository();
      await _diaryRepository.init();
      
      // 태그 관련 리포지토리 초기화
      final tagRepository = TagRepository();
      final tagGroupRepository = TagGroupRepository();
      
      _tagManager = TagManager(
        tagRepository: tagRepository,
        groupRepository: tagGroupRepository,
      );
      await _tagManager.init();
      
      // 다이어리 데이터 로드
      await _loadDiariesForMonth(_selectedDate);
    } catch (e) {
      print('DiaryScreen - 초기화 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDiariesForMonth(DateTime date) async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 모든 다이어리 가져오기
      final allDiaries = _diaryRepository.getAllItems();
      
      // 선택된 달의 다이어리만 필터링
      final filteredDiaries = allDiaries.where((diary) {
        return diary.date.year == date.year && diary.date.month == date.month;
      }).toList();
      
      // 날짜 내림차순으로 정렬 (최신순)
      filteredDiaries.sort((a, b) => b.date.compareTo(a.date));
      
      setState(() {
        _diaries = filteredDiaries;
        _isLoading = false;
      });
    } catch (e) {
      print('DiaryScreen - 다이어리 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _goToPreviousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
      _loadDiariesForMonth(_selectedDate);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
      _loadDiariesForMonth(_selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '다이어리',
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
        onPressed: () => _addNewDiary(context),
      ),
      body: Column(
        children: [
          // 월 선택기
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _goToPreviousMonth,
                ),
                Text(
                  _monthFormat.format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _goToNextMonth,
                ),
              ],
            ),
          ),
          
          // 다이어리 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _diaries.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: _diaries.length,
                        itemBuilder: (context, index) {
                          final diary = _diaries[index];
                          return _buildDiaryCard(diary);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            '${_monthFormat.format(_selectedDate)}에 작성된 다이어리가 없습니다',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _addNewDiary(context),
            child: const Text('새 다이어리 작성하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryCard(DiaryItem diary) {
    final dateFormat = DateFormat('M월 d일 (E)', 'ko_KR');
    final tagInfos = _tagManager.getTagInfoList(diary.tagIds);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => _showDiaryDetail(context, diary),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 날짜
              Text(
                dateFormat.format(diary.date),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              
              // 제목
              Text(
                diary.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // 내용 미리보기
              Text(
                diary.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // 태그
              if (tagInfos.isNotEmpty)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: tagInfos.map((tag) {
                    return Chip(
                      label: Text(
                        tag.name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: tag.color,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDiaryDetail(BuildContext context, DiaryItem diary) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryDetailPage(
          diary: diary,
          tagManager: _tagManager,
          onEdit: () {
            _loadDiariesForMonth(_selectedDate);
          },
          onDelete: () {
            _diaryRepository.deleteDiary(diary.id);
            _loadDiariesForMonth(_selectedDate);
          },
        ),
      ),
    );
  }

  void _addNewDiary(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEditorPage(
          date: DateTime.now(),
          diary: null,
          tagManager: _tagManager,
          onSave: (DiaryItem diary) async {
            await _diaryRepository.addDiary(diary);
            _loadDiariesForMonth(_selectedDate);
          },
        ),
      ),
    );
  }
}
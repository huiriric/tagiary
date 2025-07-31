import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:tagiary/component/slide_up_container.dart';
import 'package:tagiary/constants/colors.dart';
import 'package:tagiary/diary/diary_editor.dart';
import 'package:tagiary/diary/diary_detail.dart';
import 'package:tagiary/tables/diary/diary_item.dart';
import 'package:tagiary/tables/diary/tag.dart';
import 'package:tagiary/tables/diary/tag_group.dart';
import 'package:tagiary/tables/diary/tag_manager.dart';

class DiaryWidget extends StatefulWidget {
  final DateTime date;

  const DiaryWidget({
    super.key,
    required this.date,
  });

  @override
  State<DiaryWidget> createState() => _DiaryWidgetState();
}

class _DiaryWidgetState extends State<DiaryWidget> {
  late DiaryRepository _diaryRepository;
  late TagManager _tagManager;
  DiaryItem? _todayDiary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 비동기 초기화 즉시 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setupRepositories();
      }
    });
  }

  @override
  void didUpdateWidget(DiaryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 날짜가 변경되었을 때만 데이터 다시 로드
    if (oldWidget.date.year != widget.date.year || oldWidget.date.month != widget.date.month || oldWidget.date.day != widget.date.day) {
      print('DiaryWidget - didUpdateWidget 날짜 변경 감지: ${oldWidget.date} -> ${widget.date}');
      // 즉시 다이어리 로딩 실행
      _loadDiary();
    }
  }

  Future<void> _setupRepositories() async {
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

      // 모든 리포지토리 초기화 후 다이어리 로드
      await _loadDiary();
    } catch (e) {
      print('DiaryWidget - 리포지토리 초기화 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDiary() async {
    // 이미 ui가 해제된 경우 실행하지 않음
    if (!mounted) return;

    // 로딩 상태 활성화
    setState(() {
      _isLoading = true;
    });

    print('DiaryWidget - 다이어리 로드 시작: ${widget.date}');

    try {
      // 날짜 정보를 년, 월, 일만 포함하도록 변환 (시간 정보 제거)
      final dateOnly = DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
      );

      // 다이어리 리포지토리 초기화 확인
      await _diaryRepository.init();

      // 해당 날짜의 다이어리 데이터 조회
      final diaries = _diaryRepository.getDateItem(dateOnly);

      // UI가 아직 유효하면 상태 업데이트
      if (mounted) {
        setState(() {
          _todayDiary = (diaries != null && diaries.isNotEmpty) ? diaries.first : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DiaryWidget - 다이어리 로드 오류: $e');

      // 오류 발생해도 로딩 상태는 해제
      if (mounted) {
        setState(() {
          _isLoading = false;
          _todayDiary = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      elevation: 1,
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 부분
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '다이어리',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  InkWell(
                    onTap: () => _addNewDiary(context),
                    borderRadius: BorderRadius.circular(12),
                    child: const Icon(
                      Icons.add,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(),
            ),
            // 내용 부분
            Expanded(
              child: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_todayDiary == null) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(
              //   _todayDiary!.title,
              //   style: const TextStyle(
              //     fontSize: 13,
              //     fontWeight: FontWeight.w600,
              //   ),
              //   maxLines: 1,
              //   overflow: TextOverflow.ellipsis,
              // ),
              // const SizedBox(height: 4),
              // 내용 미리보기
              Text(
                _todayDiary!.content,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 태그 표시
        Expanded(
          child: _buildTagChips(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 36,
              color: Colors.grey[400],
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              '오늘의 기록이 없습니다',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            TextButton(
              onPressed: () => _addNewDiary(context),
              child: const Text('작성하기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChips() {
    if (_todayDiary == null || _todayDiary!.tagIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final tagInfos = _tagManager.getTagInfoList(_todayDiary!.tagIds);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const Padding(padding: EdgeInsets.only(left: 16)),
          ...tagInfos.map((tag) {
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Chip(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                side: BorderSide.none,
                label: Text(
                  tag.name,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Colors.white,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            );
          }),
          const Padding(padding: EdgeInsets.only(left: 12))
        ],
      ),
    );
  }

  void _handleTap(BuildContext context) {
    if (_todayDiary != null) {
      _showDiaryDetail(context);
    } else {
      _addNewDiary(context);
    }
  }

  void _showDiaryDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEditorPage(
          diary: _todayDiary!,
          date: _todayDiary!.date,
          tagManager: _tagManager,
          isEdit: true,
          onEdit: () {
            _loadDiary();
          },
          onDelete: () {
            _loadDiary();
          },
        ),
      ),
    );
  }

  void _addNewDiary(BuildContext context) {
    // 날짜 정보를 년, 월, 일만 포함하도록 설정
    final dateOnly = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEditorPage(
          date: dateOnly,
          diary: null, // 새 다이어리
          tagManager: _tagManager,
          isEdit: false,
          onSave: (DiaryItem diary) async {
            await _diaryRepository.addDiary(diary);
            _loadDiary();
          },
        ),
      ),
    );
  }
}

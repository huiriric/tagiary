import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mrplando/features/diary/screens/diary_category_management_page.dart';
import 'package:mrplando/features/diary/widgets/diary_editor.dart';
import 'package:mrplando/features/diary/screens/diary_list_screen.dart';
import 'package:mrplando/features/diary/models/diary_item.dart';
import 'package:mrplando/features/diary/models/tag.dart';
import 'package:mrplando/features/diary/models/tag_group.dart';
import 'package:mrplando/features/diary/models/tag_manager.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

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
  List<DateTime> _daysInMonth = [];
  Map<int, List<Color>> _categoryColorsByDate = {};
  OverlayEntry? _tooltipOverlay;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _calculateMonthDays();
    _initializeData();
  }

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
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
      // 선택된 달의 다이어리만 직접 가져오기 (필터링 및 정렬 포함)
      final monthDiaries = _diaryRepository.getItemsByMonth(date);
      // 날짜별 카테고리 색상 가져오기
      final colorsByDate = _diaryRepository.getCategoryColorsByDate(date, _tagManager.groupRepository);
      setState(() {
        _diaries = monthDiaries;
        _categoryColorsByDate = colorsByDate;
        // _diaries.map((d) => print('로드된 다이어리: ${d.id}, ${d.tagIds}')).toList();
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
      _calculateMonthDays();
      _loadDiariesForMonth(_selectedDate);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
      _calculateMonthDays();
      _loadDiariesForMonth(_selectedDate);
    });
  }

  void _calculateMonthDays() {
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

    final firstWeekday = firstDayOfMonth.weekday % 7; // 0(일)~6(토)
    final daysInPreviousMonth = firstWeekday;

    List<DateTime> days = [];

    // 이전 달의 날짜들
    for (int i = daysInPreviousMonth; i > 0; i--) {
      days.add(firstDayOfMonth.subtract(Duration(days: i)));
    }

    // 현재 달의 날짜들
    for (int i = 1; i <= lastDayOfMonth.day; i++) {
      days.add(DateTime(_selectedDate.year, _selectedDate.month, i));
    }

    // 다음 달의 날짜들 (6주 달력을 만들기 위해)
    final remainingDays = 42 - days.length;
    for (int i = 1; i <= remainingDays; i++) {
      days.add(lastDayOfMonth.add(Duration(days: i)));
    }

    setState(() {
      _daysInMonth = days;
    });
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _hasDiary(DateTime date) {
    return _diaries.any((diary) => diary.date.year == date.year && diary.date.month == date.month && diary.date.day == date.day);
  }

  // 카테고리별 일기 개수 계산
  Map<int, int> _getCategoryCount() {
    Map<int, int> categoryCount = {};
    for (var diary in _diaries) {
      if (diary.categoryId != null) {
        categoryCount[diary.categoryId!] = (categoryCount[diary.categoryId!] ?? 0) + 1;
      }
    }
    return categoryCount;
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
      body: SizedBox(
        child: Column(
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      height: 150,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _diaries.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  reverse: true,
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  itemCount: _diaries.length,
                                  itemBuilder: (context, index) {
                                    final diary = _diaries[index];
                                    return _buildDiaryCard(diary);
                                  },
                                ),
                    ),
                    // 카테고리 비율 막대
                    if (!_isLoading && _diaries.isNotEmpty) _buildCategoryBar(),
                    // 캘린더
                    _buildDiaryCalendar(),
                  ],
                ),
              ),
            )
            // 다이어리 목록
          ],
        ),
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
            size: 48,
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

  Widget _buildCategoryBar() {
    final categoryCount = _getCategoryCount();
    if (categoryCount.isEmpty) return const SizedBox.shrink();

    final totalCount = categoryCount.values.reduce((a, b) => a + b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '카테고리별 기록',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              // 카테고리 관리 버튼
              IconButton(
                icon: const Icon(Icons.settings, size: 18, color: Colors.black54),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DiaryCategoryManagementPage(
                        tagManager: _tagManager,
                      ),
                    ),
                  );
                  setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: categoryCount.entries.map((entry) {
                  final categoryId = entry.key;
                  final count = entry.value;
                  final percentage = count / totalCount;
                  final category = _tagManager.groupRepository.getGroup(categoryId);

                  return Expanded(
                    flex: (percentage * 100).round(),
                    child: GestureDetector(
                      onLongPressStart: (details) {
                        // 카테고리 정보 툴팁 표시
                        _showCategoryTooltip(context, details.globalPosition, category, count, percentage);
                      },
                      onLongPressEnd: (details) {
                        // 툴팁 숨기기
                        _hideTooltip();
                      },
                      onTap: () {
                        // 해당 달 카테고리에 대한 다이어리 필터링 화면으로 이동
                        _showCategoryDiaries(context, categoryId, category?.name ?? '없음', _selectedDate.month);
                      },
                      child: Container(
                        color: category != null ? Color(category.colorValue) : Colors.grey,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: categoryCount.entries.map((entry) {
              final categoryId = entry.key;
              final count = entry.value;
              final percentage = (count / totalCount * 100).round();
              final category = _tagManager.groupRepository.getGroup(categoryId);

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: category != null ? Color(category.colorValue) : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${category?.name ?? '없음'} $count개 ($percentage%)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryCard(DiaryItem diary) {
    final dateFormat = DateFormat('d일 (E)', 'ko_KR');
    final tagInfos = _tagManager.getTagInfoList(diary.tagIds);
    final categoryInfo = _tagManager.groupRepository.getGroup(diary.categoryId!);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 2,
        child: InkWell(
          onTap: () => _editDiary(context, diary),
          child: SizedBox(
            width: 210,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜
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
                  const SizedBox(height: 8),

                  // 내용 미리보기
                  Text(
                    diary.content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // 태그
                  // if (tagInfos.isNotEmpty)
                  //   Wrap(
                  //     spacing: 4,
                  //     runSpacing: 4,
                  //     children: tagInfos
                  //         .map((tag) {
                  //           return Container(
                  //             height: 32,
                  //             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  //             decoration: BoxDecoration(
                  //               color: Colors.white,
                  //               borderRadius: BorderRadius.circular(16),
                  //               border: Border.all(color: Colors.grey[300]!),
                  //             ),
                  //             child: Row(
                  //               mainAxisSize: MainAxisSize.min,
                  //               children: [
                  //                 Text(
                  //                   tag.name,
                  //                   style: const TextStyle(
                  //                     fontSize: 14,
                  //                     color: Colors.black87,
                  //                   ),
                  //                 ),
                  //               ],
                  //             ),
                  //           );
                  //         })
                  //         .take(2)
                  //         .toList(),
                  //   ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiaryCalendar() {
    final List<String> weekdays = ['일', '월', '화', '수', '목', '금', '토'];

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      color: Colors.white,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 요일 헤더
            Row(
              children: weekdays
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: day == '일' ? Colors.red : (day == '토' ? Colors.blue : Colors.black87),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),

            // 달력 그리드
            SizedBox(
              height: 300,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: _daysInMonth.length,
                itemBuilder: (context, index) {
                  final date = _daysInMonth[index];
                  final isCurrentMonth = date.month == _selectedDate.month;
                  final isToday = _isToday(date);
                  final hasDiary = _hasDiary(date);
                  final dayColors = _categoryColorsByDate[date.day] ?? [];

                  return GestureDetector(
                    onTap: () {
                      if (hasDiary) {
                        // 해당 날짜의 다이어리들 가져오기
                        final dateDiaries = _diaries.where((d) => d.date.year == date.year && d.date.month == date.month && d.date.day == date.day).toList();
                        if (dateDiaries.length > 1) {
                          // 기록이 2개 이상이면 리스트 화면으로 이동
                          _showDateDiaries(context, date);
                        } else {
                          // 기록이 1개면 바로 편집
                          _editDiary(context, dateDiaries.first);
                        }
                      } else {
                        // 없으면 새 다이어리 작성
                        _addNewDiaryForDate(context, date);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        border: isToday ? Border.all(color: Theme.of(context).primaryColor, width: 2) : null,
                      ),
                      child: Stack(
                        children: [
                          // 배경 색상 (카테고리별) - 현재 달만 표시
                          if (isCurrentMonth && dayColors.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Column(
                                children: dayColors
                                    .map((color) => Expanded(
                                          child: Container(
                                            color: color.withAlpha(100),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          // 날짜 텍스트
                          Center(
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                fontWeight: isToday || hasDiary ? FontWeight.bold : FontWeight.normal,
                                color: !isCurrentMonth
                                    ? Colors.grey.shade400
                                    : isToday
                                        ? Theme.of(context).primaryColor
                                        : date.weekday == 7 // 일요일
                                            ? Colors.red
                                            : date.weekday == 6 // 토요일
                                                ? Colors.blue
                                                : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewDiary(BuildContext context) {
    _addNewDiaryForDate(context, DateTime.now());
  }

  void _addNewDiaryForDate(BuildContext context, DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEditorPage(
          date: date,
          diary: null,
          tagManager: _tagManager,
          isEdit: false,
          onSave: (DiaryItem diary) async {
            await _diaryRepository.addDiary(diary);
            _loadDiariesForMonth(_selectedDate);
            setState(() {});
          },
        ),
      ),
    );
  }

  void _editDiary(BuildContext context, DiaryItem diary) async {
    // 다이어리 에디터 페이지를 MaterialPageRoute로 직접 생성
    final editRoute = MaterialPageRoute<DiaryItem>(
      builder: (context) => DiaryEditorPage(
        diary: diary,
        date: diary.date,
        tagManager: _tagManager,
        isEdit: true,
        onEdit: () => setState(() {
          _loadDiariesForMonth(_selectedDate);
        }),
        // onSave: (updatedDiary) async {
        //   // 다이어리 저장 로직
        //   final repo = DiaryRepository();
        //   await repo.init();
        //   await repo.updateDiary(updatedDiary);
        //   setState(() {});
        // },
        onDelete: () => setState(() {
          _loadDiariesForMonth(_selectedDate);
        }),
      ),
    );

    // 에디터 페이지로 이동하고 결과를 기다림
    final result = await Navigator.push<DiaryItem>(context, editRoute);

    // 수정된 다이어리가 있으면 상태 업데이트
    if (result != null && mounted) {
      setState(() {
        diary = result;
      });
    }
  }

  void _showCategoryTooltip(BuildContext context, Offset position, TagGroup? category, int count, double percentage) {
    _hideTooltip(); // 기존 툴팁이 있으면 제거

    final percentageText = (percentage * 100).round();
    final overlay = Overlay.of(context);

    _tooltipOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - 40,
        top: position.dy - 30,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: category != null ? Color(category.colorValue) : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${category?.name ?? '없음'} $count개',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(_tooltipOverlay!);
  }

  void _hideTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  void _showCategoryDiaries(BuildContext context, int categoryId, String categoryName, int month) {
    final categoryDiaries = _diaries.where((d) => d.categoryId == categoryId).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryListScreen(
          diaries: categoryDiaries,
          tagManager: _tagManager,
          title: '$month월 $categoryName 기록',
          filterCategoryId: categoryId,
          onUpdate: () => _loadDiariesForMonth(_selectedDate),
        ),
      ),
    );
  }

  void _showDateDiaries(BuildContext context, DateTime date) {
    final dateDiaries = _diaries.where((d) => d.date.year == date.year && d.date.month == date.month && d.date.day == date.day).toList();

    final dateFormat = DateFormat('M월 d일 (E)', 'ko_KR');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryListScreen(
          diaries: dateDiaries,
          tagManager: _tagManager,
          title: '${dateFormat.format(date)} 기록',
          filterDate: date,
          onUpdate: () => _loadDiariesForMonth(_selectedDate),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mrplando/shared/models/category_manager_interface.dart';
import 'package:provider/provider.dart';
import 'package:mrplando/shared/widgets/slide_up_container.dart';
import 'package:mrplando/core/providers/provider.dart';
import 'package:mrplando/features/schedule/models/schedule_category.dart';
import 'package:mrplando/features/schedule/models/schedule_category_manager.dart';
import 'package:mrplando/features/schedule/widgets/time_line.dart';
import 'package:mrplando/features/schedule/widgets/add_schedule.dart';
import 'package:mrplando/features/home/screens/home_screen.dart';
import 'package:mrplando/features/schedule/widgets/week_view.dart';
import 'package:mrplando/features/schedule/widgets/month_view.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  List<String> week = ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'];
  late DateTime date;
  late ScheduleCategoryManager _categoryManager;
  List<CategoryInfo> _categories = [];
  int? _selectedCategoryId; // 선택된 카테고리 ID

  // TimeLine 위젯을 강제 새로고침하기 위한 키
  Key _timelineKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    date = DateTime.now();
    _categoryManager = ScheduleCategoryManager(
      categoryRepository: ScheduleCategoryRepository(),
    );
    _loadCategories();
    _loadEvents();
    // DataProvider 초기화 (필요 시)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DataProvider>(context, listen: false).updateDate(date);

      // 설정 로드 (이미 loadTimelineSettings가 호출되었을 수 있음)
      Provider.of<DataProvider>(context, listen: false).loadTimelineSettings();
    });
  }

  Future<void> _loadCategories() async {
    await _categoryManager.init();
    setState(() {
      _categories = _categoryManager.getAllCategories();
    });
  }

  Future<void> _loadEvents() async {
    // TimeLine 위젯 강제 새로고침을 위해 새로운 키 생성
    setState(() {
      _timelineKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    // DataProvider에서 날짜 변경이 있는지 확인
    final provider = Provider.of<DataProvider>(context);
    if (date != provider.selectedDate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          date = provider.selectedDate;
        });
      });
    }

    // 현재 뷰 모드
    final currentViewMode = provider.viewMode;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () async {
            final selectedDate = await showBlackWhiteDatePicker(
              context: context,
              initialDate: date,
            );
            if (selectedDate != null) {
              setState(() {
                provider.updateDate(selectedDate);
                date = provider.selectedDate;
                _timelineKey = UniqueKey(); // 날짜 변경 시에도 새로운 키 생성
              });
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${date.month}월 ${date.day}일',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    week[date.weekday % 7],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  )
                ],
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_categories.isNotEmpty ? 56 : 0),
          child: _categories.isNotEmpty
              ? Container(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // 전체 카테고리
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('전체'),
                          selected: _selectedCategoryId == null,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategoryId = null;
                              _timelineKey = UniqueKey(); // 필터 변경 시 위젯 새로고침
                            });
                          },
                          selectedColor: Colors.blue.shade100,
                          backgroundColor: Colors.grey.shade200,
                          labelStyle: TextStyle(
                            color: _selectedCategoryId == null ? Colors.blue.shade700 : Colors.grey.shade700,
                            fontWeight: _selectedCategoryId == null ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: _selectedCategoryId == null ? Colors.blue.shade300 : Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      // 각 카테고리
                      ..._categories.map((category) {
                        final isSelected = _selectedCategoryId == category.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: category.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(category.name),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategoryId = category.id;
                                _timelineKey = UniqueKey(); // 필터 변경 시 위젯 새로고침
                              });
                            },
                            selectedColor: category.color.withOpacity(0.2),
                            backgroundColor: Colors.grey.shade200,
                            labelStyle: TextStyle(
                              color: isSelected ? category.color : Colors.grey.shade700,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? category.color : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        actions: [
          // 선택된 날짜가 오늘인 경우 비활성화
          if (date.year != DateTime.now().year || date.month != DateTime.now().month || date.day != DateTime.now().day)
            TextButton(
                onPressed: () {
                  // 오늘 날짜로 이동
                  final today = DateTime.now();
                  provider.updateDate(today);
                  setState(() {
                    date = provider.selectedDate;
                    _timelineKey = UniqueKey(); // 날짜 변경 시에도 새로운 키 생성
                  });
                },
                child: const Text(
                  'today',
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -1),
                )),
          // 뷰 모드 전환 드롭다운 버튼
          PopupMenuButton<TimelineViewMode>(
            icon: Icon(
              _getViewModeIcon(provider.viewMode),
              color: Colors.black,
            ),
            onSelected: (TimelineViewMode mode) {
              // 선택된 뷰 모드 저장
              _loadEvents();
              provider.setViewMode(mode);
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<TimelineViewMode>(
                value: TimelineViewMode.day,
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_day, size: 20),
                    SizedBox(width: 8),
                    Text('일간'),
                  ],
                ),
              ),
              const PopupMenuItem<TimelineViewMode>(
                value: TimelineViewMode.week,
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_week, size: 20),
                    SizedBox(width: 8),
                    Text('주간'),
                  ],
                ),
              ),
              const PopupMenuItem<TimelineViewMode>(
                value: TimelineViewMode.month,
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, size: 20),
                    SizedBox(width: 8),
                    Text('월간'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Color(0xBB000000)),
        onPressed: () async {
          final result = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            builder: (context) => AnimatedPadding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              duration: const Duration(milliseconds: 0),
              curve: Curves.decelerate,
              child: SingleChildScrollView(
                child: SlideUpContainer(
                  child: AddSchedule(
                    date: date,
                    start: TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: 0),
                    end: TimeOfDay(hour: TimeOfDay.now().hour + 2, minute: 0),
                    onScheduleAdded: () => _loadEvents,
                    categories: _categories,
                  ),
                ),
              ),
            ),
          );

          if (result == true) {
            // 일정이 추가되었다면 UI 새로고침
            await _loadEvents();
          }
        },
      ),
      body: _buildTimelineView(provider.viewMode),
    );
  }

  Widget _buildTimelineView(TimelineViewMode viewMode) {
    switch (viewMode) {
      case TimelineViewMode.day:
        return TimeLine(
          key: _timelineKey,
          fromScreen: true,
          date: date,
          selectedCategoryId: _selectedCategoryId,
          categories: _categories,
        );
      case TimelineViewMode.week:
        return WeekView(
          key: _timelineKey,
          selectedDate: date,
          selectedCategoryId: _selectedCategoryId,
          categories: _categories,
        );
      case TimelineViewMode.month:
        return MonthView(
          key: _timelineKey,
          selectedDate: date,
          selectedCategoryId: _selectedCategoryId,
          categories: _categories,
        );
    }
  }

  IconData _getViewModeIcon(TimelineViewMode viewMode) {
    switch (viewMode) {
      case TimelineViewMode.day:
        return Icons.calendar_view_day;
      case TimelineViewMode.week:
        return Icons.calendar_view_week;
      case TimelineViewMode.month:
        return Icons.calendar_month;
    }
  }
}

// showBlackWhiteDatePicker 함수는 HomeScreen에서 사용

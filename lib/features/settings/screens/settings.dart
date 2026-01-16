import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mrplando/core/providers/provider.dart';
import 'package:mrplando/shared/widgets/category_management_page.dart';
import 'package:mrplando/features/todo/models/todo_category.dart';
import 'package:mrplando/features/todo/models/todo_category_manager.dart';
import 'package:mrplando/features/routine/models/routine_category.dart';
import 'package:mrplando/features/routine/models/routine_category_manager.dart';
import 'package:mrplando/features/schedule/models/schedule_category.dart';
import 'package:mrplando/features/schedule/models/schedule_category_manager.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

// timetable 시작, 종료 시간 설정
// sharedPreference 사용해서 저장하고 가져오기

class _SettingsState extends State<Settings> {
  // 타임라인 설정을 확장할지 여부
  bool _isTimelineSettingsExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            AppBar(
              toolbarHeight: 80,
              title: const Text(
                '설정',
                style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.w700),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // 설정 컨텐츠 섹션
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 확장 가능한 타임라인 설정
                      _buildExpandableTimelineSettings(),

                      // 카테고리 관리 섹션
                      _buildCategoryManagementSection(),

                      // 여기에 다른 설정 섹션들을 추가할 수 있습니다
                      // 예: 알림 설정, 테마 설정, 계정 설정 등
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 확장 가능한 타임라인 설정 위젯
  Widget _buildExpandableTimelineSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더 (항상 표시)
        InkWell(
          onTap: () {
            setState(() {
              _isTimelineSettingsExpanded = !_isTimelineSettingsExpanded;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '타임라인 설정',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Icon(
                  _isTimelineSettingsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey.shade700,
                ),
              ],
            ),
          ),
        ),

        // 확장된 내용 (펼쳐졌을 때만 표시)
        if (_isTimelineSettingsExpanded) ...[
          // 시작 시간 설정
          _buildTimelineSetting(
            title: '시작 시간',
            subtitle: '타임라인의 시작 시간',
            currentValue: context.watch<DataProvider>().startHour,
            onTap: () => _showTimePickerDialog(
              context: context,
              title: '시작 시간 설정',
              initialValue: context.read<DataProvider>().startHour,
              minValue: 0,
              maxValue: context.read<DataProvider>().endHour - 1,
              onChanged: (value) {
                if (value < context.read<DataProvider>().endHour) {
                  context.read<DataProvider>().setStartHour(value);
                }
              },
            ),
          ),

          const SizedBox(height: 16),

          // 종료 시간 설정
          _buildTimelineSetting(
            title: '종료 시간',
            subtitle: '타임라인의 종료 시간',
            currentValue: context.watch<DataProvider>().endHour,
            onTap: () => _showTimePickerDialog(
              context: context,
              title: '종료 시간 설정',
              initialValue: context.read<DataProvider>().endHour,
              minValue: context.read<DataProvider>().startHour + 1,
              maxValue: 24,
              onChanged: (value) {
                if (value > context.read<DataProvider>().startHour) {
                  context.read<DataProvider>().setEndHour(value);
                }
              },
            ),
          ),
        ],

        // 구분선
        Divider(color: Colors.grey.shade300, height: 32),
      ],
    );
  }

  // 타임라인 설정 위젯 생성
  Widget _buildTimelineSetting({
    required String title,
    required String subtitle,
    required int currentValue,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              // 왼쪽: 텍스트 영역
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // 오른쪽: 현재값 + 화살표
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      '$currentValue:00',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Colors.grey.shade700,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 시간 설정 다이얼로그 표시
  void _showTimePickerDialog({
    required BuildContext context,
    required String title,
    required int initialValue,
    required int minValue,
    required int maxValue,
    required Function(int) onChanged,
  }) {
    int selectedValue = initialValue;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontSize: 18),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('시간을 선택하세요'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 마이너스 버튼 (더 깔끔한 아이콘)
                      IconButton(
                        iconSize: 16,
                        icon: const Icon(Icons.remove),
                        style: IconButton.styleFrom(
                          backgroundColor: selectedValue > minValue ? Colors.grey.shade200 : Colors.grey.shade100,
                        ),
                        onPressed: selectedValue > minValue
                            ? () {
                                setState(() {
                                  selectedValue--;
                                });
                              }
                            : null,
                      ),
                      const SizedBox(width: 10),
                      // 선택된 시간 표시
                      Container(
                        width: 80,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$selectedValue:00',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 플러스 버튼 (더 깔끔한 아이콘)
                      IconButton(
                        iconSize: 16,
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(
                          backgroundColor: selectedValue < maxValue ? Colors.grey.shade200 : Colors.grey.shade100,
                        ),
                        onPressed: selectedValue < maxValue
                            ? () {
                                setState(() {
                                  selectedValue++;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                onChanged(selectedValue);
                Navigator.pop(context);
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  // 카테고리 관리 섹션
  Widget _buildCategoryManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '카테고리 관리',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // 할 일 카테고리 관리
        _buildCategoryManagementItem(
          title: '할 일 카테고리',
          icon: Icons.check_circle_outline,
          color: Colors.blue,
          onTap: () {
            final todoCategoryManager = TodoCategoryManager(
              categoryRepository: TodoCategoryRepository(),
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategoryManagementPage(
                  categoryManager: todoCategoryManager,
                  title: '할 일 카테고리',
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // 루틴 카테고리 관리
        _buildCategoryManagementItem(
          title: '루틴 카테고리',
          icon: Icons.loop,
          color: Colors.green,
          onTap: () {
            final routineCategoryManager = RoutineCategoryManager(
              categoryRepository: RoutineCategoryRepository(),
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategoryManagementPage(
                  categoryManager: routineCategoryManager,
                  title: '루틴 카테고리',
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // 일정 카테고리 관리
        _buildCategoryManagementItem(
          title: '일정 카테고리',
          icon: Icons.event_note,
          color: Colors.orange,
          onTap: () {
            final scheduleCategoryManager = ScheduleCategoryManager(
              categoryRepository: ScheduleCategoryRepository(),
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategoryManagementPage(
                  categoryManager: scheduleCategoryManager,
                  title: '일정 카테고리',
                ),
              ),
            );
          },
        ),

        // 구분선
        Divider(color: Colors.grey.shade300, height: 32),
      ],
    );
  }

  // 카테고리 관리 항목 위젯
  Widget _buildCategoryManagementItem({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              // 아이콘
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // 텍스트
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),

              // 화살표
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

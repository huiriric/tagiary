import 'package:flutter/material.dart';
import 'package:mrplando/shared/widgets/slide_up_container.dart';
import 'package:mrplando/features/schedule/models/schedule_item.dart';
import 'package:mrplando/features/schedule/models/schedule_routine_item.dart';
import 'package:mrplando/features/schedule/widgets/time_line.dart';
import 'package:mrplando/features/schedule/widgets/add_schedule.dart';
import 'package:mrplando/features/todo/widgets/todo_widget.dart';
import 'package:mrplando/features/routine/widgets/routine_widget.dart';
import 'package:mrplando/features/diary/widgets/diary_widget.dart';
import 'package:mrplando/features/settings/screens/settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> week = ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'];
  late DateTime date;

  // TimeLine 위젯을 강제 새로고침하기 위한 키
  Key _timelineKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    date = DateTime.now();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _loadEventsForDate();
  }

  Future<void> _loadEventsForDate() async {
    // TimeLine 위젯 강제 새로고침을 위해 새로운 키 생성
    setState(() {
      _timelineKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    const double padding = 12.0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'images/mrPlando.png',
              width: 30,
            ),
            const Padding(padding: EdgeInsets.only(left: 2)),
            const Text(
              'Mr.Plando',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              final selectedDate = await showBlackWhiteDatePicker(context: context, initialDate: date);
              if (selectedDate != null) {
                setState(() {
                  date = selectedDate;
                  _timelineKey = UniqueKey(); // 날짜 변경 시에도 새로운 키 생성
                });
              }
            },
            icon: const Icon(Icons.calendar_today_rounded, color: Colors.black),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const Settings(),
            )),
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
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
                    onScheduleAdded: () async {
                      await _loadEventsForDate();
                      setState(() {});
                    },
                  ),
                ),
              ),
            ),
          );

          // 일정이 추가되었다면 UI 새로고침
          if (result == true) {
            await _loadEventsForDate();
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      backgroundColor: const Color(0xFFFAFAF8),
      body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // 날짜 표시
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${date.month}월 ${date.day}일',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        week[date.weekday % 7],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      )
                    ],
                  ),
                ),
                //앱바 아래 화면
                Expanded(
                    child: Row(
                  children: [
                    Expanded(
                      child: TimeLine(
                        key: _timelineKey, // 동적 키로 변경하여 강제 새로고침
                        fromScreen: false,
                        date: date,
                        onEventsLoaded: () {
                          setState(() {
                            date = date;
                          });
                        }, // 이벤트가 로드된 후 상태 업데이트
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SafeArea(
                        left: false,
                        right: false,
                        child: Column(
                          children: [
                            Expanded(
                              child: TodoRoutineWidget(
                                date: date,
                                fromMain: true,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Expanded(
                              child: TodoWidget(),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: DiaryWidget(
                                key: ValueKey<DateTime>(
                                    DateTime(date.year, date.month, date.day)), // 시간을 제외한 날짜만으로 키를 생성
                                date: date,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ))
              ],
            ),
          )),
    );
  }
}

// 흑백 테마 날짜 선택기
Future<DateTime?> showBlackWhiteDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  // 기본값 설정
  initialDate ??= DateTime.now();
  firstDate ??= DateTime(2000);
  lastDate ??= DateTime(2100);

  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    locale: const Locale('ko', 'KR'),
    builder: (context, child) {
      return Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF6750A4), // Material 3 primary color
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF1C1B1F),
            surfaceContainerHighest: Color(0xFFF3EDF7),
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: Colors.white,
            elevation: 3,
            shadowColor: Colors.black.withOpacity(0.1),
            headerBackgroundColor: const Color(0xFF6750A4),
            headerForegroundColor: Colors.white,
            headerHeadlineStyle: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
            weekdayStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
            dayStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            todayBorder: BorderSide(
              color: const Color(0xFF6750A4).withOpacity(0.6),
              width: 1.5,
            ),
            todayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return const Color(0xFF6750A4);
            }),
            todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF6750A4);
              }
              return Colors.transparent;
            }),
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              if (states.contains(WidgetState.disabled)) {
                return Colors.grey.shade300;
              }
              return const Color(0xFF1C1B1F);
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF6750A4);
              }
              if (states.contains(WidgetState.hovered)) {
                return const Color(0xFFF3EDF7);
              }
              return Colors.transparent;
            }),
            dayOverlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return const Color(0xFFF3EDF7);
              }
              if (states.contains(WidgetState.focused)) {
                return const Color(0xFFF3EDF7);
              }
              return null;
            }),
            yearStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            yearForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return const Color(0xFF1C1B1F);
            }),
            yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF6750A4);
              }
              if (states.contains(WidgetState.hovered)) {
                return const Color(0xFFF3EDF7);
              }
              return Colors.transparent;
            }),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            rangePickerElevation: 4,
            rangePickerShadowColor: Colors.black.withOpacity(0.15),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6750A4),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}

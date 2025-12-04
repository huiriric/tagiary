import 'package:flutter/material.dart';
import 'package:mrplando/component/slide_up_container.dart';
import 'package:mrplando/tables/schedule/schedule_item.dart';
import 'package:mrplando/tables/schedule_routine/schedule_routine_item.dart';
import 'package:mrplando/time_line/time_line.dart';
import 'package:mrplando/time_line/add_schedule.dart';
import 'package:mrplando/todo_widget/todo_widget.dart';
import 'package:mrplando/routine_widget/routine_widget.dart';
import 'package:mrplando/diary/diary_widget.dart';
import 'package:mrplando/settings/settings.dart';

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
                                key: ValueKey<DateTime>(DateTime(date.year, date.month, date.day)), // 시간을 제외한 날짜만으로 키를 생성
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
        data: Theme.of(context).copyWith(
          // 흑백 테마 설정
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
}

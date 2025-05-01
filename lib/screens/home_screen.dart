import 'package:flutter/material.dart';
import 'package:tagiary/component/slide_up_container.dart';
import 'package:tagiary/time_line/time_line.dart';
import 'package:tagiary/time_line/add_schedule.dart';
import 'package:tagiary/todo_widget/todo_widget.dart';
import 'package:tagiary/todo_routine_widget/todo_routine_widget.dart';
import 'package:tagiary/diary_widget/diary_widget.dart';
import 'package:tagiary/settings/settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> week = ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'];
  late DateTime date;

  @override
  void initState() {
    super.initState();
    date = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    const double padding = 12.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tagiary',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
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
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => AnimatedPadding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              duration: const Duration(milliseconds: 0),
              curve: Curves.decelerate,
              child: SingleChildScrollView(
                child: SlideUpContainer(
                  height: 450,
                  child: AddSchedule(
                    date: date,
                    start: TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: 0),
                    end: TimeOfDay(hour: TimeOfDay.now().hour + 2, minute: 0),
                  ),
                ),
              ),
            ),
          );
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
                        key: ValueKey<DateTime>(date), // 날짜가 변경될 때 위젯을 다시 생성
                        fromScreen: false,
                        date: date,
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
          dialogBackgroundColor: Colors.white,
        ),
        child: child!,
      );
    },
  );
}

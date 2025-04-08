import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tagiary/component/slide_up_container.dart';
import 'package:tagiary/time_line/add_schedule.dart';
import 'package:tagiary/time_line/time_line.dart';
import 'package:tagiary/tables/check/check_item.dart';
import 'package:tagiary/tables/check_routine/check_routine_item.dart';
import 'package:tagiary/tables/check_routine/routine_history.dart';
import 'package:tagiary/tables/data_models/event.dart';
import 'package:tagiary/settings/settings.dart';
import 'package:tagiary/tables/schedule/schedule_item.dart';
import 'package:tagiary/tables/schedule_routine/schedule_routine_item.dart';
import 'package:tagiary/todo_widget/todo_widget.dart';
import 'package:tagiary/todo_routine_widget/todo_routine_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive 초기화
  await Hive.initFlutter();

  // 개발 중에만 사용하세요 - 모든 데이터가 삭제됩니다
  // await Hive.deleteFromDisk();

  // DateTime 어댑터 등록 (내장되어 있음)
  // Hive.registerAdapter(DateTimeAdapter());

  // 사용자 정의 어댑터 등록
  // 커스텀 어댑터 사용 (자동생성된 어댑터 대신)
  Hive.registerAdapter(ScheduleRoutineItemAdapter());
  Hive.registerAdapter(ScheduleItemAdapter());
  Hive.registerAdapter(CheckItemAdapter());
  Hive.registerAdapter(CheckRoutineItemAdapter());
  Hive.registerAdapter(RoutineHistoryAdapter());

  // 박스 열기
  await Hive.openBox<ScheduleItem>('scheduleBox');
  await Hive.openBox<ScheduleRoutineItem>('scheduleRoutineBox');
  await Hive.openBox<CheckItem>('checkBox');
  await Hive.openBox<CheckRoutineItem>('checkRoutineBox');
  await Hive.openBox<RoutineHistory>('routineHistoryBox');

  // ScheduleRepository scheduleRepo = ScheduleRepository();
  // ScheduleRoutineRepository scheduleRRepo = ScheduleRoutineRepository();
  // CheckRepository checkRepo = CheckRepository();
  // CheckRoutineRepository checkRRepo = CheckRoutineRepository();

  // scheduleRepo.init();
  // scheduleRRepo.init();
  // checkRepo.init();
  // checkRRepo.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        // useMaterial3: true,
        fontFamily: 'NanumSquareRound',
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'), // 한국어
        Locale('en', 'US'), // 영어
      ],
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // setState(() {
          //   addScheduleRoutine();
          // });
          showModalBottomSheet(
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
                  ),
                ),
              ),
            ),
          );
        },
      ),
      backgroundColor: const Color(0xFFFAFAF8),
      body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                //앱 바
                SizedBox(
                  height: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 날짜 표시
                      Column(
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
                      //달력
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () async {
                              final selectedDate = await showBlackWhiteDatePicker(context: context, initialDate: date);
                              if (selectedDate != null) {
                                setState(() {
                                  date = selectedDate;
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_today_rounded),
                          ),
                          //설정
                          IconButton(
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const Settings(),
                            )),
                            icon: const Icon(Icons.settings_outlined),
                          ),
                        ],
                      ),
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
                        date: date,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: TodoRoutineWidget(),
                          ),
                          SizedBox(height: 12),
                          Expanded(
                            child: TodoWidget(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ))
              ],
            ),
          )),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Future<void> addScheduleRoutine() async {
  //   final scheduleRoutineBox = Hive.box<ScheduleRoutineItem>('scheduleRoutineBox');

  //   final newItem = ScheduleRoutineItem(
  //     title: '첫 루틴',
  //     description: '첫 루틴입니다.',
  //     startHour: 13,
  //     startMinute: 0,
  //     endHour: 14,
  //     endMinute: 0,
  //     colorValue: const Color(0xFF123456).value,
  //   );

  //   ScheduleRoutineRepository repo = ScheduleRoutineRepository();
  //   await repo.init();

  //   int id = await repo.addItem(newItem);
  //   final firstSchedule = repo.getItem(id);
  //   print(firstSchedule?.key);
  //   print(firstSchedule?.title);
  //   print(firstSchedule?.description);
  //   print(firstSchedule?.startHour);
  //   print(firstSchedule?.endHour);
  // }
}

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

import 'package:flutter/material.dart';
import 'package:mrplando/services/notification_service.dart';
import 'package:mrplando/tables/check/check_enum.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:mrplando/provider.dart';
import 'package:mrplando/tables/schedule_links/schedule_link_item.dart';
import 'package:mrplando/tables/check/check_item.dart';
import 'package:mrplando/tables/check_routine/check_routine_item.dart';
import 'package:mrplando/tables/check_routine/routine_history.dart';
import 'package:mrplando/tables/schedule/schedule_item.dart';
import 'package:mrplando/tables/schedule_routine/schedule_routine_item.dart';
import 'package:mrplando/tables/diary/diary_item.dart';
import 'package:mrplando/tables/diary/tag.dart';
import 'package:mrplando/tables/diary/tag_group.dart';
import 'package:mrplando/tables/diary/tag_group_adapter.dart';
import 'package:mrplando/tables/color/color_item.dart';
import 'package:mrplando/constants/colors.dart';
import 'package:mrplando/screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화를 NotificationService로 이동
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  // Firebase 초기화 후 백그라운드 핸들러 등록
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
  //   alert: true,
  //   badge: true,
  //   sound: true,
  // );

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
  Hive.registerAdapter(CheckEnumAdapter());
  Hive.registerAdapter(CheckRoutineItemAdapter());
  Hive.registerAdapter(RoutineHistoryAdapter());
  Hive.registerAdapter(ScheduleLinkItemAdapter());
  Hive.registerAdapter(LinkItemTypeAdapter());
  Hive.registerAdapter(DiaryItemAdapter());
  Hive.registerAdapter(TagAdapter());
  Hive.registerAdapter(TagGroupAdapterWithMigration());
  Hive.registerAdapter(ColorItemAdapter());

  // 박스 열기
  await Hive.openBox<ScheduleItem>('scheduleBox');
  await Hive.openBox<ScheduleRoutineItem>('scheduleRoutineBox');
  await Hive.openBox<CheckItem>('checkBox');
  await Hive.openBox<CheckEnum>('checkEnumBox');
  await Hive.openBox<CheckRoutineItem>('checkRoutineBox');
  await Hive.openBox<RoutineHistory>('routineHistoryBox');
  await Hive.openBox<ScheduleLinkItem>('scheduleLinkBox');
  await Hive.openBox<DiaryItem>('diaryBox');
  await Hive.openBox<Tag>('tagBox');
  await Hive.openBox<TagGroup>('tagGroupBox');
  await Hive.openBox<ColorItem>('colorBox');

  // 색상 초기화
  final colorRepo = ColorRepository();
  await colorRepo.init();
  await colorRepo.initializeDefaultColors();

  // 색상 리스트 로드
  await loadScheduleColors();

  // ScheduleRepository scheduleRepo = ScheduleRepository();
  // ScheduleRoutineRepository scheduleRRepo = ScheduleRoutineRepository();
  // CheckRepository checkRepo = CheckRepository();
  // CheckRoutineRepository checkRRepo = CheckRoutineRepository();

  // scheduleRepo.init();
  // scheduleRRepo.init();
  // checkRepo.init();
  // checkRRepo.init();

  // DataProvider 초기화 및 설정 로드
  final dataProvider = DataProvider();
  await dataProvider.loadTimelineSettings();

  // 알림 서비스 초기화
  await NotificationService.initialize();

  runApp(
    ChangeNotifierProvider.value(
      value: dataProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tagiary',
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
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}

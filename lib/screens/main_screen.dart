import 'package:flutter/material.dart';
import 'package:tagiary/screens/timeline_screen.dart';
import 'package:tagiary/screens/todo_screen.dart';
import 'package:tagiary/screens/home_screen.dart';
import 'package:tagiary/screens/routine_screen.dart';
import 'package:tagiary/screens/diary_screen.dart';
import 'package:tagiary/settings/settings.dart';
import 'package:tagiary/widgets/home_widget_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 2; // 기본값을 홈으로 설정

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 모든 위젯 업데이트
    // HomeWidgetProvider.updateAllWidgets();
  }

  // 탭에 표시될 화면들
  final List<Widget> _pages = [
    const TimelineScreen(),
    const TodoScreen(),
    const HomeScreen(), // 홈 화면을 가운데에 배치
    const RoutineScreen(),
    const DiaryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 탭이 5개이므로 fixed 타입 사용
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline),
            label: '일정',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_box),
            label: '할 일',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.repeat),
            label: '루틴',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: '다이어리',
          ),
        ],
      ),
    );
  }
}

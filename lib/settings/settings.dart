import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

// timetable 시작, 종료 시간 설정
// sharedPreference 사용해서 저장하고 가져오기

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.center,
              height: 80,
              child: const Text(
                '설정',
                style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.w700),
              ),
            ),
            // 설정 목록
            const Column()
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tagiary/provider.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

// timetable 시작, 종료 시간 설정
// sharedPreference 사용해서 저장하고 가져오기

class _SettingsState extends State<Settings> {
  // 타임라인 설정 위젯 생성
  Widget _buildTimelineSetting({
    required String title,
    required String subtitle,
    required int currentValue,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$currentValue:00',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
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
          title: Text(title),
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
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: selectedValue > minValue
                            ? () {
                                setState(() {
                                  selectedValue--;
                                });
                              }
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$selectedValue:00',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
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
            // 타임라인 설정 섹션
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          '타임라인 설정',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                      
                      // 타임라인 시작 시간 설정
                      _buildTimelineSetting(
                        title: '시작 시간',
                        subtitle: '타임라인의 시작 시간을 설정합니다. (0~23)',
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
                      
                      // 타임라인 종료 시간 설정
                      _buildTimelineSetting(
                        title: '종료 시간',
                        subtitle: '타임라인의 종료 시간을 설정합니다. (1~24)',
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
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

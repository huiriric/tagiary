import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tagiary/component/slide_up_container.dart';
import 'package:tagiary/tables/check_routine/check_routine_item.dart';
import 'package:tagiary/tables/check_routine/routine_history.dart';
import 'package:tagiary/todo_routine_widget/add_routine/add_routine.dart';
import 'package:tagiary/todo_routine_widget/routine_history_view.dart';
import 'package:tagiary/todo_routine_widget/todo_routine_widget.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({Key? key}) : super(key: key);

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  late CheckRoutineRepository _repository;
  late RoutineHistoryRepository _historyRepository;
  int _selectedDayIndex = DateTime.now().weekday % 7; // 오늘 요일 (0: 일요일, 1: 월요일, ... 6: 토요일)
  late DateTime _selectedDate; // 선택된 요일에 해당하는 날짜

  @override
  void initState() {
    super.initState();
    _repository = CheckRoutineRepository();
    _historyRepository = RoutineHistoryRepository();
    _initRepositories();
    _updateSelectedDate();
  }

  // 선택된 요일에 해당하는 날짜 계산
  void _updateSelectedDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayDayOfWeek = now.weekday % 7; // 0(일)~6(토) 범위로 변환
    
    // 선택된 요일과 오늘 요일의 차이 계산
    int dayDifference = _selectedDayIndex - todayDayOfWeek;
    
    // 날짜 계산
    _selectedDate = today.add(Duration(days: dayDifference));
  }

  Future<void> _initRepositories() async {
    await _repository.init();
    await _historyRepository.init();
    // 새로운 날짜가 시작될 때 루틴 초기화
    _repository.initializeRoutine();
  }

  @override
  Widget build(BuildContext context) {
    // 요일 라벨 배열
    final dayLabels = ['일', '월', '화', '수', '목', '금', '토'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '루틴',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Color(0xBB000000)),
        onPressed: () => _showAddRoutineDialog(context),
      ),
      body: Column(
        children: [
          // 요일 선택 버튼 row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                bool isSelected = index == _selectedDayIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDayIndex = index;
                      _updateSelectedDate(); // 날짜 업데이트
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        dayLabels[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // 선택된 날짜 표시
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 루틴 위젯 사용
          Expanded(
            child: TodoRoutineWidget(
              date: _selectedDate,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRoutineDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AnimatedPadding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        duration: const Duration(milliseconds: 0),
        curve: Curves.decelerate,
        child: SingleChildScrollView(
          child: SlideUpContainer(
            height: 350,
            child: AddRoutine(
              onRoutineAdded: () {
                setState(() {});
              },
            ),
          ),
        ),
      ),
    );
  }
}
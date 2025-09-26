// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:tagiary/tables/check_routine/check_routine_item.dart';
// import 'package:tagiary/tables/check_routine/routine_history.dart';

// class RoutineHistoryView extends StatefulWidget {
//   final CheckRoutineItem routine;

//   const RoutineHistoryView({
//     super.key,
//     required this.routine,
//   });

//   @override
//   State<RoutineHistoryView> createState() => _RoutineHistoryViewState();
// }

// class _RoutineHistoryViewState extends State<RoutineHistoryView> {
//   late RoutineHistoryRepository _historyRepository;
//   late CheckRoutineRepository _routineRepository;
//   List<RoutineHistory> _history = [];
//   DateTime _selectedMonth = DateTime.now();

//   @override
//   void initState() {
//     super.initState();
//     _historyRepository = RoutineHistoryRepository();
//     _routineRepository = CheckRoutineRepository();

//     Future.wait([
//       _historyRepository.init(),
//       _routineRepository.init(),
//     ]).then((_) {
//       _loadHistory();
//     });
//   }

//   // 루틴 요일 편집 다이얼로그
//   void _editRoutineDays() {
//     // 현재 루틴의 요일 설정 복사
//     List<bool> selectedDays = List.from(widget.routine.daysOfWeek);

//     // 요일 없는 경우 기본값 설정
//     if (selectedDays.length != 7) {
//       selectedDays = List.generate(7, (index) => true);
//     }

//     // 요일 표시용 라벨
//     final dayLabels = ['일', '월', '화', '수', '목', '금', '토'];

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('반복 요일 편집'),
//         content: StatefulBuilder(
//           builder: (context, setState) {
//             return SizedBox(
//               width: double.maxFinite,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text('루틴을 반복할 요일을 선택하세요'),
//                   const SizedBox(height: 16),
//                   Wrap(
//                     spacing: 8,
//                     children: List.generate(7, (index) {
//                       return GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             selectedDays[index] = !selectedDays[index];
//                           });
//                         },
//                         child: Container(
//                           width: 36,
//                           height: 36,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: selectedDays[index] ? Colors.black : Colors.transparent,
//                             border: Border.all(
//                               color: selectedDays[index] ? Colors.black : Colors.grey,
//                               width: 1,
//                             ),
//                           ),
//                           child: Center(
//                             child: Text(
//                               dayLabels[index],
//                               style: TextStyle(
//                                 color: selectedDays[index] ? Colors.white : Colors.grey,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),
//                       );
//                     }),
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('취소'),
//           ),
//           TextButton(
//             onPressed: () {
//               // 선택한 요일 중 하나라도 선택되어 있는지 확인
//               if (!selectedDays.contains(true)) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('최소 하나의 요일을 선택해주세요')),
//                 );
//                 return;
//               }

//               // 루틴 업데이트
//               _updateRoutineDays(selectedDays);
//               Navigator.pop(context);
//             },
//             child: const Text('저장'),
//           ),
//         ],
//       ),
//     );
//   }

//   // 루틴 요일 업데이트
//   Future<void> _updateRoutineDays(List<bool> newDays) async {
//     // 새 루틴 객체 생성
//     final updatedRoutine = CheckRoutineItem(
//       id: widget.routine.id,
//       content: widget.routine.content,
//       startDate: widget.routine.startDate,
//       colorValue: widget.routine.colorValue,
//       check: widget.routine.check,
//       updated: widget.routine.updated,
//       daysOfWeek: newDays,
//     );

//     // 저장소에 업데이트
//     await _routineRepository.updateItem(updatedRoutine);

//     // UI에 반영
//     setState(() {
//       // widget.routine = updatedRoutine; // 직접 widget 속성은 변경 불가능하므로 루틴 새로 불러오기
//     });

//     // 업데이트 메시지
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('반복 요일이 업데이트되었습니다')),
//       );
//     }
//   }

//   Future<void> _loadHistory() async {
//     final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
//     final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

//     setState(() {
//       _history = _historyRepository
//           .getHistoryForRoutine(widget.routine.id)
//           .where((h) => h.completedDate.isAfter(firstDayOfMonth) && h.completedDate.isBefore(lastDayOfMonth.add(const Duration(days: 1))))
//           .toList();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final double width = MediaQuery.of(context).size.width;
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.routine.content),
//         actions: [
//           // 요일 편집 버튼 추가
//           IconButton(
//             icon: const Icon(Icons.edit),
//             tooltip: '반복 요일 편집',
//             onPressed: _editRoutineDays,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           _buildMonthSelector(),
//           // 달성률 요약 카드 추가
//           _buildCompletionSummary(),
//           Expanded(
//             child: _buildCalendar(width),
//           ),
//         ],
//       ),
//     );
//   }

//   // 달성률 요약 카드
//   Widget _buildCompletionSummary() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       child: Card(
//         elevation: 1,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 '이번 달 달성률',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               FutureBuilder<double>(
//                 future: _calculateMonthlyCompletionRate(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   if (!snapshot.hasData || snapshot.data == 0) {
//                     return const Center(
//                       child: Text(
//                         '이번 달 데이터가 없습니다',
//                         style: TextStyle(color: Colors.grey),
//                       ),
//                     );
//                   }

//                   final completionRate = snapshot.data!;
//                   return Column(
//                     children: [
//                       // 달성률 표시 (퍼센트)
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             '${(completionRate * 100).toStringAsFixed(1)}%',
//                             style: TextStyle(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                               color: _getColorForRate(completionRate),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Icon(
//                             _getIconForRate(completionRate),
//                             color: _getColorForRate(completionRate),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),

//                       // 진행률 바
//                       Stack(
//                         children: [
//                           // 배경 프로그레스 바
//                           Container(
//                             height: 12,
//                             width: double.infinity,
//                             decoration: BoxDecoration(
//                               color: Colors.grey.withOpacity(0.2),
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                           // 진행률 표시 프로그레스 바
//                           Align(
//                             alignment: Alignment.centerLeft,
//                             child: Container(
//                               height: 12,
//                               width: MediaQuery.of(context).size.width * 0.8 * completionRate,
//                               decoration: BoxDecoration(
//                                 color: _getColorForRate(completionRate),
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 8),

//                       // 달성률 설명 텍스트
//                       FutureBuilder<String>(
//                         future: _getCompletionSummaryText(completionRate),
//                         builder: (context, snapshot) {
//                           if (!snapshot.hasData) {
//                             return const SizedBox.shrink();
//                           }
//                           return Text(
//                             snapshot.data!,
//                             textAlign: TextAlign.center,
//                             style: const TextStyle(
//                               fontSize: 13,
//                               color: Colors.grey,
//                             ),
//                           );
//                         },
//                       ),
//                     ],
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // 달성률에 따른 색상 반환
//   Color _getColorForRate(double rate) {
//     if (rate >= 0.8) {
//       return Colors.green;
//     } else if (rate >= 0.6) {
//       return Colors.lightGreen;
//     } else if (rate >= 0.4) {
//       return Colors.amber;
//     } else if (rate >= 0.2) {
//       return Colors.orange;
//     } else {
//       return Colors.red;
//     }
//   }

//   // 달성률에 따른 아이콘 반환
//   IconData _getIconForRate(double rate) {
//     if (rate >= 0.8) {
//       return Icons.sentiment_very_satisfied;
//     } else if (rate >= 0.6) {
//       return Icons.sentiment_satisfied;
//     } else if (rate >= 0.4) {
//       return Icons.sentiment_neutral;
//     } else if (rate >= 0.2) {
//       return Icons.sentiment_dissatisfied;
//     } else {
//       return Icons.sentiment_very_dissatisfied;
//     }
//   }

//   // 달성률 설명 텍스트 생성
//   Future<String> _getCompletionSummaryText(double rate) async {
//     final scheduledDaysCount = await _getScheduledDaysCount();
//     final completedDaysCount = _history.length;

//     return '이번 달 예정된 $scheduledDaysCount일 중 $completedDaysCount일 완료';
//   }

//   // 이번 달 예정된 날짜 수 계산
//   Future<int> _getScheduledDaysCount() async {
//     // 이번 달의 모든 날짜
//     final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
//     final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

//     // 루틴이 예정된 요일 정보
//     final daysOfWeek = widget.routine.daysOfWeek.length == 7 ? widget.routine.daysOfWeek : List.generate(7, (index) => true); // 기본값은 모든 요일 true

//     // 루틴 시작일
//     final routineStartDate = DateTime(widget.routine.startDate.year, widget.routine.startDate.month, widget.routine.startDate.day);

//     // 이번 달에 루틴이 예정된 날짜 수 계산
//     int count = 0;
//     for (int day = 1; day <= lastDayOfMonth.day; day++) {
//       final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
//       final dayOfWeek = date.weekday % 7; // 0(일)~6(토)

//       // 루틴 시작일 이후이고 해당 요일에 루틴이 설정된 경우만 카운트
//       if (daysOfWeek[dayOfWeek] && !date.isBefore(routineStartDate)) {
//         count++;
//       }
//     }

//     return count;
//   }

//   // 월간 달성률 계산
//   Future<double> _calculateMonthlyCompletionRate() async {
//     final scheduledDaysCount = await _getScheduledDaysCount();

//     // 예정된 날짜가 없으면 0% 반환
//     if (scheduledDaysCount == 0) return 0.0;

//     return _history.length / scheduledDaysCount;
//   }

//   Widget _buildMonthSelector() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           IconButton(
//             icon: const Icon(Icons.chevron_left),
//             onPressed: () {
//               setState(() {
//                 _selectedMonth = DateTime(
//                   _selectedMonth.year,
//                   _selectedMonth.month - 1,
//                 );
//                 _loadHistory();
//               });
//             },
//           ),
//           Text(
//             DateFormat('yyyy년 MM월').format(_selectedMonth),
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.chevron_right),
//             onPressed: () {
//               setState(() {
//                 _selectedMonth = DateTime(
//                   _selectedMonth.year,
//                   _selectedMonth.month + 1,
//                 );
//                 _loadHistory();
//               });
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCalendar(double width) {
//     // 달의 일수 계산
//     final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
//     final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
//     final firstWeekday = firstDayOfMonth.weekday % 7; // 0은 일요일

//     // 월 전체 날짜 목록 생성
//     final calendarDays = List.generate(
//       daysInMonth + firstWeekday,
//       (index) {
//         if (index < firstWeekday) {
//           return null; // 1일 이전의 빈 칸
//         }
//         return DateTime(_selectedMonth.year, _selectedMonth.month, index - firstWeekday + 1);
//       },
//     );

//     // 주별로 2차원 배열 생성
//     final weeks = <List<DateTime?>>[];
//     for (var i = 0; i < calendarDays.length; i += 7) {
//       final end = i + 7;
//       weeks.add(calendarDays.sublist(i, end > calendarDays.length ? calendarDays.length : end));
//       if (end > calendarDays.length) {
//         // 주의 나머지 부분을 null로 채움
//         weeks.last.addAll(List.generate(end - calendarDays.length, (_) => null));
//       }
//     }

//     return Column(
//       children: [
//         // 요일 헤더
//         const Row(
//           children: [
//             Expanded(child: Center(child: Text('일', style: TextStyle(fontWeight: FontWeight.bold)))),
//             Expanded(child: Center(child: Text('월', style: TextStyle(fontWeight: FontWeight.bold)))),
//             Expanded(child: Center(child: Text('화', style: TextStyle(fontWeight: FontWeight.bold)))),
//             Expanded(child: Center(child: Text('수', style: TextStyle(fontWeight: FontWeight.bold)))),
//             Expanded(child: Center(child: Text('목', style: TextStyle(fontWeight: FontWeight.bold)))),
//             Expanded(child: Center(child: Text('금', style: TextStyle(fontWeight: FontWeight.bold)))),
//             Expanded(child: Center(child: Text('토', style: TextStyle(fontWeight: FontWeight.bold)))),
//           ],
//         ),
//         // const SizedBox(height: 2),
//         const Divider(height: 1),
//         // 캘린더 그리드
//         Expanded(
//           child: ListView.builder(
//             itemCount: weeks.length,
//             itemBuilder: (context, weekIndex) {
//               return Row(
//                 children: List.generate(7, (dayIndex) {
//                   final date = weeks[weekIndex].length > dayIndex ? weeks[weekIndex][dayIndex] : null;
//                   return Expanded(
//                     child: _buildCalendarDay(date, width),
//                   );
//                 }),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCalendarDay(DateTime? date, double width) {
//     if (date == null) {
//       return const SizedBox(height: 50);
//     }

//     // 루틴 시작일 확인
//     final routineStartDate = DateTime(widget.routine.startDate.year, widget.routine.startDate.month, widget.routine.startDate.day);
//     final dateOnly = DateTime(date.year, date.month, date.day);
//     final isBeforeRoutineStart = dateOnly.isBefore(routineStartDate);

//     // 루틴이 설정된 요일인지 확인
//     final dayOfWeek = date.weekday % 7; // 0(일)~6(토)
//     final daysOfWeek = widget.routine.daysOfWeek.length == 7 ? widget.routine.daysOfWeek : List.generate(7, (index) => true);
//     final isRoutineDay = daysOfWeek[dayOfWeek];

//     // 이 날짜에 루틴을 완료했는지 확인 (루틴 시작일 이후이고 루틴 요일인 경우만)
//     final isCompleted = !isBeforeRoutineStart &&
//         isRoutineDay &&
//         _history.any((h) {
//           final historyDate = DateTime(h.completedDate.year, h.completedDate.month, h.completedDate.day);
//           final compareDate = DateTime(date.year, date.month, date.day);
//           return historyDate.isAtSameMomentAs(compareDate);
//         });

//     final isToday = DateTime.now().day == date.day && DateTime.now().month == date.month && DateTime.now().year == date.year;

//     return Container(
//       height: width / 7,
//       decoration: const BoxDecoration(
//           // border: Border.all(color: Colors.grey.withOpacity(0.2), width: 0.5),
//           // color: isToday ? Colors.blue[100] : null,
//           ),
//       child: Stack(
//         children: [
//           Align(
//             alignment: Alignment.topLeft,
//             child: Padding(
//               padding: const EdgeInsets.all(4.0),
//               child: Text(
//                 '${date.day}',
//                 style: TextStyle(
//                   color: date.weekday == DateTime.sunday
//                       ? Colors.red
//                       : date.weekday == DateTime.saturday
//                           ? Colors.blue
//                           : Colors.black,
//                 ),
//               ),
//             ),
//           ),
//           if (isCompleted)
//             Center(
//               child: Container(
//                 width: 24,
//                 height: 24,
//                 decoration: BoxDecoration(
//                   color: Color(widget.routine.colorValue),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.check,
//                   color: Colors.white,
//                   size: 16,
//                 ),
//               ),
//             )
//           else if (!isBeforeRoutineStart && isRoutineDay)
//             // 루틴 시작일 이후 예정된 날짜에는 빈 원 표시
//             Center(
//               child: Container(
//                 width: 20,
//                 height: 20,
//                 decoration: BoxDecoration(
//                   border: Border.all(
//                     color: Color(widget.routine.colorValue).withOpacity(0.5),
//                     width: 2,
//                   ),
//                   shape: BoxShape.circle,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

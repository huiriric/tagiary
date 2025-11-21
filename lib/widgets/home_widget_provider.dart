// import 'package:home_widget/home_widget.dart';
// import 'package:tagiary/tables/check_routine/check_routine_item.dart';
// import 'package:tagiary/tables/schedule/schedule_item.dart';
// import 'package:tagiary/tables/check/check_item.dart';

// class HomeWidgetProvider {
//   // 위젯 업데이트를 위한 메서드들

//   /// 주간 일정 위젯 업데이트
//   static Future<void> updateWeeklyScheduleWidget() async {
//     try {
//       final scheduleRepo = ScheduleRepository();
//       await scheduleRepo.init();

//       final now = DateTime.now();
//       final today = DateTime(now.year, now.month, now.day);
//       final weekEnd = today.add(const Duration(days: 7));

//       // 이번 주 일정 가져오기
//       final schedules = scheduleRepo.getAllItems().where((schedule) {
//         final scheduleDate = DateTime(schedule.year, schedule.month, schedule.date);
//         return scheduleDate.isAfter(today.subtract(const Duration(days: 1))) && scheduleDate.isBefore(weekEnd);
//       }).toList();

//       // 날짜순 정렬
//       schedules.sort((a, b) {
//         final aDate = DateTime(a.year, a.month, a.date);
//         final bDate = DateTime(b.year, b.month, b.date);
//         return aDate.compareTo(bDate);
//       });

//       // 위젯에 데이터 저장 (최대 5개)
//       final limitedSchedules = schedules.take(5).toList();
//       await HomeWidget.saveWidgetData<String>(
//         'schedule_count',
//         limitedSchedules.length.toString(),
//       );

//       for (int i = 0; i < limitedSchedules.length; i++) {
//         final schedule = limitedSchedules[i];
//         await HomeWidget.saveWidgetData<String>(
//           'schedule_${i}_title',
//           schedule.title,
//         );
//         await HomeWidget.saveWidgetData<String>(
//           'schedule_${i}_date',
//           '${schedule.month}/${schedule.date}',
//         );
//         await HomeWidget.saveWidgetData<String>(
//           'schedule_${i}_color',
//           schedule.colorValue.toString(),
//         );
//       }

//       await HomeWidget.updateWidget(
//         name: 'WeeklyScheduleWidget',
//         androidName: 'WeeklyScheduleWidgetProvider',
//         iOSName: 'WeeklyScheduleWidget',
//       );
//     } catch (e) {
//       print('주간 일정 위젯 업데이트 실패: $e');
//     }
//   }

//   /// 할 일 위젯 업데이트
//   static Future<void> updateTodoWidget() async {
//     try {
//       final todoRepo = CheckRepository();
//       await todoRepo.init();

//       // 오늘의 할 일 가져오기
//       final todos = todoRepo.getUnCheckdItems();

//       // 위젯에 데이터 저장 (최대 7개)
//       final limitedTodos = todos.take(7).toList();
//       await HomeWidget.saveWidgetData<String>(
//         'todo_count',
//         limitedTodos.length.toString(),
//       );

//       int checkedCount = todoRepo.getCheckedItems().length;
//       int totalCount = todos.length + checkedCount;
//       double progress = totalCount > 0 ? checkedCount / totalCount : 0.0;

//       await HomeWidget.saveWidgetData<String>(
//         'todo_progress',
//         progress.toStringAsFixed(2),
//       );

//       for (int i = 0; i < limitedTodos.length; i++) {
//         final todo = limitedTodos[i];
//         await HomeWidget.saveWidgetData<String>(
//           'todo_${i}_content',
//           todo.content,
//         );
//         await HomeWidget.saveWidgetData<String>(
//           'todo_${i}_color',
//           todo.colorValue.toString(),
//         );
//       }

//       await HomeWidget.updateWidget(
//         name: 'TodoWidget',
//         androidName: 'TodoWidgetProvider',
//         iOSName: 'TodoWidget',
//       );
//     } catch (e) {
//       print('할 일 위젯 업데이트 실패: $e');
//     }
//   }

//   /// 루틴 위젯 업데이트
//   static Future<void> updateRoutineWidget() async {
//     try {
//       final routineRepo = CheckRoutineRepository();
//       await routineRepo.init();

//       final now = DateTime.now();
//       final todayDayOfWeek = now.weekday % 7; // 0(일)~6(토)

//       // 오늘의 루틴 가져오기
//       final routines = routineRepo.getAllItems().where((routine) {
//         // 시작일 체크
//         final routineStartDate = DateTime(
//           routine.startDate.year,
//           routine.startDate.month,
//           routine.startDate.day,
//         );
//         final today = DateTime(now.year, now.month, now.day);
//         if (today.isBefore(routineStartDate)) return false;

//         // 종료일 체크
//         if (routine.endDate != null) {
//           final routineEndDate = DateTime(
//             routine.endDate!.year,
//             routine.endDate!.month,
//             routine.endDate!.day,
//           );
//           if (today.isAfter(routineEndDate)) return false;
//         }

//         // 요일 체크
//         return routine.daysOfWeek[todayDayOfWeek];
//       }).toList();

//       // 위젯에 데이터 저장 (최대 7개)
//       final limitedRoutines = routines.take(7).toList();
//       await HomeWidget.saveWidgetData<String>(
//         'routine_count',
//         limitedRoutines.length.toString(),
//       );

//       int checkedCount = routines.where((r) => r.check).length;
//       double progress = routines.isNotEmpty ? checkedCount / routines.length : 0.0;

//       await HomeWidget.saveWidgetData<String>(
//         'routine_progress',
//         progress.toStringAsFixed(2),
//       );

//       for (int i = 0; i < limitedRoutines.length; i++) {
//         final routine = limitedRoutines[i];
//         await HomeWidget.saveWidgetData<String>(
//           'routine_${i}_content',
//           routine.content,
//         );
//         await HomeWidget.saveWidgetData<String>(
//           'routine_${i}_checked',
//           routine.check.toString(),
//         );
//         await HomeWidget.saveWidgetData<String>(
//           'routine_${i}_color',
//           routine.colorValue.toString(),
//         );
//       }

//       await HomeWidget.updateWidget(
//         name: 'RoutineWidget',
//         androidName: 'RoutineWidgetProvider',
//         iOSName: 'RoutineWidget',
//       );
//     } catch (e) {
//       print('루틴 위젯 업데이트 실패: $e');
//     }
//   }

//   /// 모든 위젯 업데이트
//   static Future<void> updateAllWidgets() async {
//     await Future.wait([
//       updateWeeklyScheduleWidget(),
//       updateTodoWidget(),
//       updateRoutineWidget(),
//     ]);
//   }
// }

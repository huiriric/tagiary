import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mrplando/tables/data_models/event.dart';
import 'package:mrplando/main.dart';
part 'schedule_routine_item.g.dart';

@HiveType(typeId: 1)
class ScheduleRoutineItem extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final List<bool> daysOfWeek; // [월,화,수,목,금,토,일] - true means the schedule applies to that day

  @HiveField(4)
  final DateTime createdAt = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  @HiveField(5)
  final int? startHour;

  @HiveField(6)
  final int? startMinute;

  @HiveField(7)
  final int? endHour;

  @HiveField(8)
  final int? endMinute;

  @HiveField(9)
  final int colorValue;

  @HiveField(10)
  final DateTime? startDate;

  @HiveField(11)
  final DateTime? endDate;

  bool get hasTimeInfo => startHour != null && startMinute != null && endHour != null && endMinute != null;

  ScheduleRoutineItem({
    required this.title,
    required this.description,
    this.startHour,
    this.startMinute,
    this.endHour,
    this.endMinute,
    required this.colorValue,
    required this.daysOfWeek,
    this.startDate,
    this.endDate,
  });

  Event toEvent() {
    return Event(
        id: id,
        title: title,
        description: description,
        daysOfWeek: daysOfWeek,
        date: startDate, // 시작일 (루틴 날짜 범위용)
        endDate: endDate, // 종료일 (루틴 날짜 범위용)
        startTime: hasTimeInfo ? TimeOfDay(hour: startHour!, minute: startMinute!) : null,
        endTime: hasTimeInfo ? TimeOfDay(hour: endHour!, minute: endMinute!) : null,
        color: Color(colorValue),
        isRoutine: true,
        hasTimeSet: hasTimeInfo);
  }
}

class ScheduleRoutineRepository {
  static const String itemCounterKey = 'itemCounter';

  late Box<ScheduleRoutineItem> _item;
  late Box<int> _counter;

  Future<void> init() async {
    // 이미 열려있는지 확인
    if (Hive.isBoxOpen('scheduleRoutineBox')) {
      _item = Hive.box<ScheduleRoutineItem>('scheduleRoutineBox');
    } else {
      _item = await Hive.openBox<ScheduleRoutineItem>('scheduleRoutineBox');
    }

    if (Hive.isBoxOpen('counterBox')) {
      _counter = Hive.box<int>('counterBox');
    } else {
      _counter = await Hive.openBox<int>('counterBox');
    }
  }

  Future<int> addItem(ScheduleRoutineItem item) async {
    int currentId = _counter.get(itemCounterKey, defaultValue: 0)!;
    int newId = currentId + 1;

    item.id = newId;

    await _item.put(newId, item);
    await _counter.put(itemCounterKey, newId);

    return newId;
  }

  ScheduleRoutineItem? getItem(int id) {
    return _item.get(id);
  }

  List<ScheduleRoutineItem> getAllItems() {
    return _item.values.toList();
  }

  Iterable<Event> getAllEvents() {
    return _item.values.toList().map((e) => e.toEvent());
  }

  // 특정 요일의 스케줄만 가져오기 (시간 정보가 있는 경우)
  // dayIndex: 0(일요일) ~ 6(토요일)
  Iterable<Event> getItemsByDayWithTime(int dayIndex) {
    if (dayIndex < 0 || dayIndex > 6) {
      throw ArgumentError('dayIndex must be between 0 and 6');
    }

    return _item.values.where((item) {
      // 인덱스가 유효한지 확인
      if (item.daysOfWeek.length <= dayIndex) {
        return false;
      }
      // 해당 요일이면서 시간 정보가 있는 경우만 반환
      return item.daysOfWeek[dayIndex] && item.hasTimeInfo;
    }).map((e) => e.toEvent());
  }

  // 특정 요일의 스케줄만 가져오기 (시간 정보가 없는 경우)
  Iterable<Event> getItemsByDayWithoutTime(int dayIndex) {
    if (dayIndex < 0 || dayIndex > 6) {
      throw ArgumentError('dayIndex must be between 0 and 6');
    }

    return _item.values.where((item) {
      // 인덱스가 유효한지 확인
      if (item.daysOfWeek.length <= dayIndex) {
        return false;
      }
      return item.daysOfWeek[dayIndex] && !item.hasTimeInfo;
    }).map((e) => e.toEvent());
  }

  // 오늘의 스케줄만 가져오기
  // Iterable<Event> getTodayItems() {
  //   // DateTime의 weekday는 1(월요일) ~ 7(일요일)이므로 조정 필요
  //   final today = DateTime.now().weekday % 7; // 0(일)~6(토) 범위로 변환
  //   return getItemsByDayWithTime(today);
  // }

  Future<void> updateItem(ScheduleRoutineItem item) async {
    await _item.put(item.id, item);
  }

  Future<void> deleteItem(int id) async {
    await _item.delete(id);
  }
}

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:tagiary/tables/data_models/event.dart';
import 'package:tagiary/main.dart';
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
  final int startHour;

  @HiveField(5)
  final int startMinute;

  @HiveField(6)
  final int endHour;

  @HiveField(7)
  final int endMinute;

  @HiveField(8)
  final int colorValue;

  ScheduleRoutineItem({
    required this.title,
    required this.description,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.colorValue,
    required this.daysOfWeek,
  });

  Event toEvent() {
    return Event(
      id: id,
      title: title,
      description: description,
      startTime: TimeOfDay(hour: startHour, minute: startMinute),
      endTime: TimeOfDay(hour: endHour, minute: endMinute),
      color: Color(colorValue),
      isRoutine: true,
    );
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

  // 특정 요일의 스케줄만 가져오기
  // dayIndex: 0(일요일) ~ 6(토요일)
  Iterable<Event> getItemsByDay(int dayIndex) {
    if (dayIndex < 0 || dayIndex > 6) {
      throw ArgumentError('dayIndex must be between 0 and 6');
    }

    return _item.values.where((item) {
      // 인덱스가 유효한지 확인
      if (item.daysOfWeek.length <= dayIndex) {
        return false;
      }
      return item.daysOfWeek[dayIndex];
    }).map((e) => e.toEvent());
  }

  // 오늘의 스케줄만 가져오기
  Iterable<Event> getTodayItems() {
    // DateTime의 weekday는 1(월요일) ~ 7(일요일)이므로 조정 필요
    final today = DateTime.now().weekday % 7; // 0(일)~6(토) 범위로 변환
    return getItemsByDay(today);
  }

  Future<void> updateItem(ScheduleRoutineItem item) async {
    await _item.put(item.id, item);
  }

  Future<void> deleteItem(int id) async {
    await _item.delete(id);
  }
}

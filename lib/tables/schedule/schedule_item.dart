import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:tagiary/tables/data_models/event.dart';
import 'package:tagiary/main.dart';
part 'schedule_item.g.dart';

@HiveType(typeId: 0)
class ScheduleItem extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  final int year;

  @HiveField(2)
  final int month;

  @HiveField(3)
  final int date;

  @HiveField(4)
  final int? endYear;

  @HiveField(5)
  final int? endMonth;

  @HiveField(6)
  final int? endDate;

  @HiveField(7)
  final String title;

  @HiveField(8)
  final String description;

  @HiveField(9)
  final int? startHour; // null 가능

  @HiveField(10)
  final int? startMinute; // null 가능

  @HiveField(11)
  final int? endHour; // null 가능

  @HiveField(12)
  final int? endMinute; // null 가능

  @HiveField(13)
  final int colorValue;

  bool get hasMultyDay => endYear != null && endMonth != null && endDate != null;

  ScheduleItem({
    required this.year,
    required this.month,
    required this.date,
    this.endYear,
    this.endMonth,
    this.endDate,
    required this.title,
    required this.description,
    this.startHour,
    this.startMinute,
    this.endHour,
    this.endMinute,
    required this.colorValue,
  });

  // 시간 정보가 있는지 확인하는 getter
  bool get hasTimeInfo => startHour != null && startMinute != null && endHour != null && endMinute != null;

  Event toEvent() {
    return Event(
      id: id,
      title: title,
      description: description,
      date: DateTime(year, month, date), // 날짜 정보
      daysOfWeek: null,
      startTime: hasTimeInfo ? TimeOfDay(hour: startHour!, minute: startMinute!) : null,
      endTime: hasTimeInfo ? TimeOfDay(hour: endHour!, minute: endMinute!) : null,
      color: Color(colorValue),
      isRoutine: false,
      hasTimeSet: hasTimeInfo,
      hasMultyDay: hasMultyDay,
    );
  }
}

class ScheduleRepository {
  static const String itemCounterKey = 'itemCounter';

  late Box<ScheduleItem> _item;
  late Box<int> _counter;

  Future<void> init() async {
    // 이미 열려있는지 확인
    if (Hive.isBoxOpen('scheduleBox')) {
      _item = Hive.box<ScheduleItem>('scheduleBox');
    } else {
      _item = await Hive.openBox<ScheduleItem>('scheduleBox');
    }

    if (Hive.isBoxOpen('counterBox')) {
      _counter = Hive.box<int>('counterBox');
    } else {
      _counter = await Hive.openBox<int>('counterBox');
    }
  }

  Future<int> addItem(ScheduleItem item) async {
    int currentId = _counter.get(itemCounterKey, defaultValue: 0)!;
    int newId = currentId + 1;

    item.id = newId;

    await _item.put(newId, item);
    await _counter.put(itemCounterKey, newId);

    return newId;
  }

  ScheduleItem? getItem(int id) {
    return _item.get(id);
  }

  List<ScheduleItem> getAllItems() {
    return _item.values.toList();
  }

  Iterable<Event> getDateItems(DateTime date) {
    return _item.values
        .where((item) => DateTime(item.year, item.month, item.date).isAtSameMomentAs(DateTime(date.year, date.month, date.day)))
        .map((e) => e.toEvent());
  }

  // 시간 정보가 없는 일정만 가져오기
  Iterable<Event> getNoTimeItems(DateTime date) {
    return _item.values
        .where((item) =>
            DateTime(item.year, item.month, item.date).isAtSameMomentAs(DateTime(date.year, date.month, date.day)) &&
            (item.startHour == null || item.endHour == null))
        .map((e) => e.toEvent());
  }

  // 시간 정보가 있는 일정만 가져오기
  Iterable<Event> getTimeItems(DateTime date) {
    return _item.values
        .where((item) =>
            DateTime(item.year, item.month, item.date).isAtSameMomentAs(DateTime(date.year, date.month, date.day)) &&
            item.startHour != null &&
            item.endHour != null)
        .map((e) => e.toEvent());
  }

  Future<void> updateItem(ScheduleItem item) async {
    await _item.put(item.id, item);
  }

  Future<void> deleteItem(int id) async {
    await _item.delete(id);
  }
}

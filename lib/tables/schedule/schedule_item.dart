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
  final String title;

  @HiveField(5)
  final String description;

  @HiveField(6)
  final int startHour;

  @HiveField(7)
  final int startMinute;

  @HiveField(8)
  final int endHour;

  @HiveField(9)
  final int endMinute;

  @HiveField(10)
  final int colorValue;

  ScheduleItem({
    required this.year,
    required this.month,
    required this.date,
    required this.title,
    required this.description,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.colorValue,
  });

  Event toEvent() {
    return Event(
      id: id,
      title: title,
      description: description,
      startTime: TimeOfDay(hour: startHour, minute: startMinute),
      endTime: TimeOfDay(hour: endHour, minute: endMinute),
      color: Color(colorValue),
      isRoutine: false,
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

  Future<void> updateItem(ScheduleItem item) async {
    await _item.put(item.id, item);
  }

  Future<void> deleteItem(int id) async {
    await _item.delete(id);
  }
}

import 'package:hive/hive.dart';
part 'routine_history.g.dart';

@HiveType(typeId: 5) // Make sure this ID is not used by other Hive types
class RoutineHistory extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  final int routineId;

  @HiveField(2)
  final DateTime completedDate;

  RoutineHistory({
    required this.id,
    required this.routineId,
    required this.completedDate,
  });
}

class RoutineHistoryRepository {
  static const String itemCounterKey = 'historyCounter';

  late Box<RoutineHistory> _item;
  late Box<int> _counter;

  Future<void> init() async {
    _item = await Hive.openBox<RoutineHistory>('routineHistoryBox');
    _counter = await Hive.openBox<int>('counterBox');
  }

  Future<int> addItem(RoutineHistory item) async {
    int currentId = _counter.get(itemCounterKey, defaultValue: 0)!;
    int newId = currentId + 1;

    item.id = newId;

    await _item.put(newId, item);
    await _counter.put(itemCounterKey, newId);

    return newId;
  }

  // Get history entries for a specific routine
  List<RoutineHistory> getHistoryForRoutine(int routineId) {
    return _item.values
        .where((history) => history.routineId == routineId)
        .toList();
  }

  // Get all history entries between two dates
  List<RoutineHistory> getHistoryBetweenDates(DateTime start, DateTime end) {
    return _item.values.where((history) {
      return history.completedDate.isAfter(start) && 
             history.completedDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Check if a routine was completed on a specific date
  bool wasRoutineCompletedOnDate(int routineId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return _item.values.any((history) => 
      history.routineId == routineId &&
      history.completedDate.isAfter(startOfDay) &&
      history.completedDate.isBefore(endOfDay)
    );
  }

  // Delete all history for a specific routine
  Future<void> deleteHistoryForRoutine(int routineId) async {
    final keysToDelete = _item.keys.where((key) {
      final item = _item.get(key);
      return item != null && item.routineId == routineId;
    }).toList();
    
    for (var key in keysToDelete) {
      await _item.delete(key);
    }
  }
  
  // Delete history for a specific routine on a specific date
  Future<void> deleteHistoryForRoutineOnDate(int routineId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    
    final keysToDelete = _item.keys.where((key) {
      final item = _item.get(key);
      return item != null && 
             item.routineId == routineId &&
             item.completedDate.isAfter(startOfDay) &&
             item.completedDate.isBefore(endOfDay);
    }).toList();
    
    for (var key in keysToDelete) {
      await _item.delete(key);
    }
  }
}
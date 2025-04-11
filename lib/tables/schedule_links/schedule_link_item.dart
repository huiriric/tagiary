import 'package:hive/hive.dart';
part 'schedule_link_item.g.dart';

// 연결되는 항목의 타입
@HiveType(typeId: 7)
enum LinkItemType {
  @HiveField(0)
  todo, // 일반 할 일
  @HiveField(1)
  todoRoutine, // 루틴 할 일
}

@HiveType(typeId: 6) // 적절한 typeId 선택 (다른 모델과 충돌하지 않는 값)
class ScheduleLinkItem extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  final int scheduleId; // 일정 ID

  @HiveField(2)
  final bool isRoutine; // 이 일정이 루틴인지 여부

  @HiveField(3)
  final int linkedItemId; // 연결된 항목(할일/루틴)의 ID

  @HiveField(4)
  final LinkItemType linkedItemType; // 연결된 항목의 타입

  ScheduleLinkItem({
    required this.scheduleId,
    required this.isRoutine,
    required this.linkedItemId,
    required this.linkedItemType,
  });
}

class ScheduleLinkRepository {
  static const String itemCounterKey = 'linkItemCounter';

  late Box<ScheduleLinkItem> _item;
  late Box<int> _counter;

  Future<void> init() async {
    // 이미 열려있는지 확인
    if (Hive.isBoxOpen('scheduleLinkBox')) {
      _item = Hive.box<ScheduleLinkItem>('scheduleLinkBox');
    } else {
      _item = await Hive.openBox<ScheduleLinkItem>('scheduleLinkBox');
    }

    if (Hive.isBoxOpen('counterBox')) {
      _counter = Hive.box<int>('counterBox');
    } else {
      _counter = await Hive.openBox<int>('counterBox');
    }
  }

  Future<int> addItem(ScheduleLinkItem item) async {
    int currentId = _counter.get(itemCounterKey, defaultValue: 0) ?? 0;
    int newId = currentId + 1;

    item.id = newId;

    await _item.put(newId, item);
    await _counter.put(itemCounterKey, newId);

    return newId;
  }

  // 특정 일정에 연결된 항목 찾기
  List<ScheduleLinkItem> getLinksForSchedule(int scheduleId, bool isRoutine) {
    return _item.values.where((link) => link.scheduleId == scheduleId && link.isRoutine == isRoutine).toList();
  }

  // 특정 할일/루틴에 연결된 일정 찾기
  List<ScheduleLinkItem> getLinksForItem(int itemId, LinkItemType itemType) {
    return _item.values.where((link) => link.linkedItemId == itemId && link.linkedItemType == itemType).toList();
  }

  // 일정에 연결된 모든 링크 삭제
  Future<void> deleteLinksForSchedule(int scheduleId, bool isRoutine) async {
    final links = getLinksForSchedule(scheduleId, isRoutine);
    for (var link in links) {
      await _item.delete(link.id);
    }
  }

  // 할일/루틴에 연결된 모든 링크 삭제
  Future<void> deleteLinksForItem(int itemId, LinkItemType itemType) async {
    final links = getLinksForItem(itemId, itemType);
    for (var link in links) {
      await _item.delete(link.id);
    }
  }

  // 특정 링크 삭제
  Future<void> deleteLink(int id) async {
    await _item.delete(id);
  }
}

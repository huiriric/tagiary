import 'package:hive/hive.dart';
part 'diary_item.g.dart';

@HiveType(typeId: 4)
class DiaryItem extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final int? categoryId; // 카테고리 ID (일기 카테고리 - 태그와는 별개)

  @HiveField(5)
  final List<int> tagIds; // 연결된 태그 ID 목록

  DiaryItem({
    required this.id,
    required this.title,
    required this.date,
    required this.content,
    this.categoryId,
    required this.tagIds,
  });
}

class DiaryRepository {
  static const String itemCounterKey = 'diaryItemCounter';

  late Box<DiaryItem> _item;
  late Box<int> _counter;

  Future<void> init() async {
    _item = await Hive.openBox<DiaryItem>('diaryBox');
    _counter = await Hive.openBox<int>('counterBox');
  }

  Future<int> addDiary(DiaryItem item) async {
    int currentId = _counter.get(itemCounterKey, defaultValue: 0)!;
    int newId = currentId + 1;

    item.id = newId;

    await _item.put(newId, item);
    await _counter.put(itemCounterKey, newId);

    return newId;
  }

  Future<void> updateDiary(DiaryItem item) async {
    await _item.put(item.id, item);
  }

  Future<void> deleteDiary(int id) async {
    await _item.delete(id);
  }

  DiaryItem? getItem(int id) {
    return _item.get(id);
  }

  List<DiaryItem>? getDateItem(DateTime date) {
    return _item.values.where((item) => item.date.year == date.year && item.date.month == date.month && item.date.day == date.day).toList();
  }

  List<DiaryItem> getAllItems() {
    List<DiaryItem> list = _item.values.toList();
    // 일기 최신 순으로 가져오기
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // 카테고리별 다이어리 가져오기
  List<DiaryItem> getItemsByCategory(int categoryId) {
    List<DiaryItem> list = _item.values.where((item) => item.categoryId == categoryId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // 태그별 다이어리 가져오기
  List<DiaryItem> getItemsByTag(int tagId) {
    List<DiaryItem> list = _item.values.where((item) => item.tagIds.contains(tagId)).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // 검색 기능
  List<DiaryItem> searchItems(String query) {
    String lowercaseQuery = query.toLowerCase();
    List<DiaryItem> list =
        _item.values.where((item) => item.title.toLowerCase().contains(lowercaseQuery) || item.content.toLowerCase().contains(lowercaseQuery)).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }
}

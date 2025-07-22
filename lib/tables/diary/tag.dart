import 'package:hive/hive.dart';

part 'tag.g.dart';

@HiveType(typeId: 8)
class Tag extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int usageCount; // 사용 빈도

  @HiveField(3)
  DateTime lastUsed; // 최근 사용일

  Tag({
    required this.id,
    required this.name,
    this.usageCount = 0,
    DateTime? lastUsed,
  }) : lastUsed = lastUsed ?? DateTime.now();
}

class TagRepository {
  static const String tagCounterKey = 'tagCounter';

  late Box<Tag> _tags;
  late Box<int> _counter;

  Future<void> init() async {
    _tags = await Hive.openBox<Tag>('tagBox');
    _counter = await Hive.openBox<int>('counterBox');
  }

  Future<int> addTag(Tag tag) async {
    int currentId = _counter.get(tagCounterKey, defaultValue: 0)!;
    int newId = currentId + 1;

    tag.id = newId;

    await _tags.put(newId, tag);
    await _counter.put(tagCounterKey, newId);

    return newId;
  }

  Future<void> updateTag(Tag tag) async {
    await _tags.put(tag.id, tag);
  }

  Future<void> deleteTag(int id) async {
    await _tags.delete(id);
  }

  Tag? getTag(int id) {
    return _tags.get(id);
  }

  List<Tag> getAllTags() {
    return _tags.values.toList();
  }

  // 이름으로 태그 찾기
  Tag? getTagByName(String name) {
    try {
      return _tags.values.firstWhere((tag) => tag.name.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  // 태그 사용 빈도 증가
  Future<void> incrementUsage(int tagId) async {
    final tag = getTag(tagId);
    if (tag != null) {
      tag.usageCount++;
      tag.lastUsed = DateTime.now();
      await updateTag(tag);
    }
  }

  // 태그 검색 (부분 일치)
  List<Tag> searchTags(String query) {
    if (query.isEmpty) return getAllTags();
    
    final lowercaseQuery = query.toLowerCase();
    return _tags.values
        .where((tag) => tag.name.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  // 사용 빈도와 최근 사용일 기준으로 정렬된 태그 목록
  List<Tag> getTagsSorted() {
    final tags = getAllTags();
    tags.sort((a, b) {
      // 사용 빈도 우선, 같으면 최근 사용일 순
      if (a.usageCount != b.usageCount) {
        return b.usageCount.compareTo(a.usageCount);
      }
      return b.lastUsed.compareTo(a.lastUsed);
    });
    return tags;
  }

  // 검색 결과를 사용 빈도 순으로 정렬
  List<Tag> searchTagsSorted(String query) {
    final searchResults = searchTags(query);
    searchResults.sort((a, b) {
      // 정확히 일치하는 경우 우선
      if (a.name.toLowerCase() == query.toLowerCase()) return -1;
      if (b.name.toLowerCase() == query.toLowerCase()) return 1;
      
      // 시작하는 경우 우선
      final aStarts = a.name.toLowerCase().startsWith(query.toLowerCase());
      final bStarts = b.name.toLowerCase().startsWith(query.toLowerCase());
      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;
      
      // 사용 빈도 순
      if (a.usageCount != b.usageCount) {
        return b.usageCount.compareTo(a.usageCount);
      }
      
      // 최근 사용일 순
      return b.lastUsed.compareTo(a.lastUsed);
    });
    return searchResults;
  }
}

import 'package:hive/hive.dart';

part 'tag.g.dart';

@HiveType(typeId: 8)
class Tag extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int groupId; // 태그가 속한 그룹의 ID

  Tag({
    required this.id,
    required this.name,
    required this.groupId,
  });
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

  List<Tag> getTagsByGroup(int groupId) {
    return _tags.values.where((tag) => tag.groupId == groupId).toList();
  }
}

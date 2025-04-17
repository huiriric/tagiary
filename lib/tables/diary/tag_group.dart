import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'tag_group.g.dart';

@HiveType(typeId: 6)
class TagGroup extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int colorValue;

  TagGroup({
    required this.id,
    required this.name,
    required this.colorValue,
  });
}

class TagGroupRepository {
  static const String groupCounterKey = 'groupCounter';

  late Box<TagGroup> _groups;
  late Box<int> _counter;

  Future<void> init() async {
    _groups = await Hive.openBox<TagGroup>('tagGroupBox');
    _counter = await Hive.openBox<int>('counterBox');
  }

  Future<int> addGroup(TagGroup group) async {
    int currentId = _counter.get(groupCounterKey, defaultValue: 0)!;
    int newId = currentId + 1;

    group.id = newId;

    await _groups.put(newId, group);
    await _counter.put(groupCounterKey, newId);

    return newId;
  }

  Future<void> updateGroup(TagGroup group) async {
    await _groups.put(group.id, group);
  }

  Future<void> deleteGroup(int id) async {
    await _groups.delete(id);
  }

  TagGroup? getGroup(int id) {
    return _groups.get(id);
  }

  List<TagGroup> getAllGroups() {
    return _groups.values.toList();
  }

  // 기본 그룹 설정 (앱 첫 실행시 호출)
  Future<void> setupDefaultGroups() async {
    if (_groups.isEmpty) {
      await addGroup(TagGroup(
        id: 0,
        name: '일반',
        colorValue: Colors.grey.value,
      ));
      
      await addGroup(TagGroup(
        id: 0,
        name: '감정',
        colorValue: Colors.red.value,
      ));
      
      await addGroup(TagGroup(
        id: 0,
        name: '활동',
        colorValue: Colors.blue.value,
      ));
    }
  }
}

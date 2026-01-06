import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'tag_group.g.dart';

@HiveType(typeId: 9)
class TagGroup extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int colorValue;

  @HiveField(3)
  bool isDeleted;

  TagGroup({
    required this.id,
    required this.name,
    required this.colorValue,
    this.isDeleted = false,
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

  // Soft delete: isDeleted를 true로 설정
  Future<void> softDeleteGroup(int id) async {
    final group = _groups.get(id);
    if (group != null) {
      group.isDeleted = true;
      await _groups.put(id, group);
    }
  }

  TagGroup? getGroup(int id) {
    return _groups.get(id);
  }

  // 활성 카테고리만 반환 (isDeleted = false)
  List<TagGroup> getAllGroups() {
    return _groups.values.where((group) => !group.isDeleted).toList();
  }

  // 모든 카테고리 반환 (삭제된 것 포함)
  List<TagGroup> getAllGroupsIncludingDeleted() {
    return _groups.values.toList();
  }

  // 기본 카테고리 설정 (앱 첫 실행시 호출)
  Future<void> setupDefaultCategories() async {
    if (_groups.isEmpty) {
      await addGroup(TagGroup(
        id: 0,
        name: '일반',
        colorValue: Colors.blueGrey.value,
      ));
    }
  }
}

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'schedule_category.g.dart';

@HiveType(typeId: 14)
class ScheduleCategory extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int colorValue;

  @HiveField(3)
  bool isDeleted;

  ScheduleCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    this.isDeleted = false,
  });
}

class ScheduleCategoryRepository {
  static const String categoryCounterKey = 'scheduleCategoryCounter';

  late Box<ScheduleCategory> _categories;
  late Box<int> _counter;

  Future<void> init() async {
    // 이미 열린 박스가 있으면 재사용, 없으면 새로 열기
    if (Hive.isBoxOpen('scheduleCategoryBox')) {
      _categories = Hive.box<ScheduleCategory>('scheduleCategoryBox');
    } else {
      _categories = await Hive.openBox<ScheduleCategory>('scheduleCategoryBox');
    }

    if (Hive.isBoxOpen('counterBox')) {
      _counter = Hive.box<int>('counterBox');
    } else {
      _counter = await Hive.openBox<int>('counterBox');
    }
  }

  Future<int> addCategory(ScheduleCategory category) async {
    int currentId = _counter.get(categoryCounterKey, defaultValue: 0)!;
    int newId = currentId + 1;

    category.id = newId;

    await _categories.put(newId, category);
    await _counter.put(categoryCounterKey, newId);

    return newId;
  }

  Future<void> updateCategory(ScheduleCategory category) async {
    await _categories.put(category.id, category);
  }

  Future<void> deleteCategory(int id) async {
    await _categories.delete(id);
  }

  // Soft delete: isDeleted를 true로 설정
  Future<void> softDeleteCategory(int id) async {
    final category = _categories.get(id);
    if (category != null) {
      category.isDeleted = true;
      await _categories.put(id, category);
    }
  }

  ScheduleCategory? getCategory(int id) {
    return _categories.get(id);
  }

  // 활성 카테고리만 반환 (isDeleted = false)
  List<ScheduleCategory> getAllCategories() {
    return _categories.values.where((category) => !category.isDeleted).toList();
  }

  // 모든 카테고리 반환 (삭제된 것 포함)
  List<ScheduleCategory> getAllCategoriesIncludingDeleted() {
    return _categories.values.toList();
  }

  // 기본 카테고리 설정 (앱 첫 실행시 호출)
  Future<void> setupDefaultCategories() async {
    if (getAllCategories().isEmpty) {
      await addCategory(ScheduleCategory(
        id: 0,
        name: '일정',
        colorValue: Colors.orange.value,
      ));
    }
  }
}

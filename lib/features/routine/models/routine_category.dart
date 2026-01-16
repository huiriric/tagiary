import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'routine_category.g.dart';

@HiveType(typeId: 13)
class RoutineCategory extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int colorValue;

  @HiveField(3)
  bool isDeleted;

  RoutineCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    this.isDeleted = false,
  });
}

class RoutineCategoryRepository {
  static const String categoryCounterKey = 'routineCategoryCounter';

  late Box<RoutineCategory> _categories;
  late Box<int> _counter;

  Future<void> init() async {
    // 이미 열린 박스가 있으면 재사용, 없으면 새로 열기
    if (Hive.isBoxOpen('routineCategoryBox')) {
      _categories = Hive.box<RoutineCategory>('routineCategoryBox');
    } else {
      _categories = await Hive.openBox<RoutineCategory>('routineCategoryBox');
    }

    if (Hive.isBoxOpen('counterBox')) {
      _counter = Hive.box<int>('counterBox');
    } else {
      _counter = await Hive.openBox<int>('counterBox');
    }
  }

  Future<int> addCategory(RoutineCategory category) async {
    int currentId = _counter.get(categoryCounterKey, defaultValue: 0)!;
    int newId = currentId + 1;

    category.id = newId;

    await _categories.put(newId, category);
    await _counter.put(categoryCounterKey, newId);

    return newId;
  }

  Future<void> updateCategory(RoutineCategory category) async {
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

  RoutineCategory? getCategory(int id) {
    return _categories.get(id);
  }

  // 활성 카테고리만 반환 (isDeleted = false)
  List<RoutineCategory> getAllCategories() {
    return _categories.values.where((category) => !category.isDeleted).toList();
  }

  // 모든 카테고리 반환 (삭제된 것 포함)
  List<RoutineCategory> getAllCategoriesIncludingDeleted() {
    return _categories.values.toList();
  }

  // 기본 카테고리 설정 (앱 첫 실행시 호출)
  Future<void> setupDefaultCategories() async {
    if (_categories.isEmpty) {
      await addCategory(RoutineCategory(
        id: 0,
        name: '루틴',
        colorValue: Colors.green.value,
      ));
    }
  }
}
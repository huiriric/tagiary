import 'package:flutter/material.dart';
import 'package:mrplando/features/todo/models/todo_category.dart';
import 'package:mrplando/shared/models/category_manager_interface.dart';

class TodoCategoryManager implements CategoryManagerInterface {
  final TodoCategoryRepository categoryRepository;

  TodoCategoryManager({
    required this.categoryRepository,
  });

  // 초기화
  Future<void> init() async {
    await categoryRepository.init();
    await categoryRepository.setupDefaultCategories(); // 기본 카테고리 설정
  }

  // 카테고리 정보 가져오기
  @override
  CategoryInfo? getCategoryInfo(int categoryId) {
    final category = categoryRepository.getCategory(categoryId);
    if (category == null) return null;

    return CategoryInfo(
      id: category.id,
      name: category.name,
      color: Color(category.colorValue),
    );
  }

  // 모든 카테고리 가져오기
  @override
  List<CategoryInfo> getAllCategories() {
    return categoryRepository.getAllCategories().map((category) {
      return CategoryInfo(
        id: category.id,
        name: category.name,
        color: Color(category.colorValue),
      );
    }).toList();
  }

  // 새 카테고리 추가
  @override
  Future<int> addCategory(String name, Color color) async {
    final category = TodoCategory(
      id: 0,
      name: name,
      colorValue: color.value,
    );

    return await categoryRepository.addCategory(category);
  }

  // 카테고리 수정
  @override
  Future<void> updateCategory(int categoryId, String name, Color color) async {
    final category = categoryRepository.getCategory(categoryId);
    if (category != null) {
      category.name = name;
      category.colorValue = color.value;
      await categoryRepository.updateCategory(category);
    }
  }

  // 카테고리 삭제 (hard delete)
  @override
  Future<void> deleteCategory(int categoryId) async {
    await categoryRepository.deleteCategory(categoryId);
  }

  // 카테고리 소프트 삭제 (isDeleted = true)
  @override
  Future<void> softDeleteCategory(int categoryId) async {
    await categoryRepository.softDeleteCategory(categoryId);
  }

  // 삭제된 카테고리 포함 모든 카테고리 조회
  @override
  List<CategoryInfo> getAllCategoriesIncludingDeleted() {
    return categoryRepository.getAllCategoriesIncludingDeleted().map((category) {
      return CategoryInfo(
        id: category.id,
        name: category.name,
        color: Color(category.colorValue),
      );
    }).toList();
  }
}

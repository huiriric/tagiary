import 'package:flutter/material.dart';

// 공통 카테고리 정보 클래스
class CategoryInfo {
  final int id;
  final String name;
  final Color color;

  CategoryInfo({
    required this.id,
    required this.name,
    required this.color,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryInfo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// 공통 카테고리 매니저 인터페이스
abstract class CategoryManagerInterface {
  // 카테고리 정보 가져오기
  CategoryInfo? getCategoryInfo(int categoryId);

  // 모든 카테고리 가져오기
  List<CategoryInfo> getAllCategories();

  // 새 카테고리 추가
  Future<int> addCategory(String name, Color color);

  // 카테고리 수정
  Future<void> updateCategory(int categoryId, String name, Color color);

  // 카테고리 삭제 (hard delete)
  Future<void> deleteCategory(int categoryId);

  // 카테고리 소프트 삭제 (isDeleted = true)
  Future<void> softDeleteCategory(int categoryId);

  // 삭제된 카테고리 포함 모든 카테고리 조회
  List<CategoryInfo> getAllCategoriesIncludingDeleted();
}

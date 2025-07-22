import 'package:flutter/material.dart';
import 'package:tagiary/tables/diary/tag.dart';
import 'package:tagiary/tables/diary/tag_group.dart';

class TagManager {
  final TagRepository tagRepository;
  final TagGroupRepository groupRepository;

  TagManager({
    required this.tagRepository,
    required this.groupRepository,
  });

  // 초기화
  Future<void> init() async {
    await tagRepository.init();
    await groupRepository.init();
    await groupRepository.setupDefaultCategories(); // 기본 카테고리 설정
  }

  // === 태그 관련 메서드 ===
  
  // 태그 정보 가져오기
  TagInfo? getTagInfo(int tagId) {
    final tag = tagRepository.getTag(tagId);
    if (tag == null) return null;

    return TagInfo(
      id: tag.id,
      name: tag.name,
      usageCount: tag.usageCount,
      lastUsed: tag.lastUsed,
    );
  }

  // 태그 ID 목록에서 TagInfo 목록 가져오기
  List<TagInfo> getTagInfoList(List<int> tagIds) {
    List<TagInfo> result = [];

    for (int tagId in tagIds) {
      final tagInfo = getTagInfo(tagId);
      if (tagInfo != null) {
        result.add(tagInfo);
      }
    }

    return result;
  }

  // 모든 태그 가져오기 (사용 빈도순 정렬)
  List<TagInfo> getAllTagsSorted() {
    return tagRepository.getTagsSorted().map((tag) {
      return TagInfo(
        id: tag.id,
        name: tag.name,
        usageCount: tag.usageCount,
        lastUsed: tag.lastUsed,
      );
    }).toList();
  }

  // 태그 검색
  List<TagInfo> searchTags(String query) {
    return tagRepository.searchTagsSorted(query).map((tag) {
      return TagInfo(
        id: tag.id,
        name: tag.name,
        usageCount: tag.usageCount,
        lastUsed: tag.lastUsed,
      );
    }).toList();
  }

  // 새 태그 추가 또는 기존 태그 반환
  Future<int> addOrGetTag(String name) async {
    // 기존 태그 찾기
    final existingTag = tagRepository.getTagByName(name);
    if (existingTag != null) {
      // 사용 빈도 증가
      await tagRepository.incrementUsage(existingTag.id);
      return existingTag.id;
    }

    // 새 태그 추가
    final tag = Tag(
      id: 0,
      name: name,
      usageCount: 1,
      lastUsed: DateTime.now(),
    );

    return await tagRepository.addTag(tag);
  }

  // 태그 사용 빈도 증가
  Future<void> incrementTagUsage(int tagId) async {
    await tagRepository.incrementUsage(tagId);
  }

  // 태그 삭제
  Future<void> deleteTag(int tagId) async {
    await tagRepository.deleteTag(tagId);
  }

  // 태그 이름 수정
  Future<void> updateTagName(int tagId, String newName) async {
    final tag = tagRepository.getTag(tagId);
    if (tag != null) {
      tag.name = newName;
      await tagRepository.updateTag(tag);
    }
  }

  // === 카테고리 관련 메서드 ===

  // 카테고리 정보 가져오기
  CategoryInfo? getCategoryInfo(int categoryId) {
    final category = groupRepository.getGroup(categoryId);
    if (category == null) return null;

    return CategoryInfo(
      id: category.id,
      name: category.name,
      color: Color(category.colorValue),
    );
  }

  // 모든 카테고리 가져오기
  List<CategoryInfo> getAllCategories() {
    return groupRepository.getAllGroups().map((group) {
      return CategoryInfo(
        id: group.id,
        name: group.name,
        color: Color(group.colorValue),
      );
    }).toList();
  }

  // 새 카테고리 추가
  Future<int> addCategory(String name, Color color) async {
    final category = TagGroup(
      id: 0,
      name: name,
      colorValue: color.value,
    );

    return await groupRepository.addGroup(category);
  }

  // 카테고리 수정
  Future<void> updateCategory(int categoryId, String name, Color color) async {
    final category = groupRepository.getGroup(categoryId);
    if (category != null) {
      category.name = name;
      category.colorValue = color.value;
      await groupRepository.updateGroup(category);
    }
  }

  // 카테고리 삭제
  Future<void> deleteCategory(int categoryId) async {
    await groupRepository.deleteGroup(categoryId);
  }
}

// UI 표시용 태그 정보 클래스
class TagInfo {
  final int id;
  final String name;
  final int usageCount;
  final DateTime lastUsed;

  TagInfo({
    required this.id,
    required this.name,
    required this.usageCount,
    required this.lastUsed,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TagInfo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// UI 표시용 카테고리 정보 클래스
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

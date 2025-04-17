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
    await groupRepository.setupDefaultGroups(); // 기본 그룹 설정
  }

  // 태그 정보 가져오기 (이름과 색상)
  TagInfo? getTagInfo(int tagId) {
    final tag = tagRepository.getTag(tagId);
    if (tag == null) return null;

    final group = groupRepository.getGroup(tag.groupId);
    if (group == null) return null;

    return TagInfo(
      id: tag.id,
      name: tag.name,
      groupId: group.id,
      groupName: group.name,
      color: Color(group.colorValue),
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

  // 모든 그룹 가져오기
  List<TagGroupInfo> getAllGroupInfo() {
    return groupRepository.getAllGroups().map((group) {
      return TagGroupInfo(
        id: group.id,
        name: group.name,
        color: Color(group.colorValue),
      );
    }).toList();
  }

  // 그룹별 태그 목록 가져오기
  Map<TagGroupInfo, List<Tag>> getTagsByGroup() {
    Map<TagGroupInfo, List<Tag>> result = {};
    
    final groups = groupRepository.getAllGroups();
    for (final group in groups) {
      final groupInfo = TagGroupInfo(
        id: group.id,
        name: group.name,
        color: Color(group.colorValue),
      );
      
      final tags = tagRepository.getTagsByGroup(group.id);
      result[groupInfo] = tags;
    }
    
    return result;
  }

  // 새 태그 그룹 추가
  Future<int> addTagGroup(String name, Color color) async {
    final group = TagGroup(
      id: 0,
      name: name,
      colorValue: color.value,
    );
    
    return await groupRepository.addGroup(group);
  }

  // 새 태그 추가
  Future<int> addTag(String name, int groupId) async {
    final tag = Tag(
      id: 0,
      name: name,
      groupId: groupId,
    );
    
    return await tagRepository.addTag(tag);
  }
}

// UI 표시용 태그 정보 클래스
class TagInfo {
  final int id;
  final String name;
  final int groupId;
  final String groupName;
  final Color color;

  TagInfo({
    required this.id,
    required this.name,
    required this.groupId,
    required this.groupName,
    required this.color,
  });
}

// UI 표시용 태그 그룹 정보 클래스
class TagGroupInfo {
  final int id;
  final String name;
  final Color color;

  TagGroupInfo({
    required this.id,
    required this.name,
    required this.color,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TagGroupInfo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

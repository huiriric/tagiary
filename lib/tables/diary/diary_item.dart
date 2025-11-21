import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
part 'diary_item.g.dart';

@HiveType(typeId: 4)
class DiaryItem extends HiveObject {
  @HiveField(0)
  late int id;

  // @HiveField(1)
  // final String title;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final int? categoryId; // 카테고리 ID (일기 카테고리 - 태그와는 별개)

  @HiveField(4)
  final List<int> tagIds; // 연결된 태그 ID 목록

  DiaryItem({
    required this.id,
    // required this.title,
    required this.date,
    required this.content,
    this.categoryId,
    required this.tagIds,
  });
}

class DiaryRepository {
  static const String itemCounterKey = 'diaryItemCounter';

  late Box<DiaryItem> _item;
  late Box<int> _counter;

  Future<void> init() async {
    _item = await Hive.openBox<DiaryItem>('diaryBox');
    _counter = await Hive.openBox<int>('counterBox');
  }

  Future<int> addDiary(DiaryItem item) async {
    int currentId = _counter.get(itemCounterKey, defaultValue: 0)!;
    int newId = currentId + 1;

    item.id = newId;

    await _item.put(newId, item);
    await _counter.put(itemCounterKey, newId);

    return newId;
  }

  Future<void> updateDiary(DiaryItem item) async {
    await _item.put(item.id, item);
  }

  Future<void> deleteDiary(int id) async {
    await _item.delete(id);
  }

  DiaryItem? getItem(int id) {
    return _item.get(id);
  }

  List<DiaryItem>? getDateItem(DateTime date) {
    List<DiaryItem> list = _item.values.where((item) => item.date.year == date.year && item.date.month == date.month && item.date.day == date.day).toList();
    list.sort((a, b) => b.id.compareTo(a.id));
    return list;
  }

  // 특정 월의 다이어리 가져오기
  List<DiaryItem> getItemsByMonth(DateTime date) {
    List<DiaryItem> list = _item.values
        .where((item) => item.date.year == date.year && item.date.month == date.month)
        .toList();
    // 날짜 내림차순으로 정렬 (최신순)
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<DiaryItem> getAllItems() {
    List<DiaryItem> list = _item.values.toList();
    // 일기 최신 순으로 가져오기
    list.sort((a, b) => b.id.compareTo(a.id));
    return list;
  }

  // 카테고리별 다이어리 가져오기
  List<DiaryItem> getItemsByCategory(int categoryId) {
    List<DiaryItem> list = _item.values.where((item) => item.categoryId == categoryId).toList();
    list.sort((a, b) => b.id.compareTo(a.id));
    return list;
  }

  // 태그별 다이어리 가져오기
  List<DiaryItem> getItemsByTag(int tagId) {
    List<DiaryItem> list = _item.values.where((item) => item.tagIds.contains(tagId)).toList();
    list.sort((a, b) => b.id.compareTo(a.id));
    return list;
  }

  // 검색 기능
  List<DiaryItem> searchItems(String query) {
    String lowercaseQuery = query.toLowerCase();
    List<DiaryItem> list =
        _item.values.where((item) => item.content.toLowerCase().contains(lowercaseQuery) || item.content.toLowerCase().contains(lowercaseQuery)).toList();
    list.sort((a, b) => b.id.compareTo(a.id));
    return list;
  }

  // 선택된 달의 각 날짜별 카테고리 색상 리스트 가져오기 (같은 색상끼리 그룹화)
  Map<int, List<Color>> getCategoryColorsByDate(DateTime month, dynamic tagGroupRepository) {
    // Get all diaries for the month
    List<DiaryItem> monthDiaries = getItemsByMonth(month);

    // Group by day
    Map<int, List<DiaryItem>> diariesByDay = {};
    for (var diary in monthDiaries) {
      int day = diary.date.day;
      if (!diariesByDay.containsKey(day)) {
        diariesByDay[day] = [];
      }
      diariesByDay[day]!.add(diary);
    }

    // Convert to color list with same colors grouped
    Map<int, List<Color>> result = {};
    diariesByDay.forEach((day, diaries) {
      // Sort by categoryId to group same colors together
      diaries.sort((a, b) => (a.categoryId ?? 0).compareTo(b.categoryId ?? 0));

      result[day] = diaries
          .map((d) {
            var group = tagGroupRepository.getGroup(d.categoryId);
            return group != null ? Color(group.colorValue) : const Color(0xFF9E9E9E);
          })
          .toList();
    });

    return result;
  }
}

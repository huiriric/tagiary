import 'package:flutter/material.dart';
import 'package:mrplando/tables/color/color_item.dart';

// 앱 전체에서 사용할 색상 리스트 (동적으로 로드됨)
List<Color> scheduleColors = [];

// 색상 리스트 로드 함수
Future<void> loadScheduleColors() async {
  final colorRepo = ColorRepository();
  await colorRepo.init();
  final colorItems = colorRepo.getAllItems();
  scheduleColors = colorItems.map((item) => Color(item.colorValue)).toList();
}

// 색상 리스트 새로고침 (색상 관리 페이지에서 색상 변경 후 호출)
Future<void> refreshScheduleColors() async {
  final colorRepo = ColorRepository();
  await colorRepo.init();
  final colorItems = colorRepo.getAllItems();
  scheduleColors = colorItems.map((item) => Color(item.colorValue)).toList();
}

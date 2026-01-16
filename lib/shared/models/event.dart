import 'package:flutter/material.dart';

class Event {
  final int id;
  final int categoryId;
  final String title;
  final String description;
  final DateTime? createdAt;
  final DateTime? date; // 날짜 정보 추가
  final DateTime? endDate; // 멀티데이 이벤트를 위한 종료 날짜
  final List<bool>? daysOfWeek;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final Color color;
  final bool isRoutine;
  final bool hasTimeSet; // 시간 설정 여부
  final bool hasMultiDay; // 멀티데이 여부

  const Event({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.description,
    this.createdAt,
    this.date,
    this.endDate, // 멀티데이 이벤트를 위한 종료 날짜
    required this.daysOfWeek,
    this.startTime,
    this.endTime,
    required this.color,
    required this.isRoutine,
    this.hasTimeSet = true, // 기본값은 true
    this.hasMultiDay = false, // 멀티데이 여부 기본값은 false
  });

  // 시간을 분으로 변환 (위치 계산용)
  int get startMinutes => startTime!.hour * 60 + startTime!.minute;
  int get endMinutes => endTime!.hour * 60 + endTime!.minute;
  int get durationMinutes => endMinutes - startMinutes;
}

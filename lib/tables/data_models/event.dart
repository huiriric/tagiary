import 'package:flutter/material.dart';

class Event {
  final int id;
  final String title;
  final String description;
  final DateTime? date; // 날짜 정보 추가
  final List<bool>? daysOfWeek;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final Color color;
  final bool isRoutine;
  final bool hasTimeSet; // 시간 설정 여부

  const Event({
    required this.id,
    required this.title,
    required this.description,
    this.date,
    required this.daysOfWeek,
    this.startTime,
    this.endTime,
    required this.color,
    required this.isRoutine,
    this.hasTimeSet = true, // 기본값은 true
  });

  // 시간을 분으로 변환 (위치 계산용)
  int get startMinutes => startTime!.hour * 60 + startTime!.minute;
  int get endMinutes => endTime!.hour * 60 + endTime!.minute;
  int get durationMinutes => endMinutes - startMinutes;
}

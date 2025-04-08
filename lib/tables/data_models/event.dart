import 'package:flutter/material.dart';

class Event {
  final int id;
  final String title;
  final String description;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final Color color;
  final bool isRoutine;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.color,
    required this.isRoutine,
  });

  // 시간을 분으로 변환 (위치 계산용)
  int get startMinutes => startTime.hour * 60 + startTime.minute;
  int get endMinutes => endTime.hour * 60 + endTime.minute;
  int get durationMinutes => endMinutes - startMinutes;
}

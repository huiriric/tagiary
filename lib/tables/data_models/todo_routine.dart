import 'package:flutter/material.dart';

class TodoRoutine {
  final int id;
  final String content;
  final Color colorValue;
  final bool check;
  final DateTime updated;

  const TodoRoutine({
    required this.id,
    required this.content,
    required this.colorValue,
    required this.check,
    required this.updated,
  });
}

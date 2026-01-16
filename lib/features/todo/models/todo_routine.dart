import 'package:flutter/material.dart';

class TodoRoutine {
  final int id;
  final String content;
  final Color color;
  final bool check;
  final DateTime updated;

  const TodoRoutine({
    required this.id,
    required this.content,
    required this.color,
    required this.check,
    required this.updated,
  });
}

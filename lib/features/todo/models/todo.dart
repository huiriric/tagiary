import 'package:flutter/material.dart';

class Todo {
  final int id;
  final String content;
  final DateTime endDate;
  final Color colorValue;
  final bool check;
  final DateTime updated;

  const Todo({
    required this.id,
    required this.content,
    required this.endDate,
    required this.colorValue,
    required this.check,
    required this.updated,
  });
}

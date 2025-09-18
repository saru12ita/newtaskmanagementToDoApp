import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TaskModel {
  String id;
  String title;
  String description;
  Timestamp date;
  String? time;
  bool isDone;
  String category;
  int flagColor;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.time,
    this.isDone = false,
    this.category = 'Other',
    this.flagColor = 0xFFFF0000,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Support fallback if date is stored as String
    Timestamp taskDate;
    if (data['date'] is Timestamp) {
      taskDate = data['date'];
    } else if (data['date'] is String) {
      taskDate = Timestamp.fromDate(DateTime.parse(data['date']));
    } else {
      taskDate = Timestamp.now();
    }

    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: taskDate,
      time: data['time'],
      isDone: data['isDone'] ?? false,
      category: data['category'] ?? 'Other',
      flagColor: data['flagColor'] ?? 0xFFFF0000,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'isDone': isDone,
      'category': category,
      'flagColor': flagColor,
    };
  }
}

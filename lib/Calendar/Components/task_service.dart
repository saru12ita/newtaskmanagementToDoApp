/*

import 'package:cloud_firestore/cloud_firestore.dart';
import 'task_model.dart';

class TaskService {
  final String uid;
  late CollectionReference _taskRef;

  TaskService({required this.uid}) {
    _taskRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('tasks');
  }

  Stream<List<TaskModel>> getTasksStream() {
    return _taskRef.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => TaskModel.fromDoc(doc)).toList());
  }

  Future<void> addTask(TaskModel task) async {
    await _taskRef.add(task.toMap());
  }

  Future<void> updateTask(TaskModel task) async {
    await _taskRef.doc(task.id).update(task.toMap());
  }

  Future<void> deleteTask(String taskId) async {
    await _taskRef.doc(taskId).delete();
  }
}

*/

import 'package:cloud_firestore/cloud_firestore.dart';
import 'task_model.dart';

class TaskService {
  final String uid;
  final CollectionReference _tasksRef;

  TaskService({required this.uid})
      : _tasksRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('tasks');

  // Get tasks stream (real-time)
  Stream<List<TaskModel>> getTasksStream() {
    return _tasksRef.orderBy('date').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  // Add task
  Future<void> addTask(TaskModel task) async {
    await _tasksRef.add(task.toMap());
  }

  // Update task
  Future<void> updateTask(TaskModel task) async {
    await _tasksRef.doc(task.id).update(task.toMap());
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    await _tasksRef.doc(taskId).delete();
  }

  // Toggle isDone
  Future<void> toggleTaskDone(TaskModel task) async {
    await _tasksRef.doc(task.id).update({'isDone': !task.isDone});
  }
}

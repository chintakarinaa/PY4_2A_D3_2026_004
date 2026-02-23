import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/log_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);

  static const String _storageKey = 'user_logs_data';

  LogController() {
    loadFromDisk();
  }

  void addLog(String title, String desc) {
    if (title.isEmpty || desc.isEmpty) return;

    final newLog = LogModel(
      title: title,
      description: desc,
      date: DateTime.now().toString(),
    );

    logsNotifier.value = [...logsNotifier.value, newLog];
    saveToDisk();
  }

  void updateLog(int index, String title, String desc) {
    final current = List<LogModel>.from(logsNotifier.value);

    current[index] = LogModel(
      title: title,
      description: desc,
      date: DateTime.now().toString(),
    );

    logsNotifier.value = current;
    saveToDisk();
  }

  void removeLog(int index) {
    final current = List<LogModel>.from(logsNotifier.value);
    current.removeAt(index);
    logsNotifier.value = current;
    saveToDisk();
  }

  Future<void> saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      logsNotifier.value.map((e) => e.toMap()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);

    if (data != null) {
      final decoded = jsonDecode(data) as List;
      logsNotifier.value =
          decoded.map((e) => LogModel.fromMap(e)).toList();
    }
  }
}
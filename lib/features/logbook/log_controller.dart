import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'models/log_model.dart';
import 'package:logbook_app_004/services/mongo_service.dart';
import 'package:logbook_app_004/helpers/log_helper.dart';

class LogController {
  final String currentUser;

  LogController(this.currentUser);

  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);

  List<LogModel> get logs => logsNotifier.value;

  Future<void> fetchLogs() async {
    try {
      final data = await MongoService().getLogs(currentUser);
      logsNotifier.value = data;

      await LogHelper.writeLog(
        "SUCCESS: Fetch data untuk user $currentUser",
        source: "log_controller.dart",
        level: 3,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Fetch gagal - $e",
        source: "log_controller.dart",
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> addLog(String title, String desc, String category) async {
    final newLog = LogModel(
      id: ObjectId(),
      userId: currentUser,
      title: title,
      description: desc,
      date: DateTime.now().toIso8601String(),
      category: category,
    );

    try {
      await MongoService().insertLog(newLog);
      await fetchLogs();

      await LogHelper.writeLog(
        "SUCCESS: Tambah '$title' oleh $currentUser",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Add gagal - $e",
        source: "log_controller.dart",
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> updateLogById(
    ObjectId id,
    String title,
    String desc,
    String category,
  ) async {
    final updatedLog = LogModel(
      id: id,
      userId: currentUser,
      title: title,
      description: desc,
      date: DateTime.now().toIso8601String(),
      category: category,
    );

    try {
      await MongoService().updateLog(updatedLog);
      await fetchLogs();

      await LogHelper.writeLog(
        "SUCCESS: Update '$title' oleh $currentUser",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Update gagal - $e",
        source: "log_controller.dart",
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> deleteById(ObjectId id) async {
    try {
      await MongoService().deleteLog(id);
      await fetchLogs();

      await LogHelper.writeLog(
        "SUCCESS: Delete ID $id oleh $currentUser",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Delete gagal - $e",
        source: "log_controller.dart",
        level: 1,
      );
      rethrow;
    }
  }
}
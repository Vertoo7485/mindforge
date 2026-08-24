import 'package:flutter/material.dart';
import 'app.dart';
import 'features/finance/models/transaction_model.dart';
import 'features/planner/models/planner_database.dart';

late AppDatabase database;
late PlannerDatabase plannerDatabase;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  database = AppDatabase();
  plannerDatabase = PlannerDatabase();
  runApp(const MindForgeApp());
}

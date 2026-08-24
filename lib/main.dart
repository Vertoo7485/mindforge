import 'package:flutter/material.dart';
import 'app.dart';
import 'features/finance/models/transaction_model.dart';
import 'features/planner/models/planner_database.dart';
import 'features/rpg/models/rpg_database.dart';

late AppDatabase database;
late PlannerDatabase plannerDatabase;
late RpgDatabase rpgDatabase;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  database = AppDatabase();
  plannerDatabase = PlannerDatabase();
  rpgDatabase = RpgDatabase();
  await rpgDatabase.initAchievements();
  runApp(const MindForgeApp());
}

import 'package:flutter/material.dart';
import 'app.dart';
import 'features/finance/models/transaction_model.dart';
import 'features/planner/models/planner_database.dart';
import 'features/rpg/models/rpg_database.dart';
import 'features/workout/models/workout_database.dart';

late AppDatabase database;
late PlannerDatabase plannerDatabase;
late RpgDatabase rpgDatabase;
late WorkoutDatabase workoutDatabase;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  database = AppDatabase();
  plannerDatabase = PlannerDatabase();
  rpgDatabase = RpgDatabase();
  workoutDatabase = WorkoutDatabase();
  await rpgDatabase.initAchievements();
  runApp(const MindForgeApp());
}

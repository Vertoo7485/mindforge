import 'package:flutter/material.dart';
import 'app.dart';
import 'features/finance/models/transaction_model.dart';

late AppDatabase database;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  database = AppDatabase();
  runApp(const MindForgeApp());
}

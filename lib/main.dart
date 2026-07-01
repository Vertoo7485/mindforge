import 'package:flutter/material.dart';
import 'app.dart';
import 'features/finance/models/transaction_model.dart';

late AppDatabase database;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  database = AppDatabase();
  await _seedTestData();
  runApp(const MindForgeApp());
}

Future<void> _seedTestData() async {
  // Временно убираем проверку, чтобы заполнить тестовыми данными
  // final existing = await database.getAllTransactions();
  // if (existing.isNotEmpty) return;

  final now = DateTime.now();
  final categories = [
    'Продукты',
    'Транспорт',
    'Развлечения',
    'Здоровье',
    'Одежда',
    'Жильё',
    'Связь',
    'Кафе и рестораны',
  ];

  // Генерируем данные за 6 месяцев
  for (int monthOffset = 5; monthOffset >= 0; monthOffset--) {
    final month = now.month - monthOffset;
    final year = now.year + (month <= 0 ? -1 : 0);
    final adjustedMonth = month <= 0 ? month + 12 : month;
    final daysInMonth = DateTime(year, adjustedMonth + 1, 0).day;

    // Доходы
    await database.addTransaction(
      type: 'income',
      amount: 80000 + (monthOffset * 2000),
      category: 'Зарплата',
      date: DateTime(year, adjustedMonth, 10),
    );

    if (monthOffset % 2 == 0) {
      await database.addTransaction(
        type: 'income',
        amount: 15000.0,
        category: 'Фриланс',
        date: DateTime(year, adjustedMonth, 20),
      );
    }

    // Расходы
    for (int day = 1; day <= daysInMonth; day += (3 + (day % 5))) {
      final cat = categories[(day + monthOffset) % categories.length];
      final amount = switch (cat) {
        'Продукты' => 500.0 + (day * 17 % 2000),
        'Транспорт' => 200.0 + (day * 13 % 500),
        'Развлечения' => 1000.0 + (day * 23 % 3000),
        'Здоровье' => 1500.0 + (day * 7 % 2000),
        'Одежда' => 3000.0 + (day * 11 % 5000),
        'Жильё' => 15000.0,
        'Связь' => 600.0,
        'Кафе и рестораны' => 800.0 + (day * 19 % 2500),
        _ => 500.0,
      };

      if (cat == 'Жильё' && day > 5) continue;

      await database.addTransaction(
        type: 'expense',
        amount: amount,
        category: cat,
        date: DateTime(year, adjustedMonth, day.clamp(1, 28)),
      );
    }
  }
}

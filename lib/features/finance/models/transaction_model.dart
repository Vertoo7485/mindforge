import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'transaction_model.g.dart';

// Таблица транзакций
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // 'income' или 'expense'
  RealColumn get amount => real()();
  TextColumn get category => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Сама база данных
@DriftDatabase(tables: [Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Добавить транзакцию
  Future<void> addTransaction({
    required String type,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    await into(transactions).insert(
      TransactionsCompanion(
        type: Value(type),
        amount: Value(amount),
        category: Value(category),
        date: Value(date),
        note: Value.absentIfNull(note),
      ),
    );
  }

  // Все транзакции (новые сверху)
  Future<List<Transaction>> getAllTransactions() {
    return (select(
      transactions,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  // Удалить транзакцию
  Future<void> deleteTransaction(int id) async {
    await (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  // Баланс
  Future<double> getBalance() async {
    final query = await customSelect(
      'SELECT '
      'COALESCE(SUM(CASE WHEN type = \'income\' THEN amount ELSE -amount END), 0) as total '
      'FROM transactions',
    ).getSingle();
    return query.read<double>('total')!;
  }

  // Расходы по категориям (для диаграммы)
  Future<List<Map<String, dynamic>>> expensesByCategory() async {
    return customSelect(
      'SELECT category, SUM(amount) as total '
      'FROM transactions WHERE type = \'expense\' '
      'GROUP BY category ORDER BY total DESC',
    ).get().then(
      (rows) => rows.map((r) {
        return {
          'category': r.read<String>('category'),
          'total': r.read<double>('total'),
        };
      }).toList(),
    );
  }
}

// Открытие базы
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File('${dbFolder.path}/mindforge.db');
    return NativeDatabase.createInBackground(file);
  });
}

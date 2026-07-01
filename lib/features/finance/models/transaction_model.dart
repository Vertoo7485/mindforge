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

// Таблица бюджетов
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text().nullable()(); // null = общий бюджет
  RealColumn get amount => real()(); // сумма бюджета
  TextColumn get period => text()(); // 'monthly', 'weekly', 'yearly'
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Сама база данных
@DriftDatabase(tables: [Transactions, Budgets])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(budgets);
      }
    },
  );

  // ======== ТРАНЗАКЦИИ ========

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

  Future<List<Transaction>> getAllTransactions() {
    return (select(
      transactions,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  // Транзакции за период
  Future<List<Transaction>> getTransactionsByPeriod(
    DateTime start,
    DateTime end,
  ) {
    return (select(transactions)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<void> deleteTransaction(int id) async {
    await (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  Future<double> getBalance() async {
    final query = await customSelect(
      'SELECT '
      'COALESCE(SUM(CASE WHEN type = \'income\' THEN amount ELSE -amount END), 0) as total '
      'FROM transactions',
    ).getSingle();
    return query.read<double>('total')!;
  }

  // Доходы и расходы по месяцам (для столбчатой диаграммы)
  Future<List<Map<String, dynamic>>> monthlySummary() async {
    return customSelect(
      'SELECT '
      'strftime(\'%Y-%m\', date / 1000, \'unixepoch\') as month, '
      'SUM(CASE WHEN type = \'income\' THEN amount ELSE 0 END) as income, '
      'SUM(CASE WHEN type = \'expense\' THEN amount ELSE 0 END) as expense '
      'FROM transactions '
      'GROUP BY month ORDER BY month DESC LIMIT 6',
    ).get().then(
      (rows) => rows.map((r) {
        return {
          'month': r.read<String>('month'),
          'income': r.read<double>('income'),
          'expense': r.read<double>('expense'),
        };
      }).toList(),
    );
  }

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

  // Расходы по категориям за период
  Future<List<Map<String, dynamic>>> expensesByCategoryForPeriod(
    DateTime start,
    DateTime end,
  ) async {
    return customSelect(
      'SELECT category, SUM(amount) as total '
      'FROM transactions WHERE type = \'expense\' '
      'AND date >= ? AND date <= ? '
      'GROUP BY category ORDER BY total DESC',
      variables: [Variable.withDateTime(start), Variable.withDateTime(end)],
    ).get().then(
      (rows) => rows.map((r) {
        return {
          'category': r.read<String>('category'),
          'total': r.read<double>('total'),
        };
      }).toList(),
    );
  }

  // ======== БЮДЖЕТЫ ========

  // Добавить бюджет
  Future<void> setBudget({
    String? category,
    required double amount,
    required String period,
    required DateTime startDate,
  }) async {
    // Удаляем старый бюджет для этой категории/периода
    if (category != null) {
      await (delete(budgets)..where(
            (b) => b.category.equals(category) & b.period.equals(period),
          ))
          .go();
    } else {
      await (delete(
        budgets,
      )..where((b) => b.category.isNull() & b.period.equals(period))).go();
    }

    await into(budgets).insert(
      BudgetsCompanion(
        category: Value.absentIfNull(category),
        amount: Value(amount),
        period: Value(period),
        startDate: Value(startDate),
      ),
    );
  }

  // Получить все бюджеты
  Future<List<Budget>> getAllBudgets() {
    return select(budgets).get();
  }

  // Получить бюджет по категории
  Future<Budget?> getBudgetByCategory(String? category) {
    if (category == null) {
      return (select(budgets)
            ..where((b) => b.category.isNull())
            ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]))
          .getSingleOrNull();
    }
    return (select(budgets)
          ..where((b) => b.category.equals(category))
          ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]))
        .getSingleOrNull();
  }

  // Удалить бюджет
  Future<void> deleteBudget(int id) async {
    await (delete(budgets)..where((b) => b.id.equals(id))).go();
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

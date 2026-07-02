import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'transaction_model.g.dart';

// Таблица транзакций
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  RealColumn get amount => real()();
  TextColumn get category => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Таблица бюджетов
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text().nullable()();
  RealColumn get amount => real()();
  TextColumn get period => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Таблица целей накопления
class SavingsGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  RealColumn get targetAmount => real()();
  RealColumn get currentAmount => real().withDefault(const Constant(0))();
  DateTimeColumn get deadline => dateTime().nullable()();
  TextColumn get icon => text().withDefault(const Constant('🎯'))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Transactions, Budgets, SavingsGoals])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 3) {
        await m.createTable(savingsGoals);
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

  Future<List<Map<String, dynamic>>> monthlySummary() async {
    return customSelect(
      'SELECT '
      'strftime(\'%m\', date / 1000, \'unixepoch\') as month, '
      'strftime(\'%Y\', date / 1000, \'unixepoch\') as year, '
      'SUM(CASE WHEN type = \'income\' THEN amount ELSE 0 END) as income, '
      'SUM(CASE WHEN type = \'expense\' THEN amount ELSE 0 END) as expense '
      'FROM transactions '
      'GROUP BY year, month ORDER BY year DESC, month DESC LIMIT 6',
    ).get().then(
      (rows) => rows.map((r) {
        final y = r.read<String>('year');
        final m = r.read<String>('month');
        return {
          'month': '$y-$m',
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

  Future<void> setBudget({
    String? category,
    required double amount,
    required String period,
    required DateTime startDate,
  }) async {
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

  Future<List<Budget>> getAllBudgets() {
    return select(budgets).get();
  }

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

  Future<void> deleteBudget(int id) async {
    await (delete(budgets)..where((b) => b.id.equals(id))).go();
  }

  // ======== ЦЕЛИ НАКОПЛЕНИЯ ========

  Future<void> addSavingsGoal({
    required String title,
    required double targetAmount,
    DateTime? deadline,
    String icon = '🎯',
  }) async {
    await into(savingsGoals).insert(
      SavingsGoalsCompanion(
        title: Value(title),
        targetAmount: Value(targetAmount),
        deadline: Value.absentIfNull(deadline),
        icon: Value(icon),
      ),
    );
  }

  Future<List<SavingsGoal>> getAllSavingsGoals() {
    return (select(
      savingsGoals,
    )..orderBy([(s) => OrderingTerm.desc(s.createdAt)])).get();
  }

  Future<void> updateSavingsGoalAmount(int id, double amount) async {
    final completed =
        amount >=
        (await (select(savingsGoals)..where((s) => s.id.equals(id)))
            .getSingle()
            .then((g) => g.targetAmount));
    await (update(savingsGoals)..where((s) => s.id.equals(id))).write(
      SavingsGoalsCompanion(
        currentAmount: Value(amount),
        isCompleted: Value(completed),
      ),
    );
  }

  Future<void> deleteSavingsGoal(int id) async {
    await (delete(savingsGoals)..where((s) => s.id.equals(id))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File('${dbFolder.path}/mindforge.db');
    return NativeDatabase.createInBackground(file);
  });
}

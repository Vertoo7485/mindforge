import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'planner_database.g.dart';

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get recurrence => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Subtasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer()();
  TextColumn get title => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get icon => text().withDefault(const Constant('🔄'))();
  TextColumn get frequency => text().withDefault(const Constant('daily'))();
  IntColumn get targetCount => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class HabitCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId => integer()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  TextColumn get location => text().nullable()();
  BoolColumn get isAllDay => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Tasks, Subtasks, Habits, HabitCompletions, Events])
class PlannerDatabase extends _$PlannerDatabase {
  PlannerDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(subtasks);
      }
    },
  );

  // ======== ЗАДАЧИ ========

  Future<void> addTask({
    required String title,
    String? description,
    String priority = 'medium',
    DateTime? dueDate,
    String? recurrence,
  }) async {
    await into(tasks).insert(
      TasksCompanion(
        title: Value(title),
        description: Value.absentIfNull(description),
        priority: Value(priority),
        dueDate: Value.absentIfNull(dueDate),
        recurrence: Value.absentIfNull(recurrence),
      ),
    );
  }

  Future<List<Task>> getTasksForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    await _generateRecurringTasksForDate(startOfDay);
    return (select(tasks)
          ..where(
            (t) =>
                t.dueDate.isBiggerOrEqualValue(startOfDay) &
                t.dueDate.isSmallerThanValue(endOfDay),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.isCompleted),
            (t) => OrderingTerm.asc(t.priority),
          ]))
        .get();
  }

  Future<List<Task>> getAllTasks() =>
      (select(tasks)..orderBy([
            (t) => OrderingTerm.asc(t.isCompleted),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
          .get();

  Future<void> toggleTask(int id, bool isCompleted) async {
    await (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isCompleted: Value(isCompleted),
        completedAt: Value(isCompleted ? DateTime.now() : null),
      ),
    );
  }

  Future<void> deleteTask(int id) async {
    await (delete(subtasks)..where((s) => s.taskId.equals(id))).go();
    await (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  Future<void> completeRecurringTask(Task task) async {
    if (task.isCompleted) {
      await toggleTask(task.id, false);
      return;
    }
    await toggleTask(task.id, true);
    if (task.recurrence != null && task.dueDate != null) {
      DateTime nextDate = task.dueDate!;
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      switch (task.recurrence) {
        case 'daily':
          nextDate = nextDate.add(const Duration(days: 1));
          break;
        case 'weekly':
          nextDate = nextDate.add(const Duration(days: 7));
          break;
        case 'weekdays':
          do {
            nextDate = nextDate.add(const Duration(days: 1));
          } while (nextDate.weekday == 6 || nextDate.weekday == 7);
          break;
        case 'weekends':
          do {
            nextDate = nextDate.add(const Duration(days: 1));
          } while (nextDate.weekday != 6 && nextDate.weekday != 7);
          break;
        default:
          return;
      }
      if (nextDate.isAfter(today)) {
        await addTask(
          title: task.title,
          description: task.description,
          priority: task.priority,
          dueDate: nextDate,
          recurrence: task.recurrence,
        );
      }
    }
  }

  Future<void> rescheduleTask(Task task, DateTime newDate) async {
    await addTask(
      title: task.title,
      description: task.description,
      priority: task.priority,
      dueDate: newDate,
      recurrence: null,
    );
    await deleteTask(task.id);
  }

  // ======== ПОДЗАДАЧИ ========

  Future<void> addSubtask({required int taskId, required String title}) async {
    await into(
      subtasks,
    ).insert(SubtasksCompanion(taskId: Value(taskId), title: Value(title)));
  }

  Future<List<Subtask>> getSubtasks(int taskId) =>
      (select(subtasks)
            ..where((s) => s.taskId.equals(taskId))
            ..orderBy([(s) => OrderingTerm.asc(s.isCompleted)]))
          .get();

  Future<void> toggleSubtask(int id, bool isCompleted) async {
    await (update(subtasks)..where((s) => s.id.equals(id))).write(
      SubtasksCompanion(isCompleted: Value(isCompleted)),
    );

    // Если отметили как выполненную — проверяем, все ли подзадачи готовы
    if (isCompleted) {
      final sub = await (select(
        subtasks,
      )..where((s) => s.id.equals(id))).getSingle();
      final allSubtasks = await getSubtasks(sub.taskId);
      if (allSubtasks.every((s) => s.isCompleted)) {
        await toggleTask(sub.taskId, true);
      }
    } else {
      // Если сняли отметку — снимаем и с задачи
      final sub = await (select(
        subtasks,
      )..where((s) => s.id.equals(id))).getSingle();
      final task = await (select(
        tasks,
      )..where((t) => t.id.equals(sub.taskId))).getSingle();
      if (task.isCompleted) {
        await toggleTask(sub.taskId, false);
      }
    }
  }

  Future<void> deleteSubtask(int id) async =>
      await (delete(subtasks)..where((s) => s.id.equals(id))).go();

  // ======== ГЕНЕРАЦИЯ ПОВТОРЯЮЩИХСЯ ЗАДАЧ ========

  Future<void> _generateRecurringTasksForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final allRecurring =
        await (select(tasks)
              ..where(
                (t) =>
                    t.recurrence.isNotNull() &
                    t.dueDate.isSmallerThanValue(startOfDay),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.dueDate)]))
            .get();
    final seen = <String>{};
    for (final task in allRecurring) {
      final key = '${task.title}_${task.recurrence}';
      if (seen.contains(key)) continue;
      seen.add(key);
      if (_shouldTaskAppearOnDate(task, date)) {
        final existing =
            await (select(tasks)..where(
                  (t) =>
                      t.title.equals(task.title) &
                      t.dueDate.isBiggerOrEqualValue(startOfDay) &
                      t.dueDate.isSmallerThanValue(endOfDay),
                ))
                .get();
        if (existing.isEmpty) {
          await addTask(
            title: task.title,
            description: task.description,
            priority: task.priority,
            dueDate: date,
            recurrence: task.recurrence,
          );
        }
      }
    }
  }

  bool _shouldTaskAppearOnDate(Task task, DateTime date) {
    if (task.dueDate == null || task.recurrence == null) return false;
    final dueDate = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
    );
    final checkDate = DateTime(date.year, date.month, date.day);
    if (checkDate.isBefore(dueDate) || checkDate == dueDate) return false;
    switch (task.recurrence) {
      case 'daily':
        return true;
      case 'weekly':
        return checkDate.difference(dueDate).inDays % 7 == 0;
      case 'weekdays':
        return checkDate.weekday != 6 && checkDate.weekday != 7;
      case 'weekends':
        return checkDate.weekday == 6 || checkDate.weekday == 7;
      default:
        return false;
    }
  }

  // ======== ПРИВЫЧКИ ========

  Future<int> addHabit({
    required String name,
    String? description,
    String icon = '🔄',
    String frequency = 'daily',
    int targetCount = 1,
  }) async {
    return await into(habits).insert(
      HabitsCompanion(
        name: Value(name),
        description: Value.absentIfNull(description),
        icon: Value(icon),
        frequency: Value(frequency),
        targetCount: Value(targetCount),
      ),
    );
  }

  Future<List<Habit>> getAllHabits() => select(habits).get();

  Future<void> deleteHabit(int id) async {
    await (delete(habitCompletions)..where((h) => h.habitId.equals(id))).go();
    await (delete(habits)..where((h) => h.id.equals(id))).go();
  }

  Future<void> toggleHabitForDate(int habitId, DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);
    final nextDay = day.add(const Duration(days: 1));
    final existing =
        await (select(habitCompletions)..where(
              (h) =>
                  h.habitId.equals(habitId) &
                  h.date.isBetweenValues(day, nextDay),
            ))
            .get();
    if (existing.isNotEmpty) {
      await (delete(
        habitCompletions,
      )..where((h) => h.id.equals(existing.first.id))).go();
    } else {
      await into(habitCompletions).insert(
        HabitCompletionsCompanion(habitId: Value(habitId), date: Value(day)),
      );
    }
  }

  Future<bool> isHabitDoneForDate(int habitId, DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);
    final nextDay = day.add(const Duration(days: 1));
    return (await (select(habitCompletions)..where(
              (h) =>
                  h.habitId.equals(habitId) &
                  h.date.isBetweenValues(day, nextDay),
            ))
            .get())
        .isNotEmpty;
  }

  Future<int> getHabitStreakForDate(int habitId, DateTime date) async {
    final habit = await (select(
      habits,
    )..where((h) => h.id.equals(habitId))).getSingleOrNull();
    if (habit == null) return 0;
    final completions =
        await (select(habitCompletions)
              ..where((h) => h.habitId.equals(habitId))
              ..orderBy([(h) => OrderingTerm.desc(h.date)]))
            .get();
    if (completions.isEmpty) return 0;
    if (habit.frequency == 'daily' ||
        habit.frequency == 'weekdays' ||
        habit.frequency == 'weekends') {
      int streak = 0;
      DateTime checkDate = DateTime(date.year, date.month, date.day);
      for (final c in completions) {
        final d = DateTime(c.date.year, c.date.month, c.date.day);
        if (d == checkDate) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else if (d == checkDate.subtract(const Duration(days: 1))) {
          streak++;
          checkDate = d.subtract(const Duration(days: 1));
        } else
          break;
      }
      return streak;
    }
    if (habit.frequency == 'custom') {
      final ws = DateTime(
        date.year,
        date.month,
        date.day,
      ).subtract(Duration(days: date.weekday - 1));
      return completions.where((c) {
        final d = DateTime(c.date.year, c.date.month, c.date.day);
        return d.isAfter(ws.subtract(const Duration(days: 1))) &&
            d.isBefore(ws.add(const Duration(days: 7)));
      }).length;
    }
    return 0;
  }

  // ======== ВСТРЕЧИ ========

  Future<void> addEvent({
    required String title,
    String? description,
    required DateTime startTime,
    DateTime? endTime,
    String? location,
    bool isAllDay = false,
  }) async {
    await into(events).insert(
      EventsCompanion(
        title: Value(title),
        description: Value.absentIfNull(description),
        startTime: Value(startTime),
        endTime: Value.absentIfNull(endTime),
        location: Value.absentIfNull(location),
        isAllDay: Value(isAllDay),
      ),
    );
  }

  Future<List<Event>> getEventsForDate(DateTime date) {
    final s = DateTime(date.year, date.month, date.day);
    return (select(events)
          ..where(
            (e) =>
                e.startTime.isBetweenValues(s, s.add(const Duration(days: 1))),
          )
          ..orderBy([(e) => OrderingTerm.asc(e.startTime)]))
        .get();
  }

  Future<void> deleteEvent(int id) async =>
      await (delete(events)..where((e) => e.id.equals(id))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return NativeDatabase.createInBackground(
      File('${dbFolder.path}/mindforge_planner.db'),
    );
  });
}

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

@DriftDatabase(tables: [Tasks, Habits, HabitCompletions, Events])
class PlannerDatabase extends _$PlannerDatabase {
  PlannerDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<void> addTask({
    required String title,
    String? description,
    String priority = 'medium',
    DateTime? dueDate,
    String? recurrence,
  }) async {
    print('📝 ADD TASK: $title | dueDate: $dueDate | recurrence: $recurrence');
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
    print('📅 GET TASKS for: ${date.day}.${date.month}.${date.year}');
    print('   start: $startOfDay, end: $endOfDay');

    await _generateRecurringTasksForDate(startOfDay);

    final result =
        await (select(tasks)
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
    print('📅 Found ${result.length} tasks');
    for (final t in result) {
      print(
        '   - id:${t.id} "${t.title}" dueDate:${t.dueDate?.day}.${t.dueDate?.month} dueTime:${t.dueDate?.hour}:${t.dueDate?.minute} recurrence:${t.recurrence}',
      );
    }
    return result;
  }

  Future<List<Task>> getAllTasks() {
    return (select(tasks)..orderBy([
          (t) => OrderingTerm.asc(t.isCompleted),
          (t) => OrderingTerm.desc(t.createdAt),
        ]))
        .get();
  }

  Future<void> toggleTask(int id, bool isCompleted) async {
    await (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isCompleted: Value(isCompleted),
        completedAt: Value(isCompleted ? DateTime.now() : null),
      ),
    );
  }

  Future<void> deleteTask(int id) async {
    print('🗑️ DELETE TASK id: $id');
    await (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  Future<void> completeRecurringTask(Task task) async {
    print('✅ COMPLETE TASK: ${task.title} | isCompleted: ${task.isCompleted}');
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
        print(
          '✅ Creating next recurring task for: ${nextDate.day}.${nextDate.month}.${nextDate.year}',
        );
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
    print(
      '📌 RESCHEDULE: ${task.title} (id: ${task.id}) from ${task.dueDate?.day}.${task.dueDate?.month} to ${newDate.day}.${newDate.month}',
    );

    // Создаём новую задачу на новую дату без повторения
    await addTask(
      title: task.title,
      description: task.description,
      priority: task.priority,
      dueDate: newDate,
      recurrence: null,
    );

    // Удаляем исходную
    await deleteTask(task.id);
  }

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

    print(
      '🔄 GENERATE for ${date.day}.${date.month}: found ${allRecurring.length} recurring tasks',
    );

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

        print(
          '🔄 Task "${task.title}": should appear=${_shouldTaskAppearOnDate(task, date)}, existing=${existing.length}',
        );

        if (existing.isEmpty) {
          print('🔄 CREATING: ${task.title} for ${date.day}.${date.month}');
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

  Future<void> addHabit({
    required String name,
    String? description,
    String icon = '🔄',
    String frequency = 'daily',
    int targetCount = 1,
  }) async {
    await into(habits).insert(
      HabitsCompanion(
        name: Value(name),
        description: Value.absentIfNull(description),
        icon: Value(icon),
        frequency: Value(frequency),
        targetCount: Value(targetCount),
      ),
    );
  }

  Future<List<Habit>> getAllHabits() {
    return select(habits).get();
  }

  Future<void> deleteHabit(int id) async {
    await (delete(habitCompletions)..where((h) => h.habitId.equals(id))).go();
    await (delete(habits)..where((h) => h.id.equals(id))).go();
  }

  Future<void> toggleHabitToday(int habitId) async {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final existing =
        await (select(habitCompletions)..where(
              (h) =>
                  h.habitId.equals(habitId) &
                  h.date.isBetweenValues(
                    today,
                    today.add(const Duration(days: 1)),
                  ),
            ))
            .get();

    if (existing.isNotEmpty) {
      await (delete(
        habitCompletions,
      )..where((h) => h.id.equals(existing.first.id))).go();
    } else {
      await into(habitCompletions).insert(
        HabitCompletionsCompanion(habitId: Value(habitId), date: Value(today)),
      );
    }
  }

  Future<bool> isHabitDoneToday(int habitId) async {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final result =
        await (select(habitCompletions)..where(
              (h) =>
                  h.habitId.equals(habitId) &
                  h.date.isBetweenValues(
                    today,
                    today.add(const Duration(days: 1)),
                  ),
            ))
            .get();
    return result.isNotEmpty;
  }

  Future<int> getHabitStreak(int habitId) async {
    final completions =
        await (select(habitCompletions)
              ..where((h) => h.habitId.equals(habitId))
              ..orderBy([(h) => OrderingTerm.desc(h.date)]))
            .get();

    if (completions.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    for (final completion in completions) {
      final completionDate = DateTime(
        completion.date.year,
        completion.date.month,
        completion.date.day,
      );
      if (completionDate == checkDate) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (completionDate ==
          checkDate.subtract(const Duration(days: 1))) {
        streak++;
        checkDate = completionDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
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
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(events)
          ..where((e) => e.startTime.isBetweenValues(startOfDay, endOfDay))
          ..orderBy([(e) => OrderingTerm.asc(e.startTime)]))
        .get();
  }

  Future<void> deleteEvent(int id) async {
    await (delete(events)..where((e) => e.id.equals(id))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File('${dbFolder.path}/mindforge_planner.db');
    print('📁 DB path: ${file.path}');
    return NativeDatabase.createInBackground(file);
  });
}

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
  TextColumn get color => text().withDefault(const Constant('blue'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Tasks, Subtasks, Habits, HabitCompletions, Events])
class PlannerDatabase extends _$PlannerDatabase {
  PlannerDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(subtasks);
      if (from < 3) await m.addColumn(events, events.color);
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
    final s = DateTime(date.year, date.month, date.day),
        e = s.add(const Duration(days: 1));
    await _generateRecurringTasksForDate(s);
    return (select(tasks)
          ..where(
            (t) =>
                t.dueDate.isBiggerOrEqualValue(s) &
                t.dueDate.isSmallerThanValue(e),
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

  Future<void> toggleTask(int id, bool c) async {
    await (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isCompleted: Value(c),
        completedAt: Value(c ? DateTime.now() : null),
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
      DateTime n = task.dueDate!;
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      switch (task.recurrence) {
        case 'daily':
          n = n.add(const Duration(days: 1));
          break;
        case 'weekly':
          n = n.add(const Duration(days: 7));
          break;
        case 'weekdays':
          do {
            n = n.add(const Duration(days: 1));
          } while (n.weekday == 6 || n.weekday == 7);
          break;
        case 'weekends':
          do {
            n = n.add(const Duration(days: 1));
          } while (n.weekday != 6 && n.weekday != 7);
          break;
        default:
          return;
      }
      if (n.isAfter(today))
        await addTask(
          title: task.title,
          description: task.description,
          priority: task.priority,
          dueDate: n,
          recurrence: task.recurrence,
        );
    }
  }

  Future<void> rescheduleTask(Task task, DateTime nd) async {
    await addTask(
      title: task.title,
      description: task.description,
      priority: task.priority,
      dueDate: nd,
      recurrence: null,
    );
    await deleteTask(task.id);
  }

  // ======== ПОДЗАДАЧИ ========

  Future<void> addSubtask({required int taskId, required String title}) async =>
      await into(
        subtasks,
      ).insert(SubtasksCompanion(taskId: Value(taskId), title: Value(title)));

  Future<List<Subtask>> getSubtasks(int taskId) =>
      (select(subtasks)
            ..where((s) => s.taskId.equals(taskId))
            ..orderBy([(s) => OrderingTerm.asc(s.isCompleted)]))
          .get();

  Future<void> toggleSubtask(int id, bool c) async {
    await (update(subtasks)..where((s) => s.id.equals(id))).write(
      SubtasksCompanion(isCompleted: Value(c)),
    );
    final sub = await (select(
      subtasks,
    )..where((s) => s.id.equals(id))).getSingle();
    if (c) {
      if ((await getSubtasks(sub.taskId)).every((s) => s.isCompleted))
        await toggleTask(sub.taskId, true);
    } else {
      if ((await (select(
        tasks,
      )..where((t) => t.id.equals(sub.taskId))).getSingle()).isCompleted)
        await toggleTask(sub.taskId, false);
    }
  }

  Future<void> deleteSubtask(int id) async =>
      await (delete(subtasks)..where((s) => s.id.equals(id))).go();

  // ======== ГЕНЕРАЦИЯ ========

  Future<void> _generateRecurringTasksForDate(DateTime date) async {
    final s = DateTime(date.year, date.month, date.day),
        e = s.add(const Duration(days: 1));
    final all =
        await (select(tasks)
              ..where(
                (t) =>
                    t.recurrence.isNotNull() & t.dueDate.isSmallerThanValue(s),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.dueDate)]))
            .get();
    final seen = <String>{};
    for (final t in all) {
      final key = '${t.title}_${t.recurrence}';
      if (seen.contains(key)) continue;
      seen.add(key);
      if (_shouldTaskAppear(t, date)) {
        if ((await (select(tasks)..where(
                  (x) =>
                      x.title.equals(t.title) &
                      x.dueDate.isBiggerOrEqualValue(s) &
                      x.dueDate.isSmallerThanValue(e),
                ))
                .get())
            .isEmpty) {
          await addTask(
            title: t.title,
            description: t.description,
            priority: t.priority,
            dueDate: date,
            recurrence: t.recurrence,
          );
        }
      }
    }
  }

  bool _shouldTaskAppear(Task t, DateTime d) {
    if (t.dueDate == null || t.recurrence == null) return false;
    final dd = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day),
        cd = DateTime(d.year, d.month, d.day);
    if (cd.isBefore(dd) || cd == dd) return false;
    switch (t.recurrence) {
      case 'daily':
        return true;
      case 'weekly':
        return cd.difference(dd).inDays % 7 == 0;
      case 'weekdays':
        return cd.weekday != 6 && cd.weekday != 7;
      case 'weekends':
        return cd.weekday == 6 || cd.weekday == 7;
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
  }) async => await into(habits).insert(
    HabitsCompanion(
      name: Value(name),
      description: Value.absentIfNull(description),
      icon: Value(icon),
      frequency: Value(frequency),
      targetCount: Value(targetCount),
    ),
  );

  Future<List<Habit>> getAllHabits() => select(habits).get();

  Future<void> deleteHabit(int id) async {
    await (delete(habitCompletions)..where((h) => h.habitId.equals(id))).go();
    await (delete(habits)..where((h) => h.id.equals(id))).go();
  }

  Future<void> toggleHabitForDate(int habitId, DateTime date) async {
    final d = DateTime(date.year, date.month, date.day);
    final ex =
        await (select(habitCompletions)..where(
              (h) =>
                  h.habitId.equals(habitId) &
                  h.date.isBetweenValues(d, d.add(const Duration(days: 1))),
            ))
            .get();
    if (ex.isNotEmpty) {
      await (delete(
        habitCompletions,
      )..where((h) => h.id.equals(ex.first.id))).go();
    } else {
      await into(habitCompletions).insert(
        HabitCompletionsCompanion(habitId: Value(habitId), date: Value(d)),
      );
    }
  }

  Future<bool> isHabitDoneForDate(int habitId, DateTime date) async {
    final d = DateTime(date.year, date.month, date.day);
    return (await (select(habitCompletions)..where(
              (h) =>
                  h.habitId.equals(habitId) &
                  h.date.isBetweenValues(d, d.add(const Duration(days: 1))),
            ))
            .get())
        .isNotEmpty;
  }

  Future<int> getHabitStreakForDate(int habitId, DateTime date) async {
    final h = await (select(
      habits,
    )..where((x) => x.id.equals(habitId))).getSingleOrNull();
    if (h == null) return 0;
    final comps =
        await (select(habitCompletions)
              ..where((x) => x.habitId.equals(habitId))
              ..orderBy([(x) => OrderingTerm.desc(x.date)]))
            .get();
    if (comps.isEmpty) return 0;
    if (h.frequency == 'daily' ||
        h.frequency == 'weekdays' ||
        h.frequency == 'weekends') {
      int s = 0;
      DateTime ck = DateTime(date.year, date.month, date.day);
      for (final c in comps) {
        final cd = DateTime(c.date.year, c.date.month, c.date.day);
        if (cd == ck) {
          s++;
          ck = ck.subtract(const Duration(days: 1));
        } else if (cd == ck.subtract(const Duration(days: 1))) {
          s++;
          ck = cd.subtract(const Duration(days: 1));
        } else
          break;
      }
      return s;
    }
    if (h.frequency == 'custom') {
      final ws = DateTime(
        date.year,
        date.month,
        date.day,
      ).subtract(Duration(days: date.weekday - 1));
      return comps.where((c) {
        final d = DateTime(c.date.year, c.date.month, c.date.day);
        return d.isAfter(ws.subtract(const Duration(days: 1))) &&
            d.isBefore(ws.add(const Duration(days: 7)));
      }).length;
    }
    return 0;
  }

  Future<Set<DateTime>> getHabitCompletionsForWeek(
    int habitId,
    DateTime date,
  ) async {
    final ws = DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
    return (await (select(habitCompletions)..where(
              (h) =>
                  h.habitId.equals(habitId) &
                  h.date.isBetweenValues(ws, ws.add(const Duration(days: 7))),
            ))
            .get())
        .map((c) => DateTime(c.date.year, c.date.month, c.date.day))
        .toSet();
  }

  // ======== ВСТРЕЧИ ========

  Future<void> addEvent({
    required String title,
    String? description,
    required DateTime startTime,
    DateTime? endTime,
    String? location,
    bool isAllDay = false,
    String color = 'blue',
  }) async {
    await into(events).insert(
      EventsCompanion(
        title: Value(title),
        description: Value.absentIfNull(description),
        startTime: Value(startTime),
        endTime: Value.absentIfNull(endTime),
        location: Value.absentIfNull(location),
        isAllDay: Value(isAllDay),
        color: Value(color),
      ),
    );
  }

  Future<void> updateEvent({
    required int id,
    required String title,
    String? description,
    required DateTime startTime,
    DateTime? endTime,
    String? location,
    bool isAllDay = false,
    String color = 'blue',
  }) async {
    await (update(events)..where((e) => e.id.equals(id))).write(
      EventsCompanion(
        title: Value(title),
        description: Value.absentIfNull(description),
        startTime: Value(startTime),
        endTime: Value.absentIfNull(endTime),
        location: Value.absentIfNull(location),
        isAllDay: Value(isAllDay),
        color: Value(color),
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

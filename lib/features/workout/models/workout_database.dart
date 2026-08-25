import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'workout_database.g.dart';

class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get muscleGroup => text()();
  TextColumn get equipment => text().withDefault(const Constant('none'))();
  TextColumn get description => text().nullable()();
  TextColumn get icon => text().withDefault(const Constant('💪'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class WorkoutPrograms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get type => text().withDefault(const Constant('custom'))();
  TextColumn get icon => text().withDefault(const Constant('🏋️'))();
  IntColumn get durationMinutes => integer().withDefault(const Constant(30))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class ProgramExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get programId => integer()();
  IntColumn get exerciseId => integer()();
  IntColumn get sets => integer().withDefault(const Constant(3))();
  IntColumn get reps => integer().withDefault(const Constant(12))();
  IntColumn get restSeconds => integer().withDefault(const Constant(60))();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
}

class WorkoutLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get programId => integer().nullable()();
  TextColumn get name => text()();
  IntColumn get durationMinutes => integer()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(
  tables: [Exercises, WorkoutPrograms, ProgramExercises, WorkoutLogs],
)
class WorkoutDatabase extends _$WorkoutDatabase {
  WorkoutDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ======== УПРАЖНЕНИЯ ========

  Future<int> addExercise({
    required String name,
    required String muscleGroup,
    String equipment = 'none',
    String? description,
    String icon = '💪',
  }) async {
    return await into(exercises).insert(
      ExercisesCompanion(
        name: Value(name),
        muscleGroup: Value(muscleGroup),
        equipment: Value(equipment),
        description: Value.absentIfNull(description),
        icon: Value(icon),
      ),
    );
  }

  Future<List<Exercise>> getAllExercises() => select(exercises).get();

  Future<Exercise?> getExerciseById(int id) async {
    return await (select(
      exercises,
    )..where((e) => e.id.equals(id))).getSingleOrNull();
  }

  Future<List<Exercise>> getExercisesForProgram(int programId) async {
    final peList = await getProgramExercises(programId);
    final result = <Exercise>[];
    for (final pe in peList) {
      final ex = await getExerciseById(pe.exerciseId);
      if (ex != null) result.add(ex);
    }
    return result;
  }

  Future<void> deleteExercise(int id) async {
    await (delete(exercises)..where((e) => e.id.equals(id))).go();
  }

  // ======== ПРОГРАММЫ ========

  Future<int> createProgram({
    required String name,
    String? description,
    String type = 'custom',
    String icon = '🏋️',
    int durationMinutes = 30,
  }) async {
    return await into(workoutPrograms).insert(
      WorkoutProgramsCompanion(
        name: Value(name),
        description: Value.absentIfNull(description),
        type: Value(type),
        icon: Value(icon),
        durationMinutes: Value(durationMinutes),
      ),
    );
  }

  Future<List<WorkoutProgram>> getAllPrograms() =>
      select(workoutPrograms).get();

  Future<List<WorkoutProgram>> getReadyPrograms() =>
      (select(workoutPrograms)..where((w) => w.type.equals('ready'))).get();

  Future<List<WorkoutProgram>> getCustomPrograms() =>
      (select(workoutPrograms)..where((w) => w.type.equals('custom'))).get();

  Future<void> deleteProgram(int id) async {
    await (delete(
      programExercises,
    )..where((pe) => pe.programId.equals(id))).go();
    await (delete(workoutPrograms)..where((w) => w.id.equals(id))).go();
  }

  // ======== УПРАЖНЕНИЯ В ПРОГРАММЕ ========

  Future<void> addExerciseToProgram({
    required int programId,
    required int exerciseId,
    int sets = 3,
    int reps = 12,
    int restSeconds = 60,
    required int orderIndex,
  }) async {
    await into(programExercises).insert(
      ProgramExercisesCompanion(
        programId: Value(programId),
        exerciseId: Value(exerciseId),
        sets: Value(sets),
        reps: Value(reps),
        restSeconds: Value(restSeconds),
        orderIndex: Value(orderIndex),
      ),
    );
  }

  Future<List<ProgramExercise>> getProgramExercises(int programId) =>
      (select(programExercises)
            ..where((pe) => pe.programId.equals(programId))
            ..orderBy([(pe) => OrderingTerm.asc(pe.orderIndex)]))
          .get();

  Future<void> deleteProgramExercise(int id) async {
    await (delete(programExercises)..where((pe) => pe.id.equals(id))).go();
  }

  // ======== ИСТОРИЯ ========

  Future<void> logWorkout({
    int? programId,
    required String name,
    required int durationMinutes,
    required DateTime date,
  }) async {
    await into(workoutLogs).insert(
      WorkoutLogsCompanion(
        programId: Value.absentIfNull(programId),
        name: Value(name),
        durationMinutes: Value(durationMinutes),
        date: Value(date),
      ),
    );
  }

  Future<List<WorkoutLog>> getRecentWorkouts() =>
      (select(workoutLogs)..orderBy([(w) => OrderingTerm.desc(w.date)])).get();

  Future<int> getWorkoutCountForWeek(DateTime date) async {
    final ws = DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
    final logs = await (select(
      workoutLogs,
    )..where((w) => w.date.isBiggerOrEqualValue(ws))).get();
    return logs.length;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return NativeDatabase.createInBackground(
      File('${dbFolder.path}/mindforge_workout.db'),
    );
  });
}

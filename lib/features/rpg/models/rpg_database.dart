import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'rpg_database.g.dart';

class Character extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withDefault(const Constant('Воин'))();
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get xp => integer().withDefault(const Constant(0))();
  IntColumn get xpToNextLevel => integer().withDefault(const Constant(100))();
  TextColumn get avatar => text().withDefault(const Constant('⚔️'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Attributes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get value => integer().withDefault(const Constant(1))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Achievements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get icon => text().withDefault(const Constant('🏆'))();
  BoolColumn get isUnlocked => boolean().withDefault(const Constant(false))();
  DateTimeColumn get unlockedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Character, Attributes, Achievements])
class RpgDatabase extends _$RpgDatabase {
  RpgDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ======== ПЕРСОНАЖ ========

  Future<CharacterData> getCharacter() async {
    final existing = await (select(
      character,
    )..orderBy([(c) => OrderingTerm.asc(c.id)])).getSingleOrNull();
    if (existing != null) return existing;
    await into(character).insert(CharacterCompanion());
    return (await select(character).getSingle());
  }

  Future<void> addXp(int amount) async {
    final char = await getCharacter();
    var newXp = char.xp + amount;
    var newLevel = char.level;
    var xpToNext = char.xpToNextLevel;

    while (newXp >= xpToNext) {
      newXp -= xpToNext;
      newLevel++;
      xpToNext = (xpToNext * 1.5).round();
    }

    await (update(character)..where((c) => c.id.equals(char.id))).write(
      CharacterCompanion(
        xp: Value(newXp),
        level: Value(newLevel),
        xpToNextLevel: Value(xpToNext),
      ),
    );
  }

  Future<void> addXpWithAttribute(int amount, String attribute) async {
    await addXp(amount);
    await increaseAttribute(attribute, 1);
  }

  // ======== АТРИБУТЫ ========

  Future<void> initAttributes() async {
    final existing = await select(attributes).get();
    if (existing.isNotEmpty) return;
    final defaults = ['strength', 'wisdom', 'resource', 'energy', 'balance'];
    for (final name in defaults) {
      await into(attributes).insert(AttributesCompanion(name: Value(name)));
    }
  }

  Future<List<Attribute>> getAttributes() async {
    await initAttributes();
    return select(attributes).get();
  }

  Future<void> increaseAttribute(String name, int amount) async {
    final attr = await (select(
      attributes,
    )..where((a) => a.name.equals(name))).getSingleOrNull();
    if (attr != null) {
      await (update(attributes)..where((a) => a.id.equals(attr.id))).write(
        AttributesCompanion(
          value: Value(attr.value + amount),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  // ======== ДОСТИЖЕНИЯ ========

  Future<List<Achievement>> getAchievements() => select(achievements).get();

  Future<void> unlockAchievement(int id) async {
    final existing = await (select(
      achievements,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
    if (existing != null && !existing.isUnlocked) {
      await (update(achievements)..where((a) => a.id.equals(id))).write(
        AchievementsCompanion(
          isUnlocked: const Value(true),
          unlockedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> initAchievements() async {
    final existing = await select(achievements).get();
    if (existing.isNotEmpty) return;

    final defs = [
      {
        'title': 'Первые шаги',
        'description': 'Выполните первую задачу',
        'icon': '🎯',
      },
      {
        'title': 'Транжира',
        'description': 'Добавьте первый расход',
        'icon': '💸',
      },
      {
        'title': 'Капиталист',
        'description': 'Добавьте первый доход',
        'icon': '💰',
      },
      {
        'title': 'Пламенная серия',
        'description': 'Отмечайте привычку 7 дней подряд',
        'icon': '🔥',
      },
      {
        'title': 'Продуктивный день',
        'description': 'Выполните 5 задач за день',
        'icon': '⚔️',
      },
      {
        'title': 'Путь воина',
        'description': 'Достигните 2 уровня',
        'icon': '🏆',
      },
      {
        'title': 'Финансовый маг',
        'description': 'Достигните 5 уровня',
        'icon': '🧙',
      },
      {
        'title': 'Мастер задач',
        'description': 'Выполните 50 задач',
        'icon': '✅',
      },
      {
        'title': 'Король привычек',
        'description': 'Отметьте 100 привычек',
        'icon': '👑',
      },
      {
        'title': 'Накопитель',
        'description': 'Создайте цель накопления',
        'icon': '🎯',
      },
      {
        'title': 'Мечтатель',
        'description': 'Достигните цели накопления',
        'icon': '✨',
      },
      {
        'title': 'Борец с долгами',
        'description': 'Погасите долг полностью',
        'icon': '🛡️',
      },
      {
        'title': 'Планировщик',
        'description': 'Создайте 10 задач',
        'icon': '📋',
      },
      {
        'title': 'Аналитик',
        'description': 'Добавьте 20 транзакций',
        'icon': '📊',
      },
      {
        'title': 'Стрелок',
        'description': 'Выполните задачу с высоким приоритетом',
        'icon': '🎪',
      },
      {
        'title': 'Рутинный герой',
        'description': 'Создайте привычку',
        'icon': '🔄',
      },
      {
        'title': 'Бюджетный гуру',
        'description': 'Установите бюджет',
        'icon': '💼',
      },
      {
        'title': 'Воин выходного дня',
        'description': 'Выполните задачу в выходной',
        'icon': '⚡',
      },
      {
        'title': 'Ранняя пташка',
        'description': 'Выполните задачу до 9 утра',
        'icon': '🌅',
      },
      {
        'title': 'Ночной страж',
        'description': 'Выполните задачу после 22:00',
        'icon': '🌙',
      },
    ];

    for (final def in defs) {
      await into(achievements).insert(
        AchievementsCompanion(
          title: Value(def['title']!),
          description: Value(def['description']!),
          icon: Value(def['icon']!),
        ),
      );
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return NativeDatabase.createInBackground(
      File('${dbFolder.path}/mindforge_rpg.db'),
    );
  });
}

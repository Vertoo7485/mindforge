import 'package:flutter/material.dart';
import '../../../main.dart';
import '../models/workout_database.dart';
import 'active_workout_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  List<WorkoutProgram> _programs = [];
  List<WorkoutLog> _recentWorkouts = [];
  int _weekWorkouts = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _initReadyPrograms();
  }

  Future<void> _initReadyPrograms() async {
    final ready = await workoutDatabase.getReadyPrograms();
    if (ready.isEmpty) {
      await _createReadyPrograms();
    }
    _load();
  }

  Future<void> _createReadyPrograms() async {
    final homeProgramId = await workoutDatabase.createProgram(
      name: 'Домашняя тренировка',
      description: 'Без оборудования, 30 минут',
      type: 'ready',
      icon: '🏠',
      durationMinutes: 30,
    );

    final exercises = [
      {
        'name': 'Разминка',
        'muscleGroup': 'fullbody',
        'icon': '🤸',
        'sets': 1,
        'reps': 5,
        'rest': 0,
        'description':
            'Лёгкий бег на месте, махи руками, наклоны, круговые движения головой и плечами. 5 минут.',
      },
      {
        'name': 'Отжимания',
        'muscleGroup': 'chest',
        'icon': '💪',
        'sets': 3,
        'reps': 15,
        'rest': 60,
        'description':
            'Классические отжимания от пола. Держите тело ровным, опускайтесь до прямого угла в локтях.',
      },
      {
        'name': 'Приседания',
        'muscleGroup': 'legs',
        'icon': '🦵',
        'sets': 3,
        'reps': 20,
        'rest': 60,
        'description':
            'Ноги на ширине плеч, спина прямая. Опускайтесь до параллели с полом, пятки не отрывайте.',
      },
      {
        'name': 'Планка',
        'muscleGroup': 'core',
        'icon': '🧘',
        'sets': 3,
        'reps': 45,
        'rest': 45,
        'description':
            'Держите прямую линию от головы до пяток. Напрягите пресс и ягодицы. Держите 45 секунд.',
      },
      {
        'name': 'Выпады',
        'muscleGroup': 'legs',
        'icon': '🚶',
        'sets': 3,
        'reps': 12,
        'rest': 60,
        'description':
            'Шаг вперёд, опускайтесь до прямого угла в обоих коленях. Чередуйте ноги.',
      },
      {
        'name': 'Скручивания',
        'muscleGroup': 'core',
        'icon': '🔄',
        'sets': 3,
        'reps': 20,
        'rest': 45,
        'description':
            'Лёжа на спине, руки за головой. Поднимайте плечи, напрягая пресс. Не тяните шею.',
      },
      {
        'name': 'Заминка',
        'muscleGroup': 'fullbody',
        'icon': '🧘',
        'sets': 1,
        'reps': 5,
        'rest': 0,
        'description':
            'Лёгкая растяжка всех групп мышц. Плавные движения, задерживайтесь в растяжке на 15-20 секунд.',
      },
    ];

    for (int i = 0; i < exercises.length; i++) {
      final ex = exercises[i];
      final exerciseId = await workoutDatabase.addExercise(
        name: ex['name'] as String,
        muscleGroup: ex['muscleGroup'] as String,
        icon: ex['icon'] as String,
        description: ex['description'] as String,
      );
      await workoutDatabase.addExerciseToProgram(
        programId: homeProgramId,
        exerciseId: exerciseId,
        sets: ex['sets'] as int,
        reps: ex['reps'] as int,
        restSeconds: ex['rest'] as int,
        orderIndex: i,
      );
    }
  }

  Future<void> _load() async {
    final programs = await workoutDatabase.getAllPrograms();
    final recent = await workoutDatabase.getRecentWorkouts();
    final weekCount = await workoutDatabase.getWorkoutCountForWeek(
      DateTime.now(),
    );

    setState(() {
      _programs = programs;
      _recentWorkouts = recent.take(5).toList();
      _weekWorkouts = weekCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final readyPrograms = _programs.where((p) => p.type == 'ready').toList();
    final customPrograms = _programs.where((p) => p.type == 'custom').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренировки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Создать программу',
            onPressed: () => _createCustomProgram(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatsCard(weekWorkouts: _weekWorkouts),
          const SizedBox(height: 24),
          const Text(
            'ГОТОВЫЕ ПРОГРАММЫ',
            style: TextStyle(fontSize: 12, letterSpacing: 2),
          ),
          const SizedBox(height: 12),
          ...readyPrograms.map(
            (p) => _ProgramCard(program: p, onTap: () => _openProgram(p)),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'СВОИ ПРОГРАММЫ',
                style: TextStyle(fontSize: 12, letterSpacing: 2),
              ),
              TextButton(
                onPressed: () => _createCustomProgram(),
                child: const Text('+ Создать'),
              ),
            ],
          ),
          if (customPrograms.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Нет своих программ',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...customPrograms.map(
              (p) => _ProgramCard(program: p, onTap: () => _openProgram(p)),
            ),
          const SizedBox(height: 24),
          if (_recentWorkouts.isNotEmpty) ...[
            const Text(
              'ПОСЛЕДНИЕ ТРЕНИРОВКИ',
              style: TextStyle(fontSize: 12, letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            ..._recentWorkouts.map(
              (w) => ListTile(
                leading: const Icon(
                  Icons.check_circle,
                  color: Colors.greenAccent,
                ),
                title: Text(w.name),
                subtitle: Text(
                  '${w.durationMinutes} мин · ${w.date.day}.${w.date.month}.${w.date.year}',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _createCustomProgram() async {
    final nameController = TextEditingController();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новая программа'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Название программы'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, {
                  'name': nameController.text.trim() as String,
                });
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );

    if (result != null) {
      await workoutDatabase.createProgram(
        name: result['name'] as String,
        type: 'custom',
      );
      _load();
    }
  }

  Future<void> _openProgram(WorkoutProgram program) async {
    final exercises = await workoutDatabase.getExercisesForProgram(program.id);
    final exerciseInfo = await workoutDatabase.getProgramExercises(program.id);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveWorkoutScreen(
          program: program,
          exercises: exercises,
          exerciseInfo: exerciseInfo,
        ),
      ),
    ).then((_) => _load());
  }
}

class _StatsCard extends StatelessWidget {
  final int weekWorkouts;
  const _StatsCard({required this.weekWorkouts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'ТРЕНИРОВКИ НА ЭТОЙ НЕДЕЛЕ',
            style: TextStyle(fontSize: 12, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(
            '$weekWorkouts',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.orangeAccent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Цель: 3-4 тренировки',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final WorkoutProgram program;
  final VoidCallback onTap;
  const _ProgramCard({required this.program, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(program.icon, style: const TextStyle(fontSize: 20)),
          ),
        ),
        title: Text(
          program.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${program.durationMinutes} мин · ${program.type == 'ready' ? 'Готовая' : 'Своя'}',
        ),
        trailing: const Icon(Icons.play_arrow),
        onTap: onTap,
      ),
    );
  }
}

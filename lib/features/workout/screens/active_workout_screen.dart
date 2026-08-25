import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../main.dart';
import '../models/workout_database.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final WorkoutProgram program;
  final List<Exercise> exercises;
  final List<ProgramExercise> exerciseInfo;

  const ActiveWorkoutScreen({
    super.key,
    required this.program,
    required this.exercises,
    required this.exerciseInfo,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  int _currentExerciseIndex = 0;
  int _currentSet = 0;
  bool _isResting = false;
  int _restSeconds = 0;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playBeep() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
    } catch (e) {
      HapticFeedback.mediumImpact();
    }
  }

  void _startRest(int seconds) {
    setState(() {
      _isResting = true;
      _restSeconds = seconds;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSeconds <= 0) {
        timer.cancel();
        _playBeep();
        setState(() {
          _isResting = false;
        });
        _nextExercise();
      } else {
        setState(() {
          _restSeconds--;
        });
      }
    });
  }

  void _nextExercise() {
    final info = widget.exerciseInfo[_currentExerciseIndex];

    if (_currentSet < info.sets - 1) {
      setState(() {
        _currentSet++;
      });
    } else if (_currentExerciseIndex < widget.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSet = 0;
      });
    } else {
      _finishWorkout();
    }
  }

  Future<void> _finishWorkout() async {
    _timer?.cancel();
    _playBeep();
    await workoutDatabase.logWorkout(
      programId: widget.program.id,
      name: widget.program.name,
      durationMinutes: widget.program.durationMinutes,
      date: DateTime.now(),
    );
    await rpgDatabase.addXpWithAttribute(15, 'energy');

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.program.name} — завершена! +15 XP, +1 Энергия'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleButtonPress() {
    final info = widget.exerciseInfo[_currentExerciseIndex];
    final isLastSet = _currentSet == info.sets - 1;
    final isLastExercise = _currentExerciseIndex == widget.exercises.length - 1;

    if (isLastSet && isLastExercise) {
      _finishWorkout();
    } else {
      _startRest(info.restSeconds);
    }
  }

  String _getNextLabel() {
    final info = widget.exerciseInfo[_currentExerciseIndex];
    if (_currentSet < info.sets - 1) {
      return 'Следующее: ${widget.exercises[_currentExerciseIndex].name} — подход ${_currentSet + 2}';
    } else if (_currentExerciseIndex < widget.exercises.length - 1) {
      return 'Следующее: ${widget.exercises[_currentExerciseIndex + 1].name}';
    } else {
      return 'Последний подход!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercises[_currentExerciseIndex];
    final info = widget.exerciseInfo[_currentExerciseIndex];

    final totalSteps = widget.exercises.fold<int>(
      0,
      (sum, e) => sum + widget.exerciseInfo[widget.exercises.indexOf(e)].sets,
    );
    final completedSteps = widget.exercises
        .take(_currentExerciseIndex)
        .fold<int>(0, (sum, e) => sum + widget.exerciseInfo[widget.exercises.indexOf(e)].sets) +
        _currentSet +
        (_isResting ? 0 : 1);

    return Scaffold(
      appBar: AppBar(title: Text(widget.program.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: completedSteps / totalSteps,
                  minHeight: 6,
                  backgroundColor: Colors.grey[800],
                  valueColor: const AlwaysStoppedAnimation(Colors.orangeAccent),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_currentExerciseIndex + 1} / ${widget.exercises.length} упражнений',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isResting) ...[
                  Text(
                    'ОТДЫХ',
                    style: TextStyle(fontSize: 24, letterSpacing: 3, color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Text('$_restSeconds', style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Text(_getNextLabel(), style: TextStyle(fontSize: 16, color: Colors.grey[400])),
                  const SizedBox(height: 8),
                  Text('Подготовьтесь...', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                ] else ...[
                  Text(exercise.icon, style: const TextStyle(fontSize: 72)),
                  const SizedBox(height: 16),
                  Text(exercise.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  if (exercise.description != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(exercise.description!, style: TextStyle(fontSize: 14, color: Colors.grey[400]), textAlign: TextAlign.center),
                    ),
                  const SizedBox(height: 16),
                  Text('Подход ${_currentSet + 1} из ${info.sets}', style: TextStyle(fontSize: 18, color: Colors.grey[400])),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text('${info.reps}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                        Text('повторений', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isResting ? null : _handleButtonPress,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orangeAccent,
                  disabledBackgroundColor: Colors.grey[700],
                ),
                child: Text(
                  _isResting ? 'Отдых...' : 'Подход выполнен',
                  style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          if (_isResting)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextButton(
                onPressed: () {
                  _timer?.cancel();
                  _playBeep();
                  setState(() => _isResting = false);
                  _nextExercise();
                },
                child: Text('Пропустить отдых', style: TextStyle(color: Colors.grey[400])),
              ),
            ),
        ],
      ),
    );
  }
}
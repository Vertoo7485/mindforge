import 'package:flutter/material.dart';
import '../../../main.dart';
import '../models/planner_database.dart';
import '../models/habit_days_service.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});
  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  List<Task> _tasks = [];
  List<Habit> _habits = [];
  List<Event> _events = [];
  DateTime _selectedDate = DateTime.now();
  bool _showHabits = true;
  final _quickAddController = TextEditingController();
  Set<int> _activeHabitIds = {};

  final List<String> _habitIcons = [
    '🏃',
    '💪',
    '📚',
    '🧘',
    '💧',
    '🍎',
    '😴',
    '🚭',
    '💊',
    '🎯',
    '✍️',
    '🧹',
    '🚿',
    '💭',
    '⏰',
    '🔄',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _quickAddController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final tasks = await plannerDatabase.getTasksForDate(_selectedDate);
    final habits = await plannerDatabase.getAllHabits();
    final events = await plannerDatabase.getEventsForDate(_selectedDate);
    final activeIds = <int>{};
    for (final h in habits) {
      if (await _isHabitActiveOnDate(h, _selectedDate)) activeIds.add(h.id);
    }
    setState(() {
      _tasks = tasks;
      _habits = habits;
      _events = events;
      _activeHabitIds = activeIds;
    });
  }

  Future<void> _addTask() async {
    final titleController = TextEditingController();
    String priority = 'medium';
    String? recurrence;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Новая задача'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Название'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                const Text('Приоритет', style: TextStyle(color: Colors.grey)),
                Row(
                  children: [
                    _PriorityChip(
                      label: 'Низкий',
                      color: Colors.greenAccent,
                      selected: priority == 'low',
                      onTap: () => setDialogState(() => priority = 'low'),
                    ),
                    _PriorityChip(
                      label: 'Средний',
                      color: Colors.orangeAccent,
                      selected: priority == 'medium',
                      onTap: () => setDialogState(() => priority = 'medium'),
                    ),
                    _PriorityChip(
                      label: 'Высокий',
                      color: Colors.redAccent,
                      selected: priority == 'high',
                      onTap: () => setDialogState(() => priority = 'high'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Повторение', style: TextStyle(color: Colors.grey)),
                Wrap(
                  spacing: 4,
                  children: [
                    _RecurrenceChip(
                      label: 'Нет',
                      selected: recurrence == null,
                      onTap: () => setDialogState(() => recurrence = null),
                    ),
                    _RecurrenceChip(
                      label: 'Ежедневно',
                      selected: recurrence == 'daily',
                      onTap: () => setDialogState(() => recurrence = 'daily'),
                    ),
                    _RecurrenceChip(
                      label: 'Еженедельно',
                      selected: recurrence == 'weekly',
                      onTap: () => setDialogState(() => recurrence = 'weekly'),
                    ),
                    _RecurrenceChip(
                      label: 'Будни',
                      selected: recurrence == 'weekdays',
                      onTap: () =>
                          setDialogState(() => recurrence = 'weekdays'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty)
                  Navigator.pop(context, {
                    'title': titleController.text.trim(),
                    'priority': priority,
                    'recurrence': recurrence,
                  });
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      await plannerDatabase.addTask(
        title: result['title'],
        priority: result['priority'],
        dueDate: _selectedDate,
        recurrence: result['recurrence'],
      );
      _loadData();
    }
  }

  Future<void> _quickAddTask() async {
    final text = _quickAddController.text.trim();
    if (text.isEmpty) return;
    await plannerDatabase.addTask(
      title: text,
      priority: 'medium',
      dueDate: _selectedDate,
    );
    _quickAddController.clear();
    _loadData();
  }

  Future<void> _addHabit() async {
    final nameController = TextEditingController();
    String icon = '🔄', frequency = 'daily';
    int targetCount = 1;
    Set<int> customDays = {1, 2, 3, 4, 5};

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Новая привычка'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название привычки',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text('Иконка', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _habitIcons.map((e) {
                    final isSelected = icon == e;
                    return GestureDetector(
                      onTap: () => setDialogState(() => icon = e),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.2)
                              : Colors.grey[800],
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),
                        child: Center(
                          child: Text(e, style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Частота', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: [
                    _FrequencyChip(
                      label: 'Ежедневно',
                      selected: frequency == 'daily',
                      onTap: () => setDialogState(() {
                        frequency = 'daily';
                        targetCount = 1;
                      }),
                    ),
                    _FrequencyChip(
                      label: 'По будням',
                      selected: frequency == 'weekdays',
                      onTap: () => setDialogState(() {
                        frequency = 'weekdays';
                        targetCount = 1;
                      }),
                    ),
                    _FrequencyChip(
                      label: 'По выходным',
                      selected: frequency == 'weekends',
                      onTap: () => setDialogState(() {
                        frequency = 'weekends';
                        targetCount = 1;
                      }),
                    ),
                    _FrequencyChip(
                      label: 'Свой график',
                      selected: frequency == 'custom',
                      onTap: () => setDialogState(() {
                        frequency = 'custom';
                      }),
                    ),
                  ],
                ),
                if (frequency == 'custom') ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Выберите дни недели:',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']
                        .asMap()
                        .entries
                        .map((entry) {
                          final dayIndex = entry.key + 1;
                          final selected = customDays.contains(dayIndex);
                          return _DayChip(
                            label: entry.value,
                            selected: selected,
                            onTap: () {
                              setDialogState(() {
                                if (selected) {
                                  customDays.remove(dayIndex);
                                } else {
                                  customDays.add(dayIndex);
                                }
                                targetCount = customDays.length;
                              });
                            },
                          );
                        })
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Выбрано дней: $targetCount',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty)
                  Navigator.pop(context, {
                    'name': nameController.text.trim(),
                    'icon': icon,
                    'frequency': frequency,
                    'targetCount': targetCount,
                    'customDays': frequency == 'custom'
                        ? customDays.toList()
                        : null,
                  });
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      final habitId = await plannerDatabase.addHabit(
        name: result['name'],
        icon: result['icon'],
        frequency: result['frequency'],
        targetCount: result['targetCount'],
      );
      if (result['frequency'] == 'custom' && result['customDays'] != null) {
        await HabitDaysService.setDays(
          habitId,
          (result['customDays'] as List).map((e) => e as int).toSet(),
        );
      }
      _loadData();
    }
  }

  Future<bool> _isHabitActiveOnDate(Habit habit, DateTime date) async {
    final weekday = date.weekday;
    switch (habit.frequency) {
      case 'daily':
        return true;
      case 'weekdays':
        return weekday != 6 && weekday != 7;
      case 'weekends':
        return weekday == 6 || weekday == 7;
      case 'custom':
        final days = await HabitDaysService.getDays(habit.id);
        return days.contains(weekday);
      default:
        return true;
    }
  }

  Future<void> _addEvent() async {
    final titleController = TextEditingController(),
        locationController = TextEditingController();
    TimeOfDay startTime = TimeOfDay.now();
    bool isAllDay = false;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Новая встреча'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Название'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Место',
                    hintText: 'Необязательно',
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Весь день'),
                  value: isAllDay,
                  onChanged: (v) => setDialogState(() => isAllDay = v),
                  contentPadding: EdgeInsets.zero,
                ),
                if (!isAllDay) ...[
                  ListTile(
                    title: const Text('Время'),
                    subtitle: Text(startTime.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (picked != null)
                        setDialogState(() => startTime = picked);
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty)
                  Navigator.pop(context, {
                    'title': titleController.text.trim(),
                    'location': locationController.text.trim().isEmpty
                        ? null
                        : locationController.text.trim(),
                    'isAllDay': isAllDay,
                    'startTime': startTime,
                  });
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        result['isAllDay'] ? 0 : (result['startTime'] as TimeOfDay).hour,
        result['isAllDay'] ? 0 : (result['startTime'] as TimeOfDay).minute,
      );
      await plannerDatabase.addEvent(
        title: result['title'],
        location: result['location'],
        startTime: startDateTime,
        isAllDay: result['isAllDay'],
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}';
    final isToday =
        _selectedDate.day == DateTime.now().day &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.year == DateTime.now().year;
    final completedCount = _tasks.where((t) => t.isCompleted).length,
        totalCount = _tasks.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(isToday ? 'Сегодня' : dateStr),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                _loadData();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (totalCount > 0) ...[
            _DayProgress(completed: completedCount, total: totalCount),
            const SizedBox(height: 20),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ЗАДАЧИ',
                style: TextStyle(fontSize: 12, letterSpacing: 2),
              ),
              IconButton(
                icon: const Icon(Icons.add_task),
                tooltip: 'Добавить задачу с настройками',
                onPressed: _addTask,
              ),
            ],
          ),
          if (_tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Нет задач на этот день',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._tasks.map(
              (task) => Dismissible(
                key: Key('task_${task.id}'),
                direction: DismissDirection.horizontal,
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    await plannerDatabase.completeRecurringTask(task);
                    _loadData();
                    return false;
                  } else {
                    await plannerDatabase.deleteTask(task.id);
                    _loadData();
                    return true;
                  }
                },
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    task.isCompleted ? Icons.undo : Icons.check,
                    color: Colors.greenAccent,
                  ),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.redAccent),
                ),
                child: _TaskCard(
                  task: task,
                  onToggle: () async {
                    await plannerDatabase.completeRecurringTask(task);
                    _loadData();
                  },
                  onRescheduleToDate: (DateTime date) async {
                    await plannerDatabase.rescheduleTask(task, date);
                    _loadData();
                  },
                ),
              ),
            ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => setState(() => _showHabits = !_showHabits),
                child: Row(
                  children: [
                    Text(
                      'ПРИВЫЧКИ',
                      style: TextStyle(fontSize: 12, letterSpacing: 2),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showHabits ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Добавить привычку',
                onPressed: _addHabit,
              ),
            ],
          ),
          if (_showHabits) ...[
            if (_habits.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Нет привычек',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ..._habits
                  .where((h) => _activeHabitIds.contains(h.id))
                  .map(
                    (habit) => _HabitCard(
                      habit: habit,
                      selectedDate: _selectedDate,
                      onTap: () async {
                        await plannerDatabase.toggleHabitForDate(
                          habit.id,
                          _selectedDate,
                        );
                        _loadData();
                      },
                      onDelete: () async {
                        await plannerDatabase.deleteHabit(habit.id);
                        await HabitDaysService.delete(habit.id);
                        _loadData();
                      },
                    ),
                  ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ВСТРЕЧИ',
                style: TextStyle(fontSize: 12, letterSpacing: 2),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Добавить встречу',
                onPressed: _addEvent,
              ),
            ],
          ),
          if (_events.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Нет встреч', style: TextStyle(color: Colors.grey)),
            )
          else
            ..._events.map(
              (event) => _EventCard(
                event: event,
                onDelete: () async {
                  await plannerDatabase.deleteEvent(event.id);
                  _loadData();
                },
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
      bottomSheet: Container(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quickAddController,
                    decoration: InputDecoration(
                      hintText: 'Быстрое добавление задачи...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: Colors.grey[900],
                    ),
                    onSubmitted: (_) => _quickAddTask(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _quickAddTask,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DayProgress extends StatelessWidget {
  final int completed, total;
  const _DayProgress({required this.completed, required this.total});
  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? completed / total : 0.0;
    final color = percent == 1.0
        ? Colors.greenAccent
        : percent > 0.5
        ? Colors.orangeAccent
        : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ПРОГРЕСС ДНЯ',
                style: TextStyle(fontSize: 12, letterSpacing: 2),
              ),
              Text(
                '$completed из $total задач',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          if (percent == 1.0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '🎉 Всё сделано!',
                style: TextStyle(color: Colors.greenAccent, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final Function(DateTime) onRescheduleToDate;
  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onRescheduleToDate,
  });
  @override
  Widget build(BuildContext context) {
    final priorityColor = switch (task.priority) {
      'high' => Colors.redAccent,
      'medium' => Colors.orangeAccent,
      _ => Colors.greenAccent,
    };
    return Card(
      child: InkWell(
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_calendar),
                    title: const Text('Перенести на другую дату'),
                    onTap: () async {
                      Navigator.pop(context);
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: task.dueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) onRescheduleToDate(picked);
                    },
                  ),
                ],
              ),
            ),
          );
        },
        child: ListTile(
          leading: GestureDetector(
            onTap: onToggle,
            child: Icon(
              task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
              color: task.isCompleted ? Colors.greenAccent : Colors.grey,
            ),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted ? Colors.grey : null,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (task.recurrence != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.repeat, size: 16, color: Colors.grey[600]),
                ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: priorityColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitCard extends StatefulWidget {
  final Habit habit;
  final DateTime selectedDate;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _HabitCard({
    required this.habit,
    required this.selectedDate,
    required this.onTap,
    required this.onDelete,
  });
  @override
  State<_HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<_HabitCard> {
  bool _isDone = false;
  int _streak = 0;
  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final isDone = await plannerDatabase.isHabitDoneForDate(
      widget.habit.id,
      widget.selectedDate,
    );
    final streak = await plannerDatabase.getHabitStreakForDate(
      widget.habit.id,
      widget.selectedDate,
    );
    if (mounted)
      setState(() {
        _isDone = isDone;
        _streak = streak;
      });
  }

  @override
  Widget build(BuildContext context) {
    String subtitle;
    if (widget.habit.frequency == 'custom') {
      subtitle = _streak >= widget.habit.targetCount
          ? '✅ ${widget.habit.targetCount}/${widget.habit.targetCount} на этой неделе'
          : '$_streak/${widget.habit.targetCount} на этой неделе';
    } else {
      subtitle = _streak > 0
          ? '🔥 $_streak ${_daysWord(_streak)} подряд'
          : 'Начните сегодня';
    }
    return Card(
      child: ListTile(
        leading: GestureDetector(
          onTap: () {
            widget.onTap();
            _loadStatus();
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _isDone
                  ? Colors.greenAccent.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                widget.habit.icon,
                style: TextStyle(
                  fontSize: 20,
                  color: _isDone ? Colors.greenAccent : Colors.grey,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          widget.habit.name,
          style: TextStyle(color: _isDone ? Colors.greenAccent : null),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: _streak > 0 ? Colors.orangeAccent : Colors.grey,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          color: Colors.grey,
          onPressed: widget.onDelete,
        ),
      ),
    );
  }

  String _daysWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'день';
    if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100))
      return 'дня';
    return 'дней';
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onDelete;
  const _EventCard({required this.event, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    final timeStr = event.isAllDay
        ? 'Весь день'
        : '${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')}';
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Icon(Icons.event, color: Colors.blueAccent),
          ),
        ),
        title: Text(event.title),
        subtitle: Row(
          children: [
            Text(timeStr),
            if (event.location != null) ...[
              const Text(' · '),
              Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  event.location!,
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          color: Colors.grey,
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _PriorityChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 4),
    child: FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      selectedColor: color.withValues(alpha: 0.3),
      checkmarkColor: color,
      onSelected: (_) => onTap(),
    ),
  );
}

class _RecurrenceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RecurrenceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 4),
    child: FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      selectedColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.3),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      onSelected: (_) => onTap(),
    ),
  );
}

class _FrequencyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FrequencyChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 4, bottom: 4),
    child: FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      selectedColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.3),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      onSelected: (_) => onTap(),
    ),
  );
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 4, bottom: 4),
    child: FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      selectedColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.3),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      onSelected: (_) => onTap(),
    ),
  );
}

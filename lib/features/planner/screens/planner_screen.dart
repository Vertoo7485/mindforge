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
  final _habitIcons = [
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
  final _eventColors = {
    'blue': Colors.blueAccent,
    'red': Colors.redAccent,
    'green': Colors.greenAccent,
    'orange': Colors.orangeAccent,
    'purple': Colors.purpleAccent,
  };

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
    final t = await plannerDatabase.getTasksForDate(_selectedDate);
    final h = await plannerDatabase.getAllHabits();
    final e = await plannerDatabase.getEventsForDate(_selectedDate);
    final ids = <int>{};
    for (final x in h) {
      if (await _isHabitActiveOnDate(x, _selectedDate)) ids.add(x.id);
    }
    setState(() {
      _tasks = t;
      _habits = h;
      _events = e;
      _activeHabitIds = ids;
    });
  }

  Future<void> _addTask() async {
    final tc = TextEditingController();
    String p = 'medium';
    String? r;
    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, sd) => AlertDialog(
          title: const Text('Новая задача'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tc,
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
                      selected: p == 'low',
                      onTap: () => sd(() => p = 'low'),
                    ),
                    _PriorityChip(
                      label: 'Средний',
                      color: Colors.orangeAccent,
                      selected: p == 'medium',
                      onTap: () => sd(() => p = 'medium'),
                    ),
                    _PriorityChip(
                      label: 'Высокий',
                      color: Colors.redAccent,
                      selected: p == 'high',
                      onTap: () => sd(() => p = 'high'),
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
                      selected: r == null,
                      onTap: () => sd(() => r = null),
                    ),
                    _RecurrenceChip(
                      label: 'Ежедневно',
                      selected: r == 'daily',
                      onTap: () => sd(() => r = 'daily'),
                    ),
                    _RecurrenceChip(
                      label: 'Еженедельно',
                      selected: r == 'weekly',
                      onTap: () => sd(() => r = 'weekly'),
                    ),
                    _RecurrenceChip(
                      label: 'Будни',
                      selected: r == 'weekdays',
                      onTap: () => sd(() => r = 'weekdays'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                if (tc.text.trim().isNotEmpty)
                  Navigator.pop(c, {
                    'title': tc.text.trim(),
                    'priority': p,
                    'recurrence': r,
                  });
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
    if (res != null) {
      await plannerDatabase.addTask(
        title: res['title'],
        priority: res['priority'],
        dueDate: _selectedDate,
        recurrence: res['recurrence'],
      );
      _loadData();
    }
  }

  Future<void> _quickAddTask() async {
    final t = _quickAddController.text.trim();
    if (t.isEmpty) return;
    await plannerDatabase.addTask(
      title: t,
      priority: 'medium',
      dueDate: _selectedDate,
    );
    _quickAddController.clear();
    _loadData();
  }

  Future<void> _openSubtasks(Task t) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SubtasksScreen(task: t)),
    );
    _loadData();
  }

  Future<void> _addHabit() async {
    final nc = TextEditingController();
    String i = '🔄', f = 'daily';
    int tc = 1;
    Set<int> cd = {1, 2, 3, 4, 5};
    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, sd) => AlertDialog(
          title: const Text('Новая привычка'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nc,
                  decoration: const InputDecoration(labelText: 'Название'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text('Иконка', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _habitIcons.map((e) {
                    final s = i == e;
                    return GestureDetector(
                      onTap: () => sd(() => i = e),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: s
                              ? Theme.of(
                                  c,
                                ).colorScheme.primary.withValues(alpha: 0.2)
                              : Colors.grey[800],
                          borderRadius: BorderRadius.circular(10),
                          border: s
                              ? Border.all(
                                  color: Theme.of(c).colorScheme.primary,
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
                      selected: f == 'daily',
                      onTap: () => sd(() {
                        f = 'daily';
                        tc = 1;
                      }),
                    ),
                    _FrequencyChip(
                      label: 'По будням',
                      selected: f == 'weekdays',
                      onTap: () => sd(() {
                        f = 'weekdays';
                        tc = 1;
                      }),
                    ),
                    _FrequencyChip(
                      label: 'По выходным',
                      selected: f == 'weekends',
                      onTap: () => sd(() {
                        f = 'weekends';
                        tc = 1;
                      }),
                    ),
                    _FrequencyChip(
                      label: 'Свой график',
                      selected: f == 'custom',
                      onTap: () => sd(() {
                        f = 'custom';
                      }),
                    ),
                  ],
                ),
                if (f == 'custom') ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Выберите дни:',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']
                        .asMap()
                        .entries
                        .map((e) {
                          final d = e.key + 1;
                          final sel = cd.contains(d);
                          return _DayChip(
                            label: e.value,
                            selected: sel,
                            onTap: () {
                              sd(() {
                                if (sel)
                                  cd.remove(d);
                                else
                                  cd.add(d);
                                tc = cd.length;
                              });
                            },
                          );
                        })
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Выбрано: $tc',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                if (nc.text.trim().isNotEmpty)
                  Navigator.pop(c, {
                    'name': nc.text.trim(),
                    'icon': i,
                    'frequency': f,
                    'targetCount': tc,
                    'customDays': f == 'custom' ? cd.toList() : null,
                  });
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
    if (res != null) {
      final hid = await plannerDatabase.addHabit(
        name: res['name'],
        icon: res['icon'],
        frequency: res['frequency'],
        targetCount: res['targetCount'],
      );
      if (res['frequency'] == 'custom' && res['customDays'] != null) {
        await HabitDaysService.setDays(
          hid,
          (res['customDays'] as List).map((e) => e as int).toSet(),
        );
      }
      _loadData();
    }
  }

  Future<bool> _isHabitActiveOnDate(Habit h, DateTime d) async {
    final w = d.weekday;
    switch (h.frequency) {
      case 'daily':
        return true;
      case 'weekdays':
        return w != 6 && w != 7;
      case 'weekends':
        return w == 6 || w == 7;
      case 'custom':
        return (await HabitDaysService.getDays(h.id)).contains(w);
      default:
        return true;
    }
  }

  Future<void> _addOrEditEvent({Event? existing}) async {
    final tc = TextEditingController(text: existing?.title ?? '');
    final lc = TextEditingController(text: existing?.location ?? '');
    TimeOfDay st = existing != null && !existing.isAllDay
        ? TimeOfDay(
            hour: existing.startTime.hour,
            minute: existing.startTime.minute,
          )
        : TimeOfDay.now();
    TimeOfDay? et = existing?.endTime != null
        ? TimeOfDay(
            hour: existing!.endTime!.hour,
            minute: existing.endTime!.minute,
          )
        : null;
    bool allDay = existing?.isAllDay ?? false;
    String color = existing?.color ?? 'blue';
    bool hasEndTime = existing?.endTime != null;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, sd) => AlertDialog(
          title: Text(existing != null ? 'Редактировать' : 'Новая встреча'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tc,
                  decoration: const InputDecoration(labelText: 'Название'),
                  autofocus: existing == null,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lc,
                  decoration: const InputDecoration(
                    labelText: 'Место',
                    hintText: 'Необязательно',
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Весь день'),
                  value: allDay,
                  onChanged: (v) => sd(() => allDay = v),
                  contentPadding: EdgeInsets.zero,
                ),
                if (!allDay) ...[
                  ListTile(
                    title: const Text('Начало'),
                    subtitle: Text(st.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final p = await showTimePicker(
                        context: context,
                        initialTime: st,
                      );
                      if (p != null) sd(() => st = p);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Время окончания'),
                    value: hasEndTime,
                    onChanged: (v) {
                      sd(() {
                        hasEndTime = v;
                        if (v && et == null)
                          et = TimeOfDay(hour: st.hour + 1, minute: st.minute);
                        if (!v) et = null;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (hasEndTime)
                    ListTile(
                      title: const Text('Окончание'),
                      subtitle: Text(et!.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final p = await showTimePicker(
                          context: context,
                          initialTime: et!,
                        );
                        if (p != null) sd(() => et = p);
                      },
                    ),
                ],
                const SizedBox(height: 12),
                const Text('Цвет', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _eventColors.entries
                      .map(
                        (e) => GestureDetector(
                          onTap: () => sd(() => color = e.key),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: e.value,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color == e.key
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
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
                if (tc.text.trim().isNotEmpty)
                  Navigator.pop(context, {
                    'title': tc.text.trim(),
                    'location': lc.text.trim().isEmpty ? null : lc.text.trim(),
                    'isAllDay': allDay,
                    'startTime': st,
                    'endTime': hasEndTime ? et : null,
                    'color': color,
                  });
              },
              child: Text(existing != null ? 'Сохранить' : 'Добавить'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final sdt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        result['isAllDay'] ? 0 : (result['startTime'] as TimeOfDay).hour,
        result['isAllDay'] ? 0 : (result['startTime'] as TimeOfDay).minute,
      );
      final edt = result['endTime'] != null
          ? DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              (result['endTime'] as TimeOfDay).hour,
              (result['endTime'] as TimeOfDay).minute,
            )
          : null;
      if (existing != null) {
        await plannerDatabase.updateEvent(
          id: existing.id,
          title: result['title'],
          location: result['location'],
          startTime: sdt,
          endTime: edt,
          isAllDay: result['isAllDay'],
          color: result['color'],
        );
      } else {
        await plannerDatabase.addEvent(
          title: result['title'],
          location: result['location'],
          startTime: sdt,
          endTime: edt,
          isAllDay: result['isAllDay'],
          color: result['color'],
        );
      }
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
    final comp = _tasks.where((t) => t.isCompleted).length,
        total = _tasks.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(isToday ? 'Сегодня' : dateStr),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final p = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (p != null) {
                setState(() => _selectedDate = p);
                _loadData();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (total > 0) ...[
            _DayProgress(completed: comp, total: total),
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
                tooltip: 'Добавить задачу',
                onPressed: _addTask,
              ),
            ],
          ),
          if (_tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Нет задач', style: TextStyle(color: Colors.grey)),
            )
          else
            ..._tasks.map(
              (task) => Dismissible(
                key: Key('task_${task.id}'),
                direction: DismissDirection.horizontal,
                confirmDismiss: (d) async {
                  if (d == DismissDirection.startToEnd) {
                    await plannerDatabase.completeRecurringTask(task);
                    if (!task.isCompleted)
                      await rpgDatabase.addXpWithAttribute(10, 'strength');
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
                    if (!task.isCompleted)
                      await rpgDatabase.addXpWithAttribute(10, 'strength');
                    _loadData();
                  },
                  onOpenSubtasks: () => _openSubtasks(task),
                  onRescheduleToDate: (DateTime d) async {
                    await plannerDatabase.rescheduleTask(task, d);
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
                    (h) => _HabitCard(
                      habit: h,
                      selectedDate: _selectedDate,
                      onTap: () async {
                        await plannerDatabase.toggleHabitForDate(
                          h.id,
                          _selectedDate,
                        );
                        final wasDone = await plannerDatabase
                            .isHabitDoneForDate(h.id, _selectedDate);
                        if (wasDone)
                          await rpgDatabase.addXpWithAttribute(5, 'balance');
                        _loadData();
                      },
                      onDelete: () async {
                        await plannerDatabase.deleteHabit(h.id);
                        await HabitDaysService.delete(h.id);
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
                onPressed: () => _addOrEditEvent(),
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
              (e) => _EventCard(
                event: e,
                onTap: () => _addOrEditEvent(existing: e),
                onDelete: () async {
                  await plannerDatabase.deleteEvent(e.id);
                  _loadData();
                },
                colors: _eventColors,
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

// ======== ЭКРАН ПОДЗАДАЧ ========

class SubtasksScreen extends StatefulWidget {
  final Task task;
  const SubtasksScreen({super.key, required this.task});
  @override
  State<SubtasksScreen> createState() => _SubtasksScreenState();
}

class _SubtasksScreenState extends State<SubtasksScreen> {
  List<Subtask> _s = [];
  final _c = TextEditingController();
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _s = await plannerDatabase.getSubtasks(widget.task.id);
    setState(() {});
  }

  Future<void> _add() async {
    final t = _c.text.trim();
    if (t.isEmpty) return;
    await plannerDatabase.addSubtask(taskId: widget.task.id, title: t);
    _c.clear();
    _load();
  }

  @override
  Widget build(BuildContext c) {
    final d = _s.where((s) => s.isCompleted).length;
    return Scaffold(
      appBar: AppBar(title: Text(widget.task.title)),
      body: Column(
        children: [
          if (_s.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _DayProgress(completed: d, total: _s.length),
            ),
          Expanded(
            child: _s.isEmpty
                ? const Center(
                    child: Text(
                      'Нет подзадач',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _s.length,
                    itemBuilder: (_, i) {
                      final s = _s[i];
                      return ListTile(
                        leading: GestureDetector(
                          onTap: () async {
                            await plannerDatabase.toggleSubtask(
                              s.id,
                              !s.isCompleted,
                            );
                            _load();
                          },
                          child: Icon(
                            s.isCompleted
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            color: s.isCompleted
                                ? Colors.greenAccent
                                : Colors.grey,
                          ),
                        ),
                        title: Text(
                          s.title,
                          style: TextStyle(
                            decoration: s.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: s.isCompleted ? Colors.grey : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: Colors.grey,
                          onPressed: () async {
                            await plannerDatabase.deleteSubtask(s.id);
                            _load();
                          },
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _c,
                      decoration: InputDecoration(
                        hintText: 'Новая подзадача...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                      ),
                      onSubmitted: (_) => _add(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _add,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
}

class _DayProgress extends StatelessWidget {
  final int completed, total;
  const _DayProgress({required this.completed, required this.total});
  @override
  Widget build(BuildContext c) {
    final p = total > 0 ? completed / total : 0.0;
    final cl = p == 1.0
        ? Colors.greenAccent
        : p > 0.5
        ? Colors.orangeAccent
        : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cl.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cl.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ПРОГРЕСС',
                style: TextStyle(fontSize: 12, letterSpacing: 2),
              ),
              Text(
                '$completed из $total',
                style: TextStyle(fontWeight: FontWeight.bold, color: cl),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: p,
              minHeight: 10,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation(cl),
            ),
          ),
          if (p == 1.0)
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
  final VoidCallback onToggle, onOpenSubtasks;
  final Function(DateTime) onRescheduleToDate;
  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onOpenSubtasks,
    required this.onRescheduleToDate,
  });
  @override
  Widget build(BuildContext c) {
    final pc = switch (task.priority) {
      'high' => Colors.redAccent,
      'medium' => Colors.orangeAccent,
      _ => Colors.greenAccent,
    };
    return Card(
      child: InkWell(
        onTap: onOpenSubtasks,
        onLongPress: () => showModalBottomSheet(
          context: c,
          builder: (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.checklist),
                  title: const Text('Подзадачи'),
                  onTap: () {
                    Navigator.pop(c);
                    onOpenSubtasks();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_calendar),
                  title: const Text('Перенести'),
                  onTap: () async {
                    Navigator.pop(c);
                    final p = await showDatePicker(
                      context: c,
                      initialDate: task.dueDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (p != null) onRescheduleToDate(p);
                  },
                ),
              ],
            ),
          ),
        ),
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
              Icon(Icons.list, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              if (task.recurrence != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.repeat, size: 16, color: Colors.grey[600]),
                ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: pc, shape: BoxShape.circle),
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
  final VoidCallback onTap, onDelete;
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
  bool _d = false;
  int _s = 0;
  final _wpk = GlobalKey<_WeekProgressState>();
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await plannerDatabase.isHabitDoneForDate(
      widget.habit.id,
      widget.selectedDate,
    );
    final s = await plannerDatabase.getHabitStreakForDate(
      widget.habit.id,
      widget.selectedDate,
    );
    if (mounted)
      setState(() {
        _d = d;
        _s = s;
      });
    _wpk.currentState?.reload();
  }

  @override
  Widget build(BuildContext c) {
    String sub;
    if (widget.habit.frequency == 'custom') {
      sub = _s >= widget.habit.targetCount
          ? '✅ ${widget.habit.targetCount}/${widget.habit.targetCount} на этой неделе'
          : '$_s/${widget.habit.targetCount} на этой неделе';
    } else {
      sub = _s > 0 ? '🔥 $_s ${_dw(_s)} подряд' : 'Начните сегодня';
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    widget.onTap();
                    _load();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _d
                          ? Colors.greenAccent.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        widget.habit.icon,
                        style: TextStyle(
                          fontSize: 20,
                          color: _d ? Colors.greenAccent : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.habit.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _d ? Colors.greenAccent : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        style: TextStyle(
                          fontSize: 12,
                          color: _s > 0 ? Colors.orangeAccent : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.grey,
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _WeekProgress(
              key: _wpk,
              habitId: widget.habit.id,
              selectedDate: widget.selectedDate,
            ),
          ],
        ),
      ),
    );
  }

  String _dw(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'день';
    if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100))
      return 'дня';
    return 'дней';
  }
}

class _WeekProgress extends StatefulWidget {
  final int habitId;
  final DateTime selectedDate;
  const _WeekProgress({
    super.key,
    required this.habitId,
    required this.selectedDate,
  });
  @override
  State<_WeekProgress> createState() => _WeekProgressState();
}

class _WeekProgressState extends State<_WeekProgress> {
  Set<DateTime> _c = {};
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await plannerDatabase.getHabitCompletionsForWeek(
      widget.habitId,
      widget.selectedDate,
    );
    if (mounted) setState(() => _c = c);
  }

  void reload() {
    _load();
  }

  @override
  Widget build(BuildContext c) {
    final ws = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
    ).subtract(Duration(days: widget.selectedDate.weekday - 1));
    final days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        final day = ws.add(Duration(days: i));
        final done = _c.any(
          (x) => x.year == day.year && x.month == day.month && x.day == day.day,
        );
        final today =
            day.year == widget.selectedDate.year &&
            day.month == widget.selectedDate.month &&
            day.day == widget.selectedDate.day;
        return Column(
          children: [
            Text(
              days[i],
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? Colors.greenAccent.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.1),
                border: Border.all(
                  color: done
                      ? Colors.greenAccent
                      : today
                      ? Colors.orangeAccent
                      : Colors.grey[700]!,
                  width: today ? 2 : 1,
                ),
              ),
              child: done
                  ? const Icon(Icons.check, size: 14, color: Colors.greenAccent)
                  : null,
            ),
          ],
        );
      }),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Map<String, Color> colors;
  const _EventCard({
    required this.event,
    required this.onTap,
    required this.onDelete,
    required this.colors,
  });
  @override
  Widget build(BuildContext context) {
    final color = colors[event.color] ?? Colors.blueAccent;
    final timeStr = event.isAllDay
        ? 'Весь день'
        : '${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')}${event.endTime != null ? ' - ${event.endTime!.hour}:${event.endTime!.minute.toString().padLeft(2, '0')}' : ''}';
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Icon(Icons.event, color: color)),
                ),
                title: Text(event.title),
                subtitle: Row(
                  children: [
                    Text(timeStr),
                    if (event.location != null) ...[
                      const Text(' · '),
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[500],
                      ),
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
            ),
          ],
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
  Widget build(BuildContext c) => Padding(
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
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.only(right: 4),
    child: FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      selectedColor: Theme.of(c).colorScheme.primary.withValues(alpha: 0.3),
      checkmarkColor: Theme.of(c).colorScheme.primary,
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
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.only(right: 4, bottom: 4),
    child: FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      selectedColor: Theme.of(c).colorScheme.primary.withValues(alpha: 0.3),
      checkmarkColor: Theme.of(c).colorScheme.primary,
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
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.only(right: 4, bottom: 4),
    child: FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      selectedColor: Theme.of(c).colorScheme.primary.withValues(alpha: 0.3),
      checkmarkColor: Theme.of(c).colorScheme.primary,
      onSelected: (_) => onTap(),
    ),
  );
}

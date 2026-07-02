import 'package:flutter/material.dart';
import '../../../main.dart';
import '../models/transaction_model.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  List<SavingsGoal> _goals = [];

  final List<Map<String, String>> _availableIcons = [
    {'icon': '✈️', 'label': 'Отпуск'},
    {'icon': '🚗', 'label': 'Машина'},
    {'icon': '🏠', 'label': 'Жильё'},
    {'icon': '💻', 'label': 'Техника'},
    {'icon': '📚', 'label': 'Обучение'},
    {'icon': '💍', 'label': 'Свадьба'},
    {'icon': '🏥', 'label': 'Здоровье'},
    {'icon': '🎁', 'label': 'Подарок'},
    {'icon': '💼', 'label': 'Бизнес'},
    {'icon': '🎯', 'label': 'Другое'},
  ];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final goals = await database.getAllSavingsGoals();
    setState(() => _goals = goals);
  }

  Future<void> _addGoal() async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedIcon = '🎯';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Новая цель'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Название цели'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Сумма цели',
                    prefixText: '₽ ',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Иконка', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _availableIcons.map((item) {
                    final isSelected = selectedIcon == item['icon'];
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() => selectedIcon = item['icon']!);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.2)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              item['icon']!,
                              style: const TextStyle(fontSize: 24),
                            ),
                            Text(
                              item['label']!,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
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
                final title = titleController.text.trim();
                final amount = double.tryParse(amountController.text);
                if (title.isNotEmpty && amount != null && amount > 0) {
                  Navigator.pop(context, {
                    'title': title,
                    'amount': amount,
                    'icon': selectedIcon,
                  });
                }
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await database.addSavingsGoal(
        title: result['title'],
        targetAmount: result['amount'],
        icon: result['icon'],
      );
      _loadGoals();
    }
  }

  Future<void> _addAmount(SavingsGoal goal) async {
    final controller = TextEditingController();
    final remaining = goal.targetAmount - goal.currentAmount;

    final amount = await showDialog<double>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final monthly = double.tryParse(controller.text);
          String hint = '';
          if (monthly != null && monthly > 0 && remaining > 0) {
            final months = (remaining / monthly).ceil();
            hint =
                '💡 Откладывая по ${monthly.toStringAsFixed(0)} ₽ в месяц, '
                'вы достигнете цели через $months ${_monthsWord(months)}';
          }

          return AlertDialog(
            title: Text(goal.title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Накоплено: ${goal.currentAmount.toStringAsFixed(0)} из ${goal.targetAmount.toStringAsFixed(0)} ₽',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  'Осталось: ${remaining.toStringAsFixed(0)} ₽',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Добавить сумму',
                    prefixText: '+ ₽ ',
                  ),
                  autofocus: true,
                  onChanged: (_) => setDialogState(() {}),
                ),
                if (hint.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    hint,
                    style: TextStyle(
                      color: Colors.tealAccent.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () {
                  final value = double.tryParse(controller.text);
                  Navigator.pop(context, value);
                },
                child: const Text('Добавить'),
              ),
            ],
          );
        },
      ),
    );

    if (amount != null && amount > 0) {
      final newTotal = goal.currentAmount + amount;
      await database.updateSavingsGoalAmount(goal.id, newTotal);
      _loadGoals();
    }
  }

  String _monthsWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'месяц';
    if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100))
      return 'месяца';
    return 'месяцев';
  }

  Future<void> _deleteGoal(SavingsGoal goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить цель?'),
        content: Text('Вы уверены, что хотите удалить "${goal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await database.deleteSavingsGoal(goal.id);
      _loadGoals();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Цели накопления')),
      body: _goals.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🎯', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  Text(
                    'Нет целей накопления',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Создайте цель, чтобы отслеживать прогресс',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Пояснение
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Откладывайте на мечту и следите за прогрессом. '
                    'Нажмите на цель, чтобы добавить сумму.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                // Список целей
                ..._goals.map(
                  (goal) => _GoalCard(
                    goal: goal,
                    onTap: () => _addAmount(goal),
                    onDelete: () => _deleteGoal(goal),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addGoal,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
    final remaining = goal.targetAmount - goal.currentAmount;
    final isCompleted = goal.isCompleted;

    final color = isCompleted
        ? Colors.greenAccent
        : percent > 0.6
        ? Colors.greenAccent
        : percent > 0.3
        ? Colors.orangeAccent
        : Colors.redAccent;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        goal.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isCompleted)
                          const Text(
                            '✅ Выполнено!',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.grey,
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${goal.currentAmount.toStringAsFixed(0)} / ${goal.targetAmount.toStringAsFixed(0)} ₽',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${(percent * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 12,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percent,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orangeAccent,
                                Colors.yellowAccent,
                                Colors.greenAccent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isCompleted && remaining > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Осталось ${remaining.toStringAsFixed(0)} ₽',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

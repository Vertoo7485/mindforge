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
                    labelText: 'Сумма',
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

    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(goal.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Накоплено: ${goal.currentAmount.toStringAsFixed(0)} из ${goal.targetAmount.toStringAsFixed(0)} ₽',
              style: const TextStyle(color: Colors.grey),
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
            ),
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
      ),
    );

    if (amount != null && amount > 0) {
      final newTotal = goal.currentAmount + amount;
      await database.updateSavingsGoalAmount(goal.id, newTotal);
      _loadGoals();
    }
  }

  Future<void> _deleteGoal(SavingsGoal goal) async {
    await database.deleteSavingsGoal(goal.id);
    _loadGoals();
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
              children: _goals
                  .map(
                    (goal) => _GoalCard(
                      goal: goal,
                      onTap: () => _addAmount(goal),
                      onDelete: () => _deleteGoal(goal),
                    ),
                  )
                  .toList(),
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
    final color = goal.isCompleted
        ? Colors.greenAccent
        : percent > 0.5
        ? Theme.of(context).colorScheme.primary
        : Colors.orangeAccent;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(goal.icon, style: const TextStyle(fontSize: 28)),
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
                        if (goal.isCompleted)
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
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${goal.currentAmount.toStringAsFixed(0)} / ${goal.targetAmount.toStringAsFixed(0)} ₽',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(
                    '${(percent * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 10,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

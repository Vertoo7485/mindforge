import 'package:flutter/material.dart';
import '../../../main.dart';
import '../models/transaction_model.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List<Budget> _budgets = [];
  Map<String?, double> _spentByCategory = {};

  // Категории расходов
  final List<String> _categories = [
    'Продукты',
    'Транспорт',
    'Развлечения',
    'Здоровье',
    'Одежда',
    'Жильё',
    'Связь',
    'Кафе и рестораны',
    'Красота и уход',
    'Подписки',
    'Другое',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final budgets = await database.getAllBudgets();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);

    // Считаем расходы по каждой категории за месяц
    final allExpenses = await database.getTransactionsByPeriod(start, now);
    final spent = <String?, double>{};
    spent[null] = 0; // Общий

    for (final t in allExpenses) {
      if (t.type == 'expense') {
        spent[null] = (spent[null] ?? 0) + t.amount;
        spent[t.category] = (spent[t.category] ?? 0) + t.amount;
      }
    }

    setState(() {
      _budgets = budgets;
      _spentByCategory = spent;
    });
  }

  Future<void> _addBudget({String? category}) async {
    final controller = TextEditingController();
    final existing = _budgets.where((b) => b.category == category);
    if (existing.isNotEmpty) {
      controller.text = existing.first.amount.toStringAsFixed(0);
    }

    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category ?? 'Общий бюджет'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Сумма на месяц',
            prefixText: '₽ ',
          ),
          autofocus: true,
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
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (amount != null && amount > 0) {
      await database.setBudget(
        category: category,
        amount: amount,
        period: 'monthly',
        startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
      );
      _loadData();
    }
  }

  Future<void> _deleteBudget(Budget budget) async {
    await database.deleteBudget(budget.id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final generalBudget = _budgets.where((b) => b.category == null);
    final categoryBudgets = _budgets.where((b) => b.category != null).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Бюджеты')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Общий бюджет
          const Text(
            'ОБЩИЙ БЮДЖЕТ',
            style: TextStyle(fontSize: 12, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          if (generalBudget.isEmpty)
            _EmptyBudgetCard(
              label: 'Общий месячный бюджет',
              onTap: () => _addBudget(),
            )
          else
            _BudgetCard(
              label: 'Общий',
              amount: generalBudget.first.amount,
              spent: _spentByCategory[null] ?? 0,
              onTap: () => _addBudget(),
              onDelete: () => _deleteBudget(generalBudget.first),
            ),
          const SizedBox(height: 24),

          // Бюджеты по категориям
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ПО КАТЕГОРИЯМ',
                style: TextStyle(fontSize: 12, letterSpacing: 2),
              ),
              TextButton.icon(
                onPressed: () => _showAddCategoryDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Добавить'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (categoryBudgets.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Нет бюджетов по категориям',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...categoryBudgets.map(
              (b) => _BudgetCard(
                label: b.category ?? 'Другое',
                amount: b.amount,
                spent: _spentByCategory[b.category] ?? 0,
                onTap: () => _addBudget(category: b.category),
                onDelete: () => _deleteBudget(b),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Выберите категорию'),
        children: _categories
            .map(
              (c) => SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  _addBudget(category: c);
                },
                child: Text(c),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final String label;
  final double amount;
  final double spent;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BudgetCard({
    required this.label,
    required this.amount,
    required this.spent,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (spent / amount).clamp(0.0, 1.0);
    final color = percent > 0.9
        ? Colors.redAccent
        : percent > 0.7
        ? Colors.orangeAccent
        : Colors.greenAccent;

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Text(
                        '${spent.toStringAsFixed(0)} / ${amount.toStringAsFixed(0)} ₽',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: Colors.grey,
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 8,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              if (percent > 0.9)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '⚠️ Почти исчерпан!',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBudgetCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _EmptyBudgetCard({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text('+ $label', style: TextStyle(color: Colors.grey[500])),
          ),
        ),
      ),
    );
  }
}

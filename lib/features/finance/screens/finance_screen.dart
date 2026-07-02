import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../main.dart';
import '../models/transaction_model.dart';
import 'budget_screen.dart';
import 'savings_screen.dart';
import 'history_screen.dart';
import 'finance_onboarding.dart';

// Советы по финансовой грамотности
final List<Map<String, String>> _financialTips = [
  {
    'title': 'Правило 50/30/20',
    'body':
        '50% дохода — на необходимое (жильё, еда, транспорт). '
        '30% — на желания (развлечения, хобби). '
        '20% — на сбережения и инвестиции. '
        'Это базовая формула финансового здоровья.',
    'icon': '📊',
  },
  {
    'title': 'Подушка безопасности',
    'body':
        'Финансовая подушка — это 3-6 месячных расходов, '
        'которые лежат на отдельном счёте. '
        'Она защищает от неожиданных ситуаций: потеря работы, '
        'болезнь, срочный ремонт. Начните откладывать 5-10% дохода.',
    'icon': '🛡️',
  },
  {
    'title': 'Метод конвертов',
    'body':
        'Разложите деньги по категориям в начале месяца. '
        'Когда конверт пуст — траты в этой категории прекращаются. '
        'Это помогает контролировать импульсивные покупки '
        'и видеть реальную картину расходов.',
    'icon': '✉️',
  },
  {
    'title': 'Осознанные траты',
    'body':
        'Перед покупкой задайте себе три вопроса: '
        '1) Это действительно нужно? '
        '2) Это принесёт пользу через месяц? '
        '3) Я могу позволить себе это без ущерба для целей? '
        'Пауза в 24 часа спасает от импульсивных решений.',
    'icon': '🧠',
  },
  {
    'title': 'Цена импульса',
    'body':
        'Импульсивные покупки — это способ справиться с эмоциями. '
        'Вместо покупки попробуйте: прогулку, дыхательное упражнение, '
        'звонок другу. Запишите, что вы хотели купить — '
        'через неделю 80% желаний исчезают.',
    'icon': '💡',
  },
  {
    'title': 'Сначала заплати себе',
    'body':
        'Откладывайте 10-20% дохода СРАЗУ после получения, '
        'до любых трат. Автоматический перевод на накопительный счёт '
        'убирает соблазн потратить. Это главный принцип '
        'построения капитала.',
    'icon': '🏦',
  },
  {
    'title': 'Финансовый дневник',
    'body':
        'Записывайте не только суммы, но и эмоции при тратах. '
        'Это поможет заметить триггеры: стресс, скука, социальное давление. '
        'Осознанность в финансах начинается с понимания своих паттернов.',
    'icon': '📝',
  },
];

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  List<Transaction> _transactions = [];
  double _balance = 0;
  List<Map<String, dynamic>> _expensesByCategory = [];
  Budget? _generalBudget;
  Map<String, String> _dailyTip = {};
  bool _showOnboarding = false;

  String _periodFilter = 'all';

  @override
  void initState() {
    super.initState();
    _dailyTip = _getDailyTip();
    _loadData();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final shouldShow = await FinanceOnboarding.shouldShow();
    if (mounted) {
      setState(() => _showOnboarding = shouldShow);
    }
  }

  Map<String, String> _getDailyTip() {
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    return _financialTips[dayOfYear % _financialTips.length];
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (_periodFilter) {
      case 'week':
        start = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'month':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        start = DateTime(now.year, 1, 1);
        break;
      default:
        start = DateTime(2000);
    }

    final transactions = _periodFilter == 'all'
        ? await database.getAllTransactions()
        : await database.getTransactionsByPeriod(start, end);

    final balance = await database.getBalance();
    final expenses = _periodFilter == 'all'
        ? await database.expensesByCategory()
        : await database.expensesByCategoryForPeriod(start, end);
    final budget = await database.getBudgetByCategory(null);

    setState(() {
      _transactions = transactions;
      _balance = balance;
      _expensesByCategory = expenses;
      _generalBudget = budget;
    });
  }

  Future<void> _addTransaction() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddTransactionDialog(),
    );

    if (result != null) {
      await database.addTransaction(
        type: result['type'],
        amount: result['amount'],
        category: result['category'],
        date: result['date'],
        note: result['note'],
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return FinanceOnboarding(
        onComplete: () {
          setState(() => _showOnboarding = false);
        },
      );
    }

    final periodExpense = _transactions
        .where((t) => t.type == 'expense')
        .fold<double>(0, (sum, t) => sum + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Финансы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Обучение',
            onPressed: () async {
              await FinanceOnboarding.reset();
              setState(() => _showOnboarding = true);
            },
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Цели накопления — копите на мечту',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SavingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Бюджеты — установите лимиты на категории',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BudgetScreen()),
              ).then((_) => _loadData());
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Баланс
          _BalanceCard(balance: _balance),
          const SizedBox(height: 16),

          // Совет дня
          if (_dailyTip.isNotEmpty) ...[
            _TipCard(tip: _dailyTip),
            const SizedBox(height: 16),
          ],

          // Бюджет
          if (_generalBudget != null) ...[
            _BudgetCard(budget: _generalBudget!, spent: periodExpense),
            const SizedBox(height: 16),
          ],

          // Фильтр периода
          Row(
            children: [
              _PeriodButton(
                label: 'Неделя',
                value: 'week',
                current: _periodFilter,
                onTap: (v) {
                  setState(() => _periodFilter = v);
                  _loadData();
                },
              ),
              const SizedBox(width: 8),
              _PeriodButton(
                label: 'Месяц',
                value: 'month',
                current: _periodFilter,
                onTap: (v) {
                  setState(() => _periodFilter = v);
                  _loadData();
                },
              ),
              const SizedBox(width: 8),
              _PeriodButton(
                label: 'Год',
                value: 'year',
                current: _periodFilter,
                onTap: (v) {
                  setState(() => _periodFilter = v);
                  _loadData();
                },
              ),
              const SizedBox(width: 8),
              _PeriodButton(
                label: 'Всё',
                value: 'all',
                current: _periodFilter,
                onTap: (v) {
                  setState(() => _periodFilter = v);
                  _loadData();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите период для аналитики',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Круговая диаграмма расходов
          if (_expensesByCategory.isNotEmpty) ...[
            const Text(
              'РАСХОДЫ ПО КАТЕГОРИЯМ',
              style: TextStyle(fontSize: 12, letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ..._buildLegend(),
            const SizedBox(height: 24),
          ],

          // Кнопка истории
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('История транзакций'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  side: BorderSide(color: Colors.grey[700]!),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Здесь все ваши доходы и расходы',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        child: const Icon(Icons.add),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.greenAccent,
      Colors.purpleAccent,
      Colors.yellowAccent,
      Colors.tealAccent,
      Colors.pinkAccent,
    ];

    final total = _expensesByCategory.fold<double>(
      0,
      (sum, item) => sum + (item['total'] as double),
    );

    return _expensesByCategory.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final percentage = ((item['total'] as double) / total * 100);
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: (item['total'] as double),
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _buildLegend() {
    final colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.greenAccent,
      Colors.purpleAccent,
      Colors.yellowAccent,
      Colors.tealAccent,
      Colors.pinkAccent,
    ];

    final total = _expensesByCategory.fold<double>(
      0,
      (sum, item) => sum + (item['total'] as double),
    );

    return _expensesByCategory.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final percentage = ((item['total'] as double) / total * 100)
          .toStringAsFixed(0);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(item['category'] as String),
            const Spacer(),
            Text('${item['total']} ₽ ($percentage%)'),
          ],
        ),
      );
    }).toList();
  }
}

// ======== ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ ========

class _TipCard extends StatefulWidget {
  final Map<String, String> tip;
  const _TipCard({required this.tip});

  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.tealAccent.withValues(alpha: 0.1),
            Colors.blueAccent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.tip['icon']!, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.tip['title']!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.tealAccent,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.tealAccent,
                ),
                onPressed: () {
                  setState(() => _isExpanded = !_isExpanded);
                },
              ),
            ],
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            Text(
              widget.tip['body']!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[300],
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'БАЛАНС',
            style: TextStyle(fontSize: 12, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(
            '${balance >= 0 ? "+" : ""}${balance.toStringAsFixed(0)} ₽',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: balance >= 0
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final double spent;
  const _BudgetCard({required this.budget, required this.spent});

  @override
  Widget build(BuildContext context) {
    final percent = (spent / budget.amount).clamp(0.0, 1.0);
    final color = percent > 0.9
        ? Colors.redAccent
        : percent > 0.7
        ? Colors.orangeAccent
        : Colors.greenAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'МЕСЯЧНЫЙ БЮДЖЕТ',
                style: TextStyle(fontSize: 12, letterSpacing: 2),
              ),
              Text(
                '${spent.toStringAsFixed(0)} / ${budget.amount.toStringAsFixed(0)} ₽',
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
          if (percent > 0.9)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '⚠️ Почти исчерпан!',
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final Function(String) onTap;

  const _PeriodButton({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[700]!,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[400],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// ======== ДИАЛОГ ДОБАВЛЕНИЯ ========

class AddTransactionDialog extends StatefulWidget {
  const AddTransactionDialog({super.key});

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  String _type = 'expense';
  final _amountController = TextEditingController();
  String _category = 'Продукты';

  final List<String> _expenseCategories = [
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

  final List<String> _incomeCategories = [
    'Зарплата',
    'Фриланс',
    'Подарок',
    'Кэшбэк',
    'Инвестиции',
    'Другое',
  ];

  List<String> get _currentCategories =>
      _type == 'expense' ? _expenseCategories : _incomeCategories;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить транзакцию'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Расход')),
                ButtonSegment(value: 'income', label: Text('Доход')),
              ],
              selected: {_type},
              onSelectionChanged: (selection) {
                setState(() {
                  _type = selection.first;
                  _category = _currentCategories.first;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Сумма',
                prefixText: '₽ ',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              items: _currentCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) => setState(() => _category = value!),
              decoration: const InputDecoration(labelText: 'Категория'),
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
            final amount = double.tryParse(_amountController.text);
            if (amount != null && amount > 0) {
              Navigator.pop(context, {
                'type': _type,
                'amount': amount,
                'category': _category,
                'date': DateTime.now(),
                'note': null,
              });
            }
          },
          child: const Text('Добавить'),
        ),
      ],
    );
  }
}

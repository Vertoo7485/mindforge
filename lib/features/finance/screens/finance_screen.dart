import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../main.dart';
import '../models/transaction_model.dart';
import 'budget_screen.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  List<Transaction> _transactions = [];
  double _balance = 0;
  List<Map<String, dynamic>> _expensesByCategory = [];
  List<Map<String, dynamic>> _monthlySummary = [];
  Budget? _generalBudget;

  String _periodFilter = 'all'; // 'week', 'month', 'year', 'all'

  @override
  void initState() {
    super.initState();
    _loadData();
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
    final monthly = await database.monthlySummary();
    final budget = await database.getBudgetByCategory(null);

    setState(() {
      _transactions = transactions;
      _balance = balance;
      _expensesByCategory = expenses;
      _monthlySummary = monthly;
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
    // Расходы за период для сравнения с бюджетом
    final periodExpense = _transactions
        .where((t) => t.type == 'expense')
        .fold<double>(0, (sum, t) => sum + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Финансы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Бюджеты',
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
          const SizedBox(height: 24),

          // Доходы vs Расходы по месяцам
          if (_monthlySummary.isNotEmpty) ...[
            const Text(
              'ДОХОДЫ И РАСХОДЫ',
              style: TextStyle(fontSize: 12, letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      _monthlySummary
                          .map(
                            (m) =>
                                (m['income'] as double) >
                                    (m['expense'] as double)
                                ? (m['income'] as double)
                                : (m['expense'] as double),
                          )
                          .reduce((a, b) => a > b ? a : b) *
                      1.2,
                  barGroups: _monthlySummary.reversed.map((m) {
                    final month = (m['month'] as String).substring(5);
                    return BarChartGroupData(
                      x: _monthlySummary.indexOf(m),
                      barRods: [
                        BarChartRodData(
                          toY: (m['income'] as double),
                          color: Colors.greenAccent,
                          width: 12,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: (m['expense'] as double),
                          color: Colors.redAccent,
                          width: 12,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _monthlySummary.length) {
                            final month =
                                (_monthlySummary.reversed
                                            .toList()[index]['month']
                                        as String)
                                    .substring(5);
                            return Text(
                              month,
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            // Легенда
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendDot(color: Colors.greenAccent, label: 'Доходы'),
                  const SizedBox(width: 24),
                  _LegendDot(color: Colors.redAccent, label: 'Расходы'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

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

          // История транзакций
          const Text(
            'ИСТОРИЯ',
            style: TextStyle(fontSize: 12, letterSpacing: 2),
          ),
          const SizedBox(height: 12),
          if (_transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Нет транзакций')),
            )
          else
            ..._transactions.map(
              (t) => _TransactionTile(
                transaction: t,
                onDelete: () async {
                  await database.deleteTransaction(t.id);
                  _loadData();
                },
              ),
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

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onDelete;
  const _TransactionTile({required this.transaction, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    return Card(
      child: ListTile(
        leading: Icon(
          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          color: isIncome ? Colors.green : Colors.red,
        ),
        title: Text(transaction.category),
        subtitle: transaction.note != null ? Text(transaction.note!) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isIncome ? "+" : "-"}${transaction.amount.toStringAsFixed(0)} ₽',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.grey,
              onPressed: onDelete,
            ),
          ],
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

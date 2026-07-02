import 'package:flutter/material.dart';
import '../../../main.dart';
import '../models/transaction_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Transaction> _transactions = [];
  String _periodFilter = 'all';

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

    setState(() => _transactions = transactions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Фильтр',
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _transactions.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📭', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  Text(
                    'Нет транзакций',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final t = _transactions[index];
                final isIncome = t.type == 'income';
                return Card(
                  child: ListTile(
                    leading: Icon(
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                    title: Text(t.category),
                    subtitle: Text(
                      '${t.date.day}.${t.date.month}.${t.date.year}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${isIncome ? "+" : "-"}${t.amount.toStringAsFixed(0)} ₽',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: Colors.grey,
                          onPressed: () async {
                            await database.deleteTransaction(t.id);
                            _loadData();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Период'),
        children: [
          _FilterOption(
            label: 'Неделя',
            selected: _periodFilter == 'week',
            onTap: () {
              setState(() => _periodFilter = 'week');
              Navigator.pop(context);
              _loadData();
            },
          ),
          _FilterOption(
            label: 'Месяц',
            selected: _periodFilter == 'month',
            onTap: () {
              setState(() => _periodFilter = 'month');
              Navigator.pop(context);
              _loadData();
            },
          ),
          _FilterOption(
            label: 'Год',
            selected: _periodFilter == 'year',
            onTap: () {
              setState(() => _periodFilter = 'year');
              Navigator.pop(context);
              _loadData();
            },
          ),
          _FilterOption(
            label: 'Всё время',
            selected: _periodFilter == 'all',
            onTap: () {
              setState(() => _periodFilter = 'all');
              Navigator.pop(context);
              _loadData();
            },
          ),
        ],
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: onTap,
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            size: 20,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}

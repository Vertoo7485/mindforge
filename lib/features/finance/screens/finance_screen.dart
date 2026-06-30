import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../../main.dart';
import '../models/transaction_model.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  List<Transaction> _transactions = [];
  double _balance = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final transactions = await database.getAllTransactions();
    final balance = await database.getBalance();
    setState(() {
      _transactions = transactions;
      _balance = balance;
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
    return Scaffold(
      appBar: AppBar(title: const Text('Финансы')),
      body: Column(
        children: [
          // Карточка баланса
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.3),
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
                  '${_balance >= 0 ? "+" : ""}${_balance.toStringAsFixed(0)} ₽',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: _balance >= 0
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ИСТОРИЯ',
                  style: TextStyle(fontSize: 12, letterSpacing: 2),
                ),
              ],
            ),
          ),
          Expanded(
            child: _transactions.isEmpty
                ? const Center(child: Text('Нет транзакций'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final t = _transactions[index];
                      final isIncome = t.type == 'income';
                      return ListTile(
                        leading: Icon(
                          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                        title: Text(t.category),
                        subtitle: t.note != null ? Text(t.note!) : null,
                        trailing: Text(
                          '${isIncome ? "+" : "-"}${t.amount.toStringAsFixed(0)} ₽',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                      );
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
}

// Диалог добавления транзакции
class AddTransactionDialog extends StatefulWidget {
  const AddTransactionDialog({super.key});

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  String _type = 'expense';
  final _amountController = TextEditingController();
  String _category = 'Продукты';

  final List<String> _categories = [
    'Продукты',
    'Транспорт',
    'Развлечения',
    'Здоровье',
    'Одежда',
    'Жильё',
    'Связь',
    'Другое',
    'Зарплата',
    'Подарок',
  ];

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
                setState(() => _type = selection.first);
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
              items: _categories
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

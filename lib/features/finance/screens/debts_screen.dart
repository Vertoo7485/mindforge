import 'package:flutter/material.dart';
import '../../../main.dart';
import '../models/transaction_model.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  List<Debt> _debts = [];

  final List<String> _icons = ['💳', '🏠', '🚗', '🎓', '💊', '💼', '👤', '🏦'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _debts = await database.getAllDebts();
    setState(() {});
  }

  Future<void> _addDebt() async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final paymentController = TextEditingController();
    String icon = '💳';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Новый долг'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название долга',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Сумма долга',
                    prefixText: '₽ ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: paymentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Ежемесячный платёж',
                    prefixText: '₽ ',
                    hintText: 'Необязательно',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Иконка', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _icons.map((e) {
                    final selected = icon == e;
                    return GestureDetector(
                      onTap: () => setDialogState(() => icon = e),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.2)
                              : Colors.grey[800],
                          borderRadius: BorderRadius.circular(10),
                          border: selected
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
                final amount = double.tryParse(amountController.text);
                final payment = double.tryParse(paymentController.text);
                if (nameController.text.trim().isNotEmpty &&
                    amount != null &&
                    amount > 0) {
                  Navigator.pop(context, {
                    'title': nameController.text.trim(),
                    'amount': amount,
                    'payment': payment ?? 0,
                    'icon': icon,
                  });
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await database.addDebt(
        title: result['title'],
        totalAmount: result['amount'],
        monthlyPayment: result['payment'],
        icon: result['icon'],
      );
      _load();
    }
  }

  Future<void> _addPayment(Debt debt) async {
    final controller = TextEditingController();
    final remaining = debt.totalAmount - debt.paidAmount;

    final amount = await showDialog<double>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final inputAmount = double.tryParse(controller.text) ?? 0;
          final monthsBefore = debt.monthlyPayment > 0
              ? (remaining / debt.monthlyPayment).ceil()
              : 0;
          final monthsAfter = debt.monthlyPayment > 0 && inputAmount > 0
              ? ((remaining - inputAmount) / debt.monthlyPayment).ceil().clamp(
                  0,
                  999999,
                )
              : 0;
          final savedMonths = monthsBefore - monthsAfter;

          return AlertDialog(
            title: Text(debt.title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Погашено: ${debt.paidAmount.toStringAsFixed(0)} из ${debt.totalAmount.toStringAsFixed(0)} ₽',
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
                if (debt.monthlyPayment > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Плановый платёж: ${debt.monthlyPayment.toStringAsFixed(0)} ₽ в месяц',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    'Осталось месяцев: $monthsBefore',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Сумма погашения',
                    prefixText: '+ ₽ ',
                  ),
                  autofocus: true,
                  onChanged: (_) => setDialogState(() {}),
                ),
                if (savedMonths > 0 && inputAmount > debt.monthlyPayment) ...[
                  const SizedBox(height: 12),
                  Text(
                    '🎉 Срок сократится на $savedMonths ${_monthsWord(savedMonths)}!',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
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
                  final v = double.tryParse(controller.text);
                  Navigator.pop(context, v);
                },
                child: const Text('Погасить'),
              ),
            ],
          );
        },
      ),
    );

    if (amount != null && amount > 0) {
      await database.addDebtPayment(debt.id, amount);
      _load();
    }
  }

  String _monthsWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'месяц';
    if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100))
      return 'месяца';
    return 'месяцев';
  }

  Future<void> _deleteDebt(Debt debt) async {
    await database.deleteDebt(debt.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final totalDebts = _debts.fold<double>(0, (sum, d) => sum + d.totalAmount);
    final totalPaid = _debts.fold<double>(0, (sum, d) => sum + d.paidAmount);

    return Scaffold(
      appBar: AppBar(title: const Text('Долги')),
      body: _debts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('💳', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  Text(
                    'Нет долгов',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Добавьте долг, чтобы отслеживать погашение',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_debts.length > 1) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ВСЕГО ДОЛГОВ',
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 2,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${totalDebts.toStringAsFixed(0)} ₽',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Погашено: ${totalPaid.toStringAsFixed(0)} ₽',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: totalDebts > 0
                                ? (totalPaid / totalDebts).clamp(0.0, 1.0)
                                : 0,
                            minHeight: 10,
                            backgroundColor: Colors.grey[800],
                            valueColor: const AlwaysStoppedAnimation(
                              Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ..._debts.map(
                  (debt) => _DebtCard(
                    debt: debt,
                    onTap: () => _addPayment(debt),
                    onDelete: () => _deleteDebt(debt),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDebt,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DebtCard({
    required this.debt,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (debt.paidAmount / debt.totalAmount).clamp(0.0, 1.0);
    final remaining = debt.totalAmount - debt.paidAmount;
    final color = debt.isCompleted ? Colors.greenAccent : Colors.redAccent;
    final monthsLeft = debt.monthlyPayment > 0 && !debt.isCompleted
        ? (remaining / debt.monthlyPayment).ceil()
        : null;

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
                        debt.icon,
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
                          debt.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (debt.isCompleted)
                          const Text(
                            '✅ Погашено!',
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
                    '${debt.paidAmount.toStringAsFixed(0)} / ${debt.totalAmount.toStringAsFixed(0)} ₽',
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
                                Colors.redAccent,
                                debt.isCompleted
                                    ? Colors.greenAccent
                                    : Colors.orangeAccent,
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
              if (monthsLeft != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Осталось $monthsLeft ${_monthsWordStatic(monthsLeft)}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ] else if (!debt.isCompleted && remaining > 0) ...[
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

  static String _monthsWordStatic(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'месяц';
    if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100))
      return 'месяца';
    return 'месяцев';
  }
}

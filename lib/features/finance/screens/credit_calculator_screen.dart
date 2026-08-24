import 'package:flutter/material.dart';

class CreditCalculatorScreen extends StatefulWidget {
  const CreditCalculatorScreen({super.key});

  @override
  State<CreditCalculatorScreen> createState() => _CreditCalculatorScreenState();
}

class _CreditCalculatorScreenState extends State<CreditCalculatorScreen> {
  final _amountController = TextEditingController();
  final _rateController = TextEditingController();
  final _termController = TextEditingController();

  double _monthlyPayment = 0;
  double _totalPayment = 0;
  double _overpayment = 0;

  void _calculate() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    final term = int.tryParse(_termController.text) ?? 0;

    if (amount <= 0 || rate <= 0 || term <= 0) {
      setState(() {
        _monthlyPayment = 0;
        _totalPayment = 0;
        _overpayment = 0;
      });
      return;
    }

    final monthlyRate = rate / 100 / 12;
    final factor = 1 + monthlyRate;
    double factorPow = 1;
    for (var i = 0; i < term; i++) {
      factorPow *= factor;
    }
    final payment = amount * monthlyRate * factorPow / (factorPow - 1);
    final total = payment * term;

    setState(() {
      _monthlyPayment = payment;
      _totalPayment = total;
      _overpayment = total - amount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Кредитный калькулятор')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Сумма кредита',
              prefixText: '₽ ',
            ),
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _rateController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Годовая ставка',
              suffixText: '%',
            ),
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _termController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Срок',
              suffixText: 'месяцев',
            ),
            onChanged: (_) => _calculate(),
          ),
          const SizedBox(height: 24),
          if (_monthlyPayment > 0) ...[
            Container(
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
                    'ЕЖЕМЕСЯЧНЫЙ ПЛАТЁЖ',
                    style: TextStyle(fontSize: 12, letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_monthlyPayment.toStringAsFixed(0)} ₽',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Общая сумма выплат'),
                        Text(
                          '${_totalPayment.toStringAsFixed(0)} ₽',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Переплата'),
                        Text(
                          '${_overpayment.toStringAsFixed(0)} ₽',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Переплата в %'),
                        Text(
                          '${((_overpayment / (_totalPayment - _overpayment)) * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orangeAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Если платить на 10% больше ежемесячно, срок кредита сократится примерно на 15-20%, а переплата уменьшится на 20-30%.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[300]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _rateController.dispose();
    _termController.dispose();
    super.dispose();
  }
}

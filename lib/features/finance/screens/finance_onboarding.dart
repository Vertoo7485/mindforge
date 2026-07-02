import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FinanceOnboarding extends StatefulWidget {
  final VoidCallback onComplete;

  const FinanceOnboarding({super.key, required this.onComplete});

  /// Проверяет, нужно ли показывать онбординг
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('finance_onboarding_done') ?? false);
  }

  /// Отмечает онбординг как пройденный
  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('finance_onboarding_done', true);
  }

  /// Сбрасывает (для кнопки "?")
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('finance_onboarding_done', false);
  }

  @override
  State<FinanceOnboarding> createState() => _FinanceOnboardingState();
}

class _FinanceOnboardingState extends State<FinanceOnboarding> {
  int _step = 0;

  final List<Map<String, dynamic>> _steps = [
    {
      'icon': '🏦',
      'title': 'Ваш финансовый дневник',
      'body':
          'Здесь вы будете видеть полную картину своих денег. '
          'Баланс, расходы по категориям, бюджеты и цели — '
          'всё в одном месте, чтобы управлять финансами осознанно.',
    },
    {
      'icon': '📋',
      'title': 'Категории и транзакции',
      'body':
          'Добавляйте доходы и расходы по категориям. '
          'Деньги любят счёт — даже маленькие траты, '
          'записанные в приложении, помогают увидеть общую картину.',
    },
    {
      'icon': '🎯',
      'title': 'Бюджеты',
      'body':
          'Установите месячный лимит на всё или на отдельные категории. '
          'Приложение покажет, сколько уже потрачено, '
          'и предупредит, когда вы приближаетесь к границе.',
    },
    {
      'icon': '✈️',
      'title': 'Цели накопления',
      'body':
          'Копите на мечту! Создайте цель — отпуск, машина, подушка безопасности — '
          'и отмечайте прогресс. Приложение подскажет, '
          'сколько месяцев займёт путь к цели.',
    },
    {
      'icon': '⚔️',
      'title': 'Готовы?',
      'body':
          'Финансовый модуль — ваш первый шаг к осознанной жизни. '
          'Дальше вас ждут планер, психология, тренировки '
          'и RPG-система, которая превратит развитие в игру.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Иконка
              Text(step['icon'], style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 32),

              // Заголовок
              Text(
                step['title'],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Описание
              Text(
                step['body'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[300],
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              // Индикатор шагов
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _steps.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _step ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _step
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[700],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Кнопки
              Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: () {
                        setState(() => _step--);
                      },
                      child: const Text('Назад'),
                    )
                  else
                    const SizedBox(width: 80),
                  const Spacer(),
                  FilledButton(
                    onPressed: () async {
                      if (_step < _steps.length - 1) {
                        setState(() => _step++);
                      } else {
                        await FinanceOnboarding.markDone();
                        widget.onComplete();
                      }
                    },
                    child: Text(_step < _steps.length - 1 ? 'Далее' : 'Начать'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Пропустить
              if (_step < _steps.length - 1)
                TextButton(
                  onPressed: () async {
                    await FinanceOnboarding.markDone();
                    widget.onComplete();
                  },
                  child: Text(
                    'Пропустить',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

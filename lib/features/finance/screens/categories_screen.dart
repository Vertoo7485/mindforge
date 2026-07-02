import 'package:flutter/material.dart';
import '../models/categories_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<String> _expenseCategories = [];
  List<String> _incomeCategories = [];
  final _newCategoryController = TextEditingController();
  String _activeTab = 'expense';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final expense = await CategoriesService.getExpenseCategories();
    final income = await CategoriesService.getIncomeCategories();
    setState(() {
      _expenseCategories = expense;
      _incomeCategories = income;
    });
  }

  Future<void> _addCategory() async {
    final name = _newCategoryController.text.trim();
    if (name.isEmpty) return;

    if (_activeTab == 'expense') {
      await CategoriesService.addExpenseCategory(name);
    } else {
      await CategoriesService.addIncomeCategory(name);
    }
    _newCategoryController.clear();
    _load();
  }

  Future<void> _removeCategory(String category) async {
    if (_activeTab == 'expense') {
      await CategoriesService.removeExpenseCategory(category);
    } else {
      await CategoriesService.removeIncomeCategory(category);
    }
    _load();
  }

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _activeTab == 'expense'
        ? _expenseCategories
        : _incomeCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Категории'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Сбросить по умолчанию',
            onPressed: () async {
              await CategoriesService.resetAll();
              _load();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Переключатель вкладок
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeTab = 'expense'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _activeTab == 'expense'
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Расходы',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _activeTab == 'expense'
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeTab = 'income'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _activeTab == 'income'
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Доходы',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _activeTab == 'income'
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Добавление новой категории
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newCategoryController,
                    decoration: const InputDecoration(
                      hintText: 'Новая категория',
                    ),
                    onSubmitted: (_) => _addCategory(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: _addCategory,
                ),
              ],
            ),
          ),
          // Список категорий
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  title: Text(category),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.grey,
                    onPressed: () => _removeCategory(category),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

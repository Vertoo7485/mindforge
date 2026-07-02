import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CategoriesService {
  static const _expenseKey = 'expense_categories';
  static const _incomeKey = 'income_categories';

  static final List<String> defaultExpenseCategories = [
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

  static final List<String> defaultIncomeCategories = [
    'Зарплата',
    'Фриланс',
    'Подарок',
    'Кэшбэк',
    'Инвестиции',
    'Другое',
  ];

  static Future<List<String>> getExpenseCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_expenseKey);
    if (stored == null) {
      await prefs.setString(_expenseKey, jsonEncode(defaultExpenseCategories));
      return List<String>.from(defaultExpenseCategories);
    }
    return List<String>.from(jsonDecode(stored));
  }

  static Future<List<String>> getIncomeCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_incomeKey);
    if (stored == null) {
      await prefs.setString(_incomeKey, jsonEncode(defaultIncomeCategories));
      return List<String>.from(defaultIncomeCategories);
    }
    return List<String>.from(jsonDecode(stored));
  }

  static Future<void> addExpenseCategory(String category) async {
    final categories = await getExpenseCategories();
    if (!categories.contains(category)) {
      categories.add(category);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_expenseKey, jsonEncode(categories));
    }
  }

  static Future<void> addIncomeCategory(String category) async {
    final categories = await getIncomeCategories();
    if (!categories.contains(category)) {
      categories.add(category);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_incomeKey, jsonEncode(categories));
    }
  }

  static Future<void> removeExpenseCategory(String category) async {
    final categories = await getExpenseCategories();
    categories.remove(category);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_expenseKey, jsonEncode(categories));
  }

  static Future<void> removeIncomeCategory(String category) async {
    final categories = await getIncomeCategories();
    categories.remove(category);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_incomeKey, jsonEncode(categories));
  }

  /// Сброс к категориям по умолчанию
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_expenseKey, jsonEncode(defaultExpenseCategories));
    await prefs.setString(_incomeKey, jsonEncode(defaultIncomeCategories));
  }
}

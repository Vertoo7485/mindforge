import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HabitDaysService {
  static const _prefix = 'habit_custom_days_';

  static Future<Set<int>> getDays(int habitId) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('$_prefix$habitId');
    if (stored == null) return {1, 2, 3, 4, 5}; // Пн-Пт по умолчанию
    return (jsonDecode(stored) as List).map((e) => e as int).toSet();
  }

  static Future<void> setDays(int habitId, Set<int> days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$habitId', jsonEncode(days.toList()));
  }

  static Future<void> delete(int habitId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$habitId');
  }
}

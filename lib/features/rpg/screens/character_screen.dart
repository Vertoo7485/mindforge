import 'package:flutter/material.dart';
import '../../../main.dart';
import '../models/rpg_database.dart';

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  CharacterData? _character;
  List<Attribute> _attributes = [];
  List<Achievement> _achievements = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await rpgDatabase.initAchievements();
    final char = await rpgDatabase.getCharacter();
    final attrs = await rpgDatabase.getAttributes();
    final achievements = await rpgDatabase.getAchievements();
    setState(() {
      _character = char;
      _attributes = attrs;
      _achievements = achievements;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_character == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Персонаж')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CharacterCard(character: _character!),
          const SizedBox(height: 24),
          const Text(
            'АТРИБУТЫ',
            style: TextStyle(fontSize: 12, letterSpacing: 2),
          ),
          const SizedBox(height: 12),
          ..._attributes.map((a) => _AttributeBar(attribute: a)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ДОСТИЖЕНИЯ',
                style: TextStyle(fontSize: 12, letterSpacing: 2),
              ),
              Text(
                '$unlockedCount из ${_achievements.length}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_achievements.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Нет достижений',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._achievements.map((a) => _AchievementCard(achievement: a)),
        ],
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final CharacterData character;
  const _CharacterCard({required this.character});

  @override
  Widget build(BuildContext context) {
    final percent = character.xp / character.xpToNextLevel;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Text(character.avatar, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(
            character.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Уровень ${character.level}',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 12,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${character.xp} / ${character.xpToNextLevel} XP',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _AttributeBar extends StatelessWidget {
  final Attribute attribute;
  const _AttributeBar({required this.attribute});

  @override
  Widget build(BuildContext context) {
    final icons = {
      'strength': '💪 Сила',
      'wisdom': '🧠 Мудрость',
      'resource': '💰 Ресурс',
      'energy': '⚡ Энергия',
      'balance': '☯️ Баланс',
    };
    final colors = {
      'strength': Colors.redAccent,
      'wisdom': Colors.blueAccent,
      'resource': Colors.greenAccent,
      'energy': Colors.orangeAccent,
      'balance': Colors.purpleAccent,
    };
    final icon = icons[attribute.name] ?? attribute.name;
    final color = colors[attribute.name] ?? Colors.grey;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(child: Text(icon, style: const TextStyle(fontSize: 14))),
            const SizedBox(width: 12),
            Row(
              children: List.generate(10, (i) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 2),
                  decoration: BoxDecoration(
                    color: i < attribute.value ? color : Colors.grey[800],
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: achievement.isUnlocked
                ? Colors.orangeAccent.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              achievement.icon,
              style: TextStyle(
                fontSize: 20,
                color: achievement.isUnlocked
                    ? Colors.orangeAccent
                    : Colors.grey,
              ),
            ),
          ),
        ),
        title: Text(
          achievement.title,
          style: TextStyle(color: achievement.isUnlocked ? null : Colors.grey),
        ),
        subtitle: Text(
          achievement.description,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        trailing: achievement.isUnlocked
            ? const Icon(Icons.check_circle, color: Colors.orangeAccent)
            : const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
      ),
    );
  }
}

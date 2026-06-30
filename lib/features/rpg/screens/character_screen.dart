import 'package:flutter/material.dart';

class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Персонаж')),
      body: const Center(child: Text('⚔️ Здесь будет RPG-персонаж')),
    );
  }
}

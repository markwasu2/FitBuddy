import 'package:flutter/material.dart';

class AICoachView extends StatelessWidget {
  const AICoachView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coach'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'AI Coach View - Coming Soon',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
} 
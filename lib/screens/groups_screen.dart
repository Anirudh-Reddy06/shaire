import 'package:flutter/material.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Groups Screen',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
import 'package:flutter/material.dart';

class ExpenseCategory {
  const ExpenseCategory({
    required this.color,
    required this.icon,
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
}

const expenseCategories = <ExpenseCategory>[
  ExpenseCategory(
    color: Colors.green,
    icon: Icons.food_bank,
    id: 'food',
    label: 'Food',
  ),
  ExpenseCategory(
    color: Colors.blue,
    icon: Icons.health_and_safety_outlined,
    id: 'health',
    label: 'Health',
  ),
  ExpenseCategory(
    color: Colors.purpleAccent,
    icon: Icons.festival_rounded,
    id: 'fun',
    label: 'fun',
  ),
  ExpenseCategory(
    color: Colors.yellow,
    icon: Icons.bus_alert,
    id: 'transport',
    label: 'Transport',
  ),
  ExpenseCategory(
    color: Colors.orange,
    icon: Icons.family_restroom,
    id: 'family',
    label: 'Family',
  ),
  ExpenseCategory(color: Colors.grey, icon: Icons.category, id: 'other', label: 'Other')
];

ExpenseCategory categoryById(String id) {
  return expenseCategories.firstWhere(
    (c) => c.id == id,
    orElse: () => expenseCategories.last, 
  );
}

import 'package:flutter/material.dart';

/// Expense categories (same set as the web app).
const List<String> kCategories = [
  'Housing / Rent',
  'Utilities',
  'Groceries',
  'Dining Out',
  'Transport / Fuel',
  'Healthcare',
  'Education',
  'Childcare',
  'Insurance',
  'Entertainment',
  'Shopping',
  'Personal Care',
  'Loan / EMI',
  'Savings / Investment',
  'Miscellaneous',
];

/// Payment methods.
const List<String> kPayments = [
  'Cash',
  'UPI',
  'Debit Card',
  'Credit Card',
  'Bank Transfer',
  'Net Banking',
];

/// Sensible starting budgets used when a month has none yet.
const Map<String, double> kDefaultBudgets = {
  'Housing / Rent': 1000,
  'Utilities': 1000,
  'Groceries': 1000,
  'Dining Out': 1000,
  'Transport / Fuel': 1000,
  'Healthcare': 1000,
  'Education': 1000,
  'Childcare': 1000,
  'Insurance': 1000,
  'Entertainment': 1000,
  'Shopping': 1000,
  'Personal Care': 1000,
  'Loan / EMI': 1000,
  'Savings / Investment': 1000,
  'Miscellaneous': 1000,
};

/// Chart palette (matches the web app).
const List<Color> kPalette = [
  Color(0xFF1F3A5F),
  Color(0xFF2E6F95),
  Color(0xFF3D8EB9),
  Color(0xFF5AA9C9),
  Color(0xFF7CC0D8),
  Color(0xFFF9A825),
  Color(0xFFE07A3F),
  Color(0xFFC62828),
  Color(0xFF8E44AD),
  Color(0xFF16A085),
  Color(0xFF2E7D32),
  Color(0xFF6B7280),
  Color(0xFFB58B00),
  Color(0xFF0277BD),
  Color(0xFFAD1457),
];

/// Brand colors.
class AppColors {
  static const dark = Color(0xFF1F3A5F);
  static const accent = Color(0xFF2E6F95);
  static const light = Color(0xFFD9E6F2);
  static const zebra = Color(0xFFF2F7FB);
  static const green = Color(0xFF2E7D32);
  static const red = Color(0xFFC62828);
  static const amber = Color(0xFFF9A825);
  static const grey = Color(0xFF6B7280);
  static const bg = Color(0xFFF6F8FB);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E8F0);
}

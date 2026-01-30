import 'dart:async';

import 'package:expense_tracker_fresh/core/categories/expense_categories.dart';
import 'package:expense_tracker_fresh/core/massengerKey/messenger_key.dart';
import 'package:expense_tracker_fresh/features/expenses/domain/expense.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/expenses_providers.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, this.initial});
  final Expense? initial;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  DateTime _spentAt = DateTime.now();
  String _selectedCategoryId = 'other';
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    if (e != null) {
      _amountCtrl.text = (e.amountCents / 100).toStringAsFixed(2);
      _noteCtrl.text = e.note ?? '';
      _spentAt = e.spentAt;
      _selectedCategoryId = e.categoryId;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  int? _parseAmountToCents(String input) {
    final v = input.trim().replaceAll(',', '.');
    if (v.isEmpty) return null;
    final d = double.tryParse(v);
    if (d == null) return null;

    final cents = (d * 100).round();
    if (cents <= 0) return null;
    return cents;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _spentAt,
      firstDate: DateTime(now.year - 5),
      lastDate: today,
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() => _spentAt = picked);
  }

  Future<void> _save() async {
    if (_saving) return;

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final cents = _parseAmountToCents(_amountCtrl.text);
    if (cents == null) return;

    setState(() => _saving = true);

    final repo = ref.read(expensesRepositoryProvider);
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    messengerKeyImp.currentState?.clearSnackBars();
    messengerKeyImp.currentState?.showSnackBar(
      const SnackBar(content: Text('Saving…'), duration: Duration(seconds: 1)),
    );

    if (mounted) context.pop();

    () async {
      try {
        if (widget.initial == null) {
          await repo.addExpense(
            amountCents: cents,
            spentAt: _spentAt,
            currency: 'EUR',
            categoryId: _selectedCategoryId,
            note: note,
          );
        } else {
          final e = widget.initial!;
          await repo.updateExpense(
            expenseId: e.id,
            amountCents: cents,
            spentAt: _spentAt,
            currency: e.currency,
            categoryId: _selectedCategoryId,
            note: note,
          );
        }

        messengerKeyImp.currentState?.clearSnackBars();
        messengerKeyImp.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Saved'),
            duration: Duration(seconds: 1),
          ),
        );
      } catch (e) {
        messengerKeyImp.currentState?.clearSnackBars();
        messengerKeyImp.currentState?.showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }();
  }

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${_spentAt.year}-${_spentAt.month.toString().padLeft(2, '0')}-${_spentAt.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit expense' : 'Add expense')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Amount (e.g. 12.99)',
                    ),
                    validator: (v) {
                      final cents = _parseAmountToCents(v ?? '');
                      if (cents == null) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(child: Text('Date: $dateText')),
                      TextButton(
                        onPressed: _saving ? null : _pickDate,
                        child: const Text('Pick'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    items: expenseCategories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Row(
                              children: [
                                Icon(c.icon, color: c.color),
                                const SizedBox(width: 8),
                                Text(c.label),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (v) {
                            if (v == null) return;
                            setState(() => _selectedCategoryId = v);
                          },
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _noteCtrl,
                    maxLength: 140,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                    ),
                    validator: (v) {
                      if (v == null) return null;
                      if (v.trim().length > 140) return 'Too long';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: Text(
                        _saving
                            ? 'Saving…'
                            : (_isEdit ? 'Save changes' : 'Save'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

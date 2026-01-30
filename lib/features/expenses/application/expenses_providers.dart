import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_fresh/features/expenses/date/expenses_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  final db = ref.read(firebaseFirestoreProvider);
  final auth = ref.read(firebaseAuthProvider);
  return ExpensesRepository(db, auth);
});
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/expense.dart';
import '../../../core/utils/month_key.dart';
import 'package:expense_tracker_fresh/core/period/period_filter.dart';

class ExpensesRepository {
  ExpensesRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Not logged in');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _ref =>
      _db.collection('users').doc(_uid).collection('expenses');

  Future<void> deleteExpense(String expenseId) async {
    await _ref.doc(expenseId).delete();
  }


  Future<String> addExpense({
    required int amountCents,
    required DateTime spentAt,
    required String currency,
    required String categoryId,
    String? note,
  }) async {
    final doc = _ref.doc();

    await doc.set({
      'amountCents': amountCents,
      'currency': currency,
      'categoryId': categoryId,
      'note': note,
      'spentAt': Timestamp.fromDate(spentAt),
      'monthKey': monthKey(spentAt),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  Future<void> addExpenseFromModel(Expense e) async {
    final doc = _ref.doc(e.id);
    await doc.set({
      'amountCents': e.amountCents,
      'currency': e.currency,
      'categoryId': e.categoryId,
      'note': e.note,
      'spentAt': Timestamp.fromDate(e.spentAt),
      'monthKey': monthKey(e.spentAt),
      'createdAt': e.createdAt != null
          ? Timestamp.fromDate(e.createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': e.updatedAt != null
          ? Timestamp.fromDate(e.updatedAt!)
          : FieldValue.serverTimestamp(),
    });
  

    await doc.set({
      'amountCents': e.amountCents,
      'currency': e.currency,
      'categoryId': e.categoryId,
      'note': e.note,
      'spentAt': Timestamp.fromDate(e.spentAt),
      'monthKey': monthKey(e.spentAt),

      'createdAt': e.createdAt != null
          ? Timestamp.fromDate(e.createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': e.updatedAt != null
          ? Timestamp.fromDate(e.updatedAt!)
          : FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateExpense({
    required String expenseId,
    required int amountCents,
    required DateTime spentAt,
    required String currency,
    required String categoryId,
    String? note,
  }) async {
    await _ref.doc(expenseId).update({
      'amountCents': amountCents,
      'currency': currency,
      'categoryId': categoryId,
      'note': note,
      'spentAt': Timestamp.fromDate(spentAt),
      'monthKey': monthKey(spentAt),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Expense>> watchExpensesByMonth(String monthKeyValue) {
    final q = _ref
        .where('monthKey', isEqualTo: monthKeyValue)
        .orderBy('spentAt', descending: true);

    return q.snapshots().map((snap) {
      return snap.docs.map((d) {
        final data = d.data();

        final spentAtTs = data['spentAt'] as Timestamp;
        final createdAtTs = data['createdAt'] as Timestamp?;
        final updatedAtTs = data['updatedAt'] as Timestamp?;

        return Expense(
          id: d.id,
          amountCents: (data['amountCents'] as num).toInt(),
          currency: data['currency'] as String,
          categoryId: data['categoryId'] as String,
          note: data['note'] as String?,
          spentAt: spentAtTs.toDate(),
          monthKey: data['monthKey'] as String,
          createdAt: createdAtTs?.toDate(),
          updatedAt: updatedAtTs?.toDate(),
        );
      }).toList();
    });
  }



  Stream<List<Expense>> watchExpenses(PeriodFilter filter) {
    Query<Map<String, dynamic>> q = _ref.orderBy('spentAt', descending: true);

    DateTime? start;
    DateTime? end;

    if (filter.type != PeriodType.allTime) {
      start = filter.anchor!;
      switch (filter.type) {
        case PeriodType.year:
          end = DateTime(start.year + 1, 1, 1);
          break;
        case PeriodType.month:
          end = DateTime(start.year, start.month + 1, 1);
          break;
        case PeriodType.day:
          end = DateTime(start.year, start.month, start.day + 1);
          break;
        case PeriodType.allTime:
          break;
      }

      q = q
          .where('spentAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('spentAt', isLessThan: Timestamp.fromDate(end!));
    }

    return q.snapshots().map((snap) {
      return snap.docs.map((d) {
        final data = d.data();

        final spentAtTs = data['spentAt'] as Timestamp;
        final createdAtTs = data['createdAt'] as Timestamp?;
        final updatedAtTs = data['updatedAt'] as Timestamp?;

        return Expense(
          id: d.id,
          amountCents: (data['amountCents'] as num).toInt(),
          currency: data['currency'] as String,
          categoryId: data['categoryId'] as String,
          note: data['note'] as String?,
          spentAt: spentAtTs.toDate(),
          monthKey: data['monthKey'] as String,
          createdAt: createdAtTs?.toDate(),
          updatedAt: updatedAtTs?.toDate(),
        );
      }).toList();
    });
  }
}

class Expense {
  const Expense({
    required this.id,
    required this.amountCents,
    required this.currency,
    required this.categoryId,
    required this.spentAt,
    required this.monthKey,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final int amountCents;
  final String currency;
  final String categoryId;
  final String? note;
  final DateTime spentAt;
  final String monthKey;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Expense copyWith({
    String? id,
    int? amountCents,
    String? currency,
    String? categoryId,
    String? note,
    DateTime? spentAt,
    String? monthKey,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amountCents: amountCents ?? this.amountCents,
      currency: currency ?? this.currency,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      spentAt: spentAt ?? this.spentAt,
      monthKey: monthKey ?? this.monthKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

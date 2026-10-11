class ExpenseSplitItem {
  final String personId;
  final double amount;
  final double? percentage;
  final int? shares;

  const ExpenseSplitItem({
    required this.personId,
    required this.amount,
    this.percentage,
    this.shares,
  });

  Map<String, dynamic> toSqliteMap(String expenseId, String splitId) {
    return {
      'id': splitId,
      'expense_id': expenseId,
      'person_id': personId,
      'amount': amount,
      'percentage': percentage,
      'shares': shares,
    };
  }

  factory ExpenseSplitItem.fromSqliteMap(Map<String, dynamic> map) {
    return ExpenseSplitItem(
      personId: map['person_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      percentage: (map['percentage'] as num?)?.toDouble(),
      shares: map['shares'] as int?,
    );
  }

  ExpenseSplitItem copyWith({
    String? personId,
    double? amount,
    double? percentage,
    int? shares,
  }) {
    return ExpenseSplitItem(
      personId: personId ?? this.personId,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
      shares: shares ?? this.shares,
    );
  }
}

class SplitExpenseModel {
  final String id;
  final String title;
  final double totalAmount;
  final DateTime date;
  final String paidByPersonId;
  final String? groupId;
  final String? categoryId;
  final String? notes;
  final String splitType; // 'equal', 'exact', 'percentage'
  final List<ExpenseSplitItem> splits;
  final String? linkedCashBookTxId;
  final DateTime createdAt;

  const SplitExpenseModel({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.date,
    required this.paidByPersonId,
    this.groupId,
    this.categoryId,
    this.notes,
    this.splitType = 'equal',
    this.splits = const [],
    this.linkedCashBookTxId,
    required this.createdAt,
  });

  SplitExpenseModel copyWith({
    String? id,
    String? title,
    double? totalAmount,
    DateTime? date,
    String? paidByPersonId,
    String? groupId,
    String? categoryId,
    String? notes,
    String? splitType,
    List<ExpenseSplitItem>? splits,
    String? linkedCashBookTxId,
    DateTime? createdAt,
  }) {
    return SplitExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      date: date ?? this.date,
      paidByPersonId: paidByPersonId ?? this.paidByPersonId,
      groupId: groupId ?? this.groupId,
      categoryId: categoryId ?? this.categoryId,
      notes: notes ?? this.notes,
      splitType: splitType ?? this.splitType,
      splits: splits ?? this.splits,
      linkedCashBookTxId: linkedCashBookTxId ?? this.linkedCashBookTxId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'title': title,
      'total_amount': totalAmount,
      'date': date.toIso8601String(),
      'paid_by_person_id': paidByPersonId,
      'group_id': groupId,
      'category_id': categoryId,
      'notes': notes,
      'split_type': splitType,
      'linked_cash_book_tx_id': linkedCashBookTxId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SplitExpenseModel.fromSqliteMap(
    Map<String, dynamic> map, {
    List<ExpenseSplitItem> splits = const [],
  }) {
    return SplitExpenseModel(
      id: map['id'] as String,
      title: map['title'] as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      paidByPersonId: map['paid_by_person_id'] as String,
      groupId: map['group_id'] as String?,
      categoryId: map['category_id'] as String?,
      notes: map['notes'] as String?,
      splitType: map['split_type'] as String? ?? 'equal',
      splits: splits,
      linkedCashBookTxId: map['linked_cash_book_tx_id'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

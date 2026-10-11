class SettlementModel {
  final String id;
  final String payerId;
  final String receiverId;
  final double amount;
  final DateTime date;
  final String? groupId;
  final String paymentMethod;
  final String? notes;
  final String? linkedCashBookTxId;
  final DateTime createdAt;

  const SettlementModel({
    required this.id,
    required this.payerId,
    required this.receiverId,
    required this.amount,
    required this.date,
    this.groupId,
    this.paymentMethod = 'UPI',
    this.notes,
    this.linkedCashBookTxId,
    required this.createdAt,
  });

  SettlementModel copyWith({
    String? id,
    String? payerId,
    String? receiverId,
    double? amount,
    DateTime? date,
    String? groupId,
    String? paymentMethod,
    String? notes,
    String? linkedCashBookTxId,
    DateTime? createdAt,
  }) {
    return SettlementModel(
      id: id ?? this.id,
      payerId: payerId ?? this.payerId,
      receiverId: receiverId ?? this.receiverId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      groupId: groupId ?? this.groupId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      linkedCashBookTxId: linkedCashBookTxId ?? this.linkedCashBookTxId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'payer_id': payerId,
      'receiver_id': receiverId,
      'amount': amount,
      'date': date.toIso8601String(),
      'group_id': groupId,
      'payment_method': paymentMethod,
      'notes': notes,
      'linked_cash_book_tx_id': linkedCashBookTxId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SettlementModel.fromSqliteMap(Map<String, dynamic> map) {
    return SettlementModel(
      id: map['id'] as String,
      payerId: map['payer_id'] as String,
      receiverId: map['receiver_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      groupId: map['group_id'] as String?,
      paymentMethod: map['payment_method'] as String? ?? 'UPI',
      notes: map['notes'] as String?,
      linkedCashBookTxId: map['linked_cash_book_tx_id'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

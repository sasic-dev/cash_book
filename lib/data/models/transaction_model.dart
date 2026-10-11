import 'transaction_type.dart';

class TransactionModel {
  final String id;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final DateTime date;
  final String title;
  final String paymentMode;

  const TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    required this.title,
    this.paymentMode = 'Cash',
  });

  TransactionModel copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? categoryId,
    DateTime? date,
    String? title,
    String? paymentMode,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      title: title ?? this.title,
      paymentMode: paymentMode ?? this.paymentMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type.name,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'title': title,
      'paymentMode': paymentMode,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.fromString(map['type'] as String? ?? 'expense'),
      categoryId: map['categoryId'] as String? ?? 'exp_other',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      title: map['title'] as String? ?? '',
      paymentMode: map['paymentMode'] as String? ?? 'Cash',
    );
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type.name,
      'category_id': categoryId,
      'date': date.toIso8601String(),
      'title': title,
      'payment_mode': paymentMode,
    };
  }

  factory TransactionModel.fromSqliteMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.fromString(map['type'] as String? ?? 'expense'),
      categoryId: (map['category_id'] as String?) ??
          (map['categoryId'] as String?) ??
          'exp_other',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      title: map['title'] as String? ?? '',
      paymentMode: (map['payment_mode'] as String?) ??
          (map['paymentMode'] as String?) ??
          'Cash',
    );
  }
}


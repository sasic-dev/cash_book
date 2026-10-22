import '../../config/app_constants.dart';
import 'transaction_type.dart';

class TransactionModel {
  final String id;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final DateTime date;
  final String title;
  final String paymentMode;
  final double? baseInrAmount;

  final String? attachmentPath;

  const TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    required this.title,
    this.paymentMode = AppConstants.defaultPaymentMode,
    this.baseInrAmount,
    this.attachmentPath,
  });

  bool get hasAttachment => attachmentPath != null && attachmentPath!.trim().isNotEmpty;

  bool get isImageAttachment {
    if (!hasAttachment) return false;
    final path = attachmentPath!.toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp') ||
        path.endsWith('.heic') ||
        path.endsWith('.bmp');
  }

  bool get isPdfAttachment {
    if (!hasAttachment) return false;
    return attachmentPath!.toLowerCase().endsWith('.pdf');
  }

  TransactionModel copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? categoryId,
    DateTime? date,
    String? title,
    String? paymentMode,
    double? baseInrAmount,
    String? attachmentPath,
    bool clearAttachment = false,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      title: title ?? this.title,
      paymentMode: paymentMode ?? this.paymentMode,
      baseInrAmount: baseInrAmount ?? this.baseInrAmount,
      attachmentPath: clearAttachment ? null : (attachmentPath ?? this.attachmentPath),
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
      if (baseInrAmount != null) 'baseInrAmount': baseInrAmount,
      if (attachmentPath != null) 'attachmentPath': attachmentPath,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.fromString(map['type'] as String? ?? 'expense'),
      categoryId: map['categoryId'] as String? ?? AppConstants.fallbackExpenseCategoryId,
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      title: map['title'] as String? ?? '',
      paymentMode: map['paymentMode'] as String? ?? AppConstants.defaultPaymentMode,
      baseInrAmount: (map['baseInrAmount'] as num?)?.toDouble() ??
          (map['base_inr_amount'] as num?)?.toDouble(),
      attachmentPath: (map['attachmentPath'] as String?) ??
          (map['attachment_path'] as String?),
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
      if (baseInrAmount != null) 'base_inr_amount': baseInrAmount,
      if (attachmentPath != null) 'attachment_path': attachmentPath,
    };
  }

  factory TransactionModel.fromSqliteMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.fromString(map['type'] as String? ?? 'expense'),
      categoryId: (map['category_id'] as String?) ??
          (map['categoryId'] as String?) ??
          AppConstants.fallbackExpenseCategoryId,
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      title: map['title'] as String? ?? '',
      paymentMode: (map['payment_mode'] as String?) ??
          (map['paymentMode'] as String?) ??
          AppConstants.defaultPaymentMode,
      baseInrAmount: (map['base_inr_amount'] as num?)?.toDouble() ??
          (map['baseInrAmount'] as num?)?.toDouble(),
      attachmentPath: (map['attachment_path'] as String?) ??
          (map['attachmentPath'] as String?),
    );
  }
}


enum TransactionType {
  income,
  expense;

  String get label => this == TransactionType.income ? 'Income' : 'Expense';
  String get cashLabel => this == TransactionType.income ? 'Cash In' : 'Cash Out';
  bool get isIncome => this == TransactionType.income;
  bool get isExpense => this == TransactionType.expense;

  static TransactionType fromString(String value) {
    if (value.toLowerCase() == 'income') {
      return TransactionType.income;
    }
    return TransactionType.expense;
  }
}


import '../models/person_model.dart';
import '../models/settlement_model.dart';
import '../models/split_expense_model.dart';

class SimplifiedDebt {
  final String fromPersonId;
  final String toPersonId;
  final double amount;

  const SimplifiedDebt({
    required this.fromPersonId,
    required this.toPersonId,
    required this.amount,
  });
}

class PersonBalanceSummary {
  final String personId;
  final double totalPaid;
  final double totalShare;
  final double settlementsPaid;
  final double settlementsReceived;

  const PersonBalanceSummary({
    required this.personId,
    required this.totalPaid,
    required this.totalShare,
    required this.settlementsPaid,
    required this.settlementsReceived,
  });

  /// Positive means the person is owed money (credit).
  /// Negative means the person owes money (debt).
  double get netBalance =>
      (totalPaid + settlementsPaid) - (totalShare + settlementsReceived);
}

class SplitCalculatorService {
  /// Calculates overall balances for each person across expenses and settlements.
  static Map<String, PersonBalanceSummary> calculateAllBalances({
    required List<PersonModel> people,
    required List<SplitExpenseModel> expenses,
    required List<SettlementModel> settlements,
    String? groupIdFilter,
  }) {
    final filteredExpenses = groupIdFilter == null
        ? expenses
        : expenses.where((e) => e.groupId == groupIdFilter).toList();

    final filteredSettlements = groupIdFilter == null
        ? settlements
        : settlements.where((s) => s.groupId == groupIdFilter).toList();

    final Map<String, double> totalPaid = {};
    final Map<String, double> totalShare = {};
    final Map<String, double> settlementsPaid = {};
    final Map<String, double> settlementsReceived = {};

    for (final person in people) {
      totalPaid[person.id] = 0.0;
      totalShare[person.id] = 0.0;
      settlementsPaid[person.id] = 0.0;
      settlementsReceived[person.id] = 0.0;
    }

    for (final exp in filteredExpenses) {
      totalPaid[exp.paidByPersonId] =
          (totalPaid[exp.paidByPersonId] ?? 0.0) + exp.totalAmount;

      for (final split in exp.splits) {
        totalShare[split.personId] =
            (totalShare[split.personId] ?? 0.0) + split.amount;
      }
    }

    for (final st in filteredSettlements) {
      settlementsPaid[st.payerId] =
          (settlementsPaid[st.payerId] ?? 0.0) + st.amount;
      settlementsReceived[st.receiverId] =
          (settlementsReceived[st.receiverId] ?? 0.0) + st.amount;
    }

    final Map<String, PersonBalanceSummary> result = {};
    for (final person in people) {
      result[person.id] = PersonBalanceSummary(
        personId: person.id,
        totalPaid: totalPaid[person.id] ?? 0.0,
        totalShare: totalShare[person.id] ?? 0.0,
        settlementsPaid: settlementsPaid[person.id] ?? 0.0,
        settlementsReceived: settlementsReceived[person.id] ?? 0.0,
      );
    }
    return result;
  }

  /// Calculates pairwise balance between current user ("person_you") and a specific person.
  /// Returns:
  /// > 0: that person owes current user
  /// < 0: current user owes that person
  /// == 0: settled
  static double calculatePairwiseBalance({
    required String currentUserId,
    required String otherPersonId,
    required List<SplitExpenseModel> expenses,
    required List<SettlementModel> settlements,
    String? groupIdFilter,
  }) {
    if (currentUserId == otherPersonId) return 0.0;

    final filteredExpenses = groupIdFilter == null
        ? expenses
        : expenses.where((e) => e.groupId == groupIdFilter).toList();

    final filteredSettlements = groupIdFilter == null
        ? settlements
        : settlements.where((s) => s.groupId == groupIdFilter).toList();

    double netBalance = 0.0;

    for (final exp in filteredExpenses) {
      if (exp.paidByPersonId == currentUserId) {
        // Current user paid. Other person owes their share to current user.
        for (final split in exp.splits) {
          if (split.personId == otherPersonId) {
            netBalance += split.amount;
          }
        }
      } else if (exp.paidByPersonId == otherPersonId) {
        // Other person paid. Current user owes their share to other person.
        for (final split in exp.splits) {
          if (split.personId == currentUserId) {
            netBalance -= split.amount;
          }
        }
      }
    }

    for (final st in filteredSettlements) {
      if (st.payerId == otherPersonId && st.receiverId == currentUserId) {
        // Other person repaid current user -> reduces what they owe
        netBalance -= st.amount;
      } else if (st.payerId == currentUserId && st.receiverId == otherPersonId) {
        // Current user repaid other person -> reduces what current user owes (increases netBalance)
        netBalance += st.amount;
      }
    }

    return netBalance;
  }

  /// Calculates simplified debt settlement list for a group.
  /// Minimizes total number of transactions needed to settle everyone.
  static List<SimplifiedDebt> calculateSimplifiedDebts({
    required List<String> memberIds,
    required List<SplitExpenseModel> expenses,
    required List<SettlementModel> settlements,
    required String groupId,
  }) {
    final Map<String, double> netBalances = {};
    for (final id in memberIds) {
      netBalances[id] = 0.0;
    }

    final groupExpenses = expenses.where((e) => e.groupId == groupId);
    for (final exp in groupExpenses) {
      netBalances[exp.paidByPersonId] =
          (netBalances[exp.paidByPersonId] ?? 0.0) + exp.totalAmount;
      for (final split in exp.splits) {
        netBalances[split.personId] =
            (netBalances[split.personId] ?? 0.0) - split.amount;
      }
    }

    final groupSettlements = settlements.where((s) => s.groupId == groupId);
    for (final st in groupSettlements) {
      netBalances[st.payerId] =
          (netBalances[st.payerId] ?? 0.0) + st.amount;
      netBalances[st.receiverId] =
          (netBalances[st.receiverId] ?? 0.0) - st.amount;
    }

    final List<MapEntry<String, double>> creditors = [];
    final List<MapEntry<String, double>> debtors = [];

    netBalances.forEach((personId, balance) {
      if (balance > 0.01) {
        creditors.add(MapEntry(personId, balance));
      } else if (balance < -0.01) {
        debtors.add(MapEntry(personId, -balance)); // store as positive debt
      }
    });

    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => b.value.compareTo(a.value));

    final List<SimplifiedDebt> debts = [];
    int cIdx = 0;
    int dIdx = 0;

    while (cIdx < creditors.length && dIdx < debtors.length) {
      final creditor = creditors[cIdx];
      final debtor = debtors[dIdx];

      final minAmount = creditor.value < debtor.value ? creditor.value : debtor.value;
      if (minAmount > 0.01) {
        debts.add(SimplifiedDebt(
          fromPersonId: debtor.key,
          toPersonId: creditor.key,
          amount: double.parse(minAmount.toStringAsFixed(2)),
        ));
      }

      final remainingCredit = creditor.value - minAmount;
      final remainingDebt = debtor.value - minAmount;

      if (remainingCredit <= 0.01) {
        cIdx++;
      } else {
        creditors[cIdx] = MapEntry(creditor.key, remainingCredit);
      }

      if (remainingDebt <= 0.01) {
        dIdx++;
      } else {
        debtors[dIdx] = MapEntry(debtor.key, remainingDebt);
      }
    }

    return debts;
  }
}

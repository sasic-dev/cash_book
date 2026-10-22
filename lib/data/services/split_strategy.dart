import '../models/split_expense_model.dart';

/// Abstract strategy defining how an expense is divided among participants.
/// Adheres to the Open/Closed Principle (OCP): new split mechanisms (e.g. shares, adjustments)
/// can be added by implementing [SplitStrategy] and registering it in [SplitStrategyRegistry]
/// without altering existing calculation logic or UI screens.
abstract class SplitStrategy {
  /// Unique identifier key for this strategy (e.g. 'equal', 'exact', 'percentage')
  String get typeName;

  /// User-friendly label for display in UI tab bars or dropdowns
  String get displayName;

  /// Calculates the list of [ExpenseSplitItem] for all participants based on total amount and inputs.
  List<ExpenseSplitItem> calculateSplits({
    required double totalAmount,
    required List<String> participantIds,
    Map<String, double>? customInputs,
  });

  /// Validates the inputs. Returns `null` if valid, or an error description string if invalid.
  String? validate({
    required double totalAmount,
    required List<String> participantIds,
    Map<String, double>? customInputs,
  });
}

/// Strategy for dividing the total amount equally among all participants,
/// with the final cent/paisa assigned to the last participant to guarantee sum conservation.
class EqualSplitStrategy implements SplitStrategy {
  const EqualSplitStrategy();

  @override
  String get typeName => 'equal';

  @override
  String get displayName => 'Equal';

  @override
  List<ExpenseSplitItem> calculateSplits({
    required double totalAmount,
    required List<String> participantIds,
    Map<String, double>? customInputs,
  }) {
    if (participantIds.isEmpty) return const [];
    final count = participantIds.length;
    final baseShare = (totalAmount / count);
    final roundedBase = double.parse(baseShare.toStringAsFixed(2));
    double sumAllocated = 0.0;
    final List<ExpenseSplitItem> splits = [];

    for (int i = 0; i < count; i++) {
      final pId = participantIds[i];
      if (i == count - 1) {
        // Adjust last participant with remaining rounding difference
        final remainder = double.parse((totalAmount - sumAllocated).toStringAsFixed(2));
        splits.add(ExpenseSplitItem(personId: pId, amount: remainder));
      } else {
        splits.add(ExpenseSplitItem(personId: pId, amount: roundedBase));
        sumAllocated += roundedBase;
      }
    }
    return splits;
  }

  @override
  String? validate({
    required double totalAmount,
    required List<String> participantIds,
    Map<String, double>? customInputs,
  }) {
    if (participantIds.isEmpty) {
      return 'Please select at least one participant';
    }
    if (totalAmount <= 0) {
      return 'Total amount must be greater than zero';
    }
    return null;
  }
}

/// Strategy for allocating specific exact amounts to each participant.
class ExactSplitStrategy implements SplitStrategy {
  const ExactSplitStrategy();

  @override
  String get typeName => 'exact';

  @override
  String get displayName => 'Exact Amounts';

  @override
  List<ExpenseSplitItem> calculateSplits({
    required double totalAmount,
    required List<String> participantIds,
    Map<String, double>? customInputs,
  }) {
    final inputs = customInputs ?? const {};
    return participantIds.map((pId) {
      final val = inputs[pId] ?? 0.0;
      return ExpenseSplitItem(personId: pId, amount: val);
    }).toList();
  }

  @override
  String? validate({
    required double totalAmount,
    required List<String> participantIds,
    Map<String, double>? customInputs,
  }) {
    if (participantIds.isEmpty) {
      return 'Please select at least one participant';
    }
    final inputs = customInputs ?? const {};
    double totalAllocated = 0.0;
    for (final pId in participantIds) {
      totalAllocated += (inputs[pId] ?? 0.0);
    }

    if ((totalAllocated - totalAmount).abs() > 0.05) {
      return 'Sum of exact amounts must match total amount ($totalAmount)';
    }
    return null;
  }
}

/// Strategy for allocating shares by percentage.
class PercentageSplitStrategy implements SplitStrategy {
  const PercentageSplitStrategy();

  @override
  String get typeName => 'percentage';

  @override
  String get displayName => 'Percentage';

  @override
  List<ExpenseSplitItem> calculateSplits({
    required double totalAmount,
    required List<String> participantIds,
    Map<String, double>? customInputs,
  }) {
    final inputs = customInputs ?? const {};
    return participantIds.map((pId) {
      final pct = inputs[pId] ?? 0.0;
      final share = double.parse(((pct / 100) * totalAmount).toStringAsFixed(2));
      return ExpenseSplitItem(
        personId: pId,
        amount: share,
        percentage: pct,
      );
    }).toList();
  }

  @override
  String? validate({
    required double totalAmount,
    required List<String> participantIds,
    Map<String, double>? customInputs,
  }) {
    if (participantIds.isEmpty) {
      return 'Please select at least one participant';
    }
    final inputs = customInputs ?? const {};
    double totalPct = 0.0;
    for (final pId in participantIds) {
      totalPct += (inputs[pId] ?? 0.0);
    }

    if ((totalPct - 100.0).abs() > 0.1) {
      return 'Total percentage must equal exactly 100% (currently ${totalPct.toStringAsFixed(1)}%)';
    }
    return null;
  }
}

/// Registry for managing available split calculation strategies.
/// Follows Open/Closed Principle: consumers can register additional custom strategies
/// at runtime without modifying this registry or existing strategy code.
class SplitStrategyRegistry {
  static final Map<String, SplitStrategy> _strategies = {
    'equal': const EqualSplitStrategy(),
    'exact': const ExactSplitStrategy(),
    'percentage': const PercentageSplitStrategy(),
  };

  /// Registers or overrides a split strategy.
  static void register(SplitStrategy strategy) {
    _strategies[strategy.typeName] = strategy;
  }

  /// Retrieves a strategy by its type name. Defaults to [EqualSplitStrategy] if not found.
  static SplitStrategy getStrategy(String typeName) {
    return _strategies[typeName] ?? const EqualSplitStrategy();
  }

  /// Returns all registered strategies.
  static List<SplitStrategy> get allStrategies => _strategies.values.toList();
}

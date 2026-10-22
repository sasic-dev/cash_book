import 'package:flutter/material.dart';
import '../../config/app_constants.dart';
import '../../data/models/transaction_type.dart';
import '../utils/formatters.dart';
import '../view_models/cash_book_view_model.dart';

class FilterChipBar extends StatelessWidget {
  final CashBookViewModel viewModel;

  const FilterChipBar({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date period chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ...DateFilter.values.map((filter) {
                if (filter == DateFilter.custom) {
                  final isCustom = viewModel.selectedDateFilter == DateFilter.custom;
                  final label = viewModel.customDateRange != null
                      ? '${AppFormatters.date(viewModel.customDateRange!.start)} - ${AppFormatters.date(viewModel.customDateRange!.end)}'
                      : 'Custom Range';
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isCustom,
                      avatar: const Icon(Icons.date_range_rounded, size: 16),
                      label: Text(label),
                      onSelected: (_) async {
                        final now = DateTime.now();
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(AppConstants.datePickerStartYear),
                          lastDate: DateTime(AppConstants.datePickerEndYear),
                          initialDateRange: viewModel.customDateRange ??
                              DateTimeRange(
                                start: now.subtract(const Duration(days: 7)),
                                end: now,
                              ),
                        );
                        if (picked != null) {
                          viewModel.setCustomDateRange(picked);
                        }
                      },
                    ),
                  );
                }

                final isSelected = viewModel.selectedDateFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        viewModel.setDateFilter(filter);
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Type filter chips (All, Cash In, Cash Out) and Reset button
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: viewModel.selectedTypeFilter == null,
                onSelected: (selected) {
                  if (selected) {
                    viewModel.setTypeFilter(null);
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Cash In'),
                avatar: const Icon(Icons.arrow_downward_rounded,
                    color: Colors.green, size: 16),
                selected: viewModel.selectedTypeFilter == TransactionType.income,
                onSelected: (selected) {
                  viewModel.setTypeFilter(
                      selected ? TransactionType.income : null);
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Cash Out'),
                avatar: const Icon(Icons.arrow_upward_rounded,
                    color: Colors.red, size: 16),
                selected: viewModel.selectedTypeFilter == TransactionType.expense,
                onSelected: (selected) {
                  viewModel.setTypeFilter(
                      selected ? TransactionType.expense : null);
                },
              ),
              if (viewModel.selectedCategoryId != null ||
                  viewModel.selectedTypeFilter != null ||
                  viewModel.selectedDateFilter != DateFilter.thisMonth ||
                  viewModel.searchQuery.isNotEmpty) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => viewModel.resetFilters(),
                  icon: const Icon(Icons.clear_all_rounded, size: 16),
                  label: const Text('Reset', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}


// ignore_for_file: non_const_argument_for_const_parameter
import 'package:flutter/material.dart';

class CategoryIconCatalog {
  static const List<IconData> availableIcons = [
    // Finance & Work
    Icons.account_balance_wallet_rounded,
    Icons.account_balance_rounded,
    Icons.attach_money_rounded,
    Icons.currency_exchange_rounded,
    Icons.savings_rounded,
    Icons.credit_card_rounded,
    Icons.receipt_long_rounded,
    Icons.work_rounded,
    Icons.laptop_mac_rounded,
    Icons.storefront_rounded,
    Icons.trending_up_rounded,

    // Living & Home
    Icons.home_rounded,
    Icons.apartment_rounded,
    Icons.build_rounded,
    Icons.electric_bolt_rounded,
    Icons.water_drop_rounded,
    Icons.wifi_rounded,
    Icons.phone_android_rounded,

    // Food & Dining
    Icons.restaurant_rounded,
    Icons.fastfood_rounded,
    Icons.local_cafe_rounded,
    Icons.local_bar_rounded,
    Icons.shopping_cart_rounded,
    Icons.local_grocery_store_rounded,

    // Transport & Travel
    Icons.directions_car_rounded,
    Icons.two_wheeler_rounded,
    Icons.directions_bus_rounded,
    Icons.local_gas_station_rounded,
    Icons.flight_rounded,
    Icons.beach_access_rounded,

    // Health & Family
    Icons.local_hospital_rounded,
    Icons.medication_rounded,
    Icons.fitness_center_rounded,
    Icons.pets_rounded,
    Icons.child_care_rounded,
    Icons.school_rounded,

    // Shopping & Fun
    Icons.shopping_bag_rounded,
    Icons.local_mall_rounded,
    Icons.movie_rounded,
    Icons.sports_esports_rounded,
    Icons.card_giftcard_rounded,
    Icons.celebration_rounded,
    Icons.more_horiz_rounded,
  ];

  static const List<int> availableColors = [
    0xFF2E7D32, // Dark Green
    0xFF43A047, // Green
    0xFF00897B, // Teal
    0xFF00ACC1, // Cyan
    0xFF1976D2, // Blue
    0xFF3949AB, // Indigo
    0xFF5E35B1, // Deep Purple
    0xFF8E24AA, // Purple
    0xFFD81B60, // Pink
    0xFFE53935, // Red
    0xFFF4511E, // Deep Orange
    0xFFFB8C00, // Orange
    0xFFFFB300, // Amber
    0xFF6D4C41, // Brown
    0xFF546E7A, // Blue Grey
    0xFF424242, // Grey
  ];
}

class CategoryIconPickerDialog extends StatefulWidget {
  final int initialIconCode;
  final int initialColorValue;

  const CategoryIconPickerDialog({
    super.key,
    required this.initialIconCode,
    required this.initialColorValue,
  });

  @override
  State<CategoryIconPickerDialog> createState() => _CategoryIconPickerDialogState();
}

class _CategoryIconPickerDialogState extends State<CategoryIconPickerDialog> {
  late int _selectedIconCode;
  late int _selectedColorValue;

  @override
  void initState() {
    super.initState();
    _selectedIconCode = widget.initialIconCode;
    _selectedColorValue = widget.initialColorValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      title: const Text('Choose Icon & Color'),
      content: SizedBox(
        width: 340,
        height: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  color: Color(_selectedColorValue),
                  child: Icon(
                    IconData(_selectedIconCode, fontFamily: 'MaterialIcons'),
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Color Selection
              const Text(
                'Color',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CategoryIconCatalog.availableColors.map((colorVal) {
                  final isSelected = _selectedColorValue == colorVal;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColorValue = colorVal;
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(colorVal),
                        border: isSelected
                            ? Border.all(color: isDark ? Colors.white : Colors.black87, width: 3)
                            : Border.all(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), width: 1),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 18, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Icon Selection
              const Text(
                'Icon',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: CategoryIconCatalog.availableIcons.length,
                itemBuilder: (context, index) {
                  final icon = CategoryIconCatalog.availableIcons[index];
                  final isSelected = _selectedIconCode == icon.codePoint;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIconCode = icon.codePoint;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(_selectedColorValue).withValues(alpha: isDark ? 0.35 : 0.18)
                            : (isDark ? const Color(0xFF334155) : Colors.grey.shade100),
                        border: isSelected
                            ? Border.all(color: Color(_selectedColorValue), width: 2)
                            : Border.all(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), width: 1),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected
                            ? Color(_selectedColorValue)
                            : (isDark ? const Color(0xFFCBD5E1) : Colors.black87),
                        size: 22,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop({
              'iconCode': _selectedIconCode,
              'colorValue': _selectedColorValue,
            });
          },
          child: const Text('Select'),
        ),
      ],
    );
  }
}

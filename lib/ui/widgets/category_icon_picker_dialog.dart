// ignore_for_file: non_const_argument_for_const_parameter
import 'package:flutter/material.dart';
import '../../config/app_constants.dart';

class CategoryIconCatalog {
  static List<IconData> get availableIcons => AppConstants.categoryIcons;
  static List<int> get availableColors => AppConstants.categoryColorPalette;
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

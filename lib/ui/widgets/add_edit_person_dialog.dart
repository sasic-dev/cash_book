import 'package:flutter/material.dart';
import '../../data/models/person_model.dart';
import '../view_models/cash_book_view_model.dart';

class AddEditPersonDialog extends StatefulWidget {
  final CashBookViewModel viewModel;
  final PersonModel? initialPerson;

  const AddEditPersonDialog({
    super.key,
    required this.viewModel,
    this.initialPerson,
  });

  static Future<PersonModel?> show(
    BuildContext context, {
    required CashBookViewModel viewModel,
    PersonModel? initialPerson,
  }) {
    return showDialog<PersonModel>(
      context: context,
      builder: (_) => AddEditPersonDialog(
        viewModel: viewModel,
        initialPerson: initialPerson,
      ),
    );
  }

  @override
  State<AddEditPersonDialog> createState() => _AddEditPersonDialogState();
}

class _AddEditPersonDialogState extends State<AddEditPersonDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late int _selectedColor;

  final List<int> _colorPalette = const [
    0xFF1E88E5, // Blue
    0xFF43A047, // Green
    0xFF8E24AA, // Purple
    0xFFFF8F00, // Amber
    0xFFE53935, // Red
    0xFF00897B, // Teal
    0xFF3949AB, // Indigo
    0xFFD81B60, // Pink
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialPerson?.name ?? '');
    _phoneController = TextEditingController(text: widget.initialPerson?.phoneNumber ?? '');
    _selectedColor = widget.initialPerson?.colorValue ?? _colorPalette[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    final isEditing = widget.initialPerson != null;
    final person = PersonModel(
      id: widget.initialPerson?.id ?? 'person_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      colorValue: _selectedColor,
      isCurrentUser: widget.initialPerson?.isCurrentUser ?? false,
      createdAt: widget.initialPerson?.createdAt ?? DateTime.now(),
    );

    if (isEditing) {
      widget.viewModel.updatePerson(person);
    } else {
      widget.viewModel.addPerson(person);
    }

    Navigator.of(context).pop(person);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.initialPerson != null;

    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(_selectedColor).withValues(alpha: 0.15),
              border: Border.all(color: Color(_selectedColor).withValues(alpha: 0.3)),
            ),
            child: Icon(
              isEditing ? Icons.edit_rounded : Icons.person_add_alt_1_rounded,
              color: Color(_selectedColor),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isEditing ? 'Edit Friend' : 'Add New Friend',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Friend Avatar Preview
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    color: Color(_selectedColor),
                    child: Center(
                      child: Text(
                        _nameController.text.trim().isNotEmpty
                            ? (_nameController.text.trim().length >= 2
                                ? _nameController.text.trim().substring(0, 2).toUpperCase()
                                : _nameController.text.trim().substring(0, 1).toUpperCase())
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameController.text.trim().isNotEmpty
                              ? _nameController.text.trim()
                              : 'Friend Name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(_selectedColor),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _phoneController.text.trim().isNotEmpty
                              ? _phoneController.text.trim()
                              : '1-on-1 Split Partner',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. John Doe',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                ),
                prefixIcon: Icon(Icons.person_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone or UPI ID (Optional)',
                hintText: 'e.g. +91 98765 43210',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                ),
                prefixIcon: Icon(Icons.phone_android_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose Avatar Color',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorPalette.map((colorVal) {
                final isSelected = _selectedColor == colorVal;
                return InkWell(
                  onTap: () => setState(() => _selectedColor = colorVal),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(colorVal),
                      border: isSelected
                          ? Border.all(color: isDark ? Colors.white : Colors.black87, width: 3)
                          : Border.all(
                              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                              width: 1,
                            ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        if (isEditing && !widget.initialPerson!.isCurrentUser)
          TextButton.icon(
            onPressed: () async {
              final nav = Navigator.of(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  title: const Text('Delete Friend?'),
                  content: Text('Remove ${widget.initialPerson!.name}? Their balance will be deleted.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                await widget.viewModel.deletePerson(widget.initialPerson!.id);
                nav.pop();
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Delete'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check_rounded, size: 18),
          label: Text(isEditing ? 'Save' : 'Add Friend'),
        ),
      ],
    );
  }
}

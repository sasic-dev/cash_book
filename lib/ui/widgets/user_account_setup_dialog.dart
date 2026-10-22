import 'package:flutter/material.dart';
import '../../config/app_constants.dart';
import '../view_models/cash_book_view_model.dart';
import '../view_models/settings_view_model.dart';

/// Interactive modal dialog for setting up and managing the user's personal
/// account profile (Name, Phone number, UPI ID, and Avatar Theme Color).
class UserAccountSetupDialog extends StatefulWidget {
  final CashBookViewModel cashBookViewModel;
  final SettingsViewModel? settingsViewModel;
  final bool isFirstRun;

  const UserAccountSetupDialog({
    super.key,
    required this.cashBookViewModel,
    this.settingsViewModel,
    this.isFirstRun = false,
  });

  /// Displays the User Account Setup dialog.
  /// Returns `true` if profile changes were saved.
  static Future<bool> show(
    BuildContext context, {
    required CashBookViewModel cashBookViewModel,
    SettingsViewModel? settingsViewModel,
    bool isFirstRun = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: !isFirstRun,
      builder: (_) => UserAccountSetupDialog(
        cashBookViewModel: cashBookViewModel,
        settingsViewModel: settingsViewModel,
        isFirstRun: isFirstRun,
      ),
    );
    return result ?? false;
  }

  @override
  State<UserAccountSetupDialog> createState() => _UserAccountSetupDialogState();
}

class _UserAccountSetupDialogState extends State<UserAccountSetupDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _upiController;
  late int _selectedColor;

  final List<int> _colorPalette = AppConstants.personColorPalette;

  @override
  void initState() {
    super.initState();
    final currentUser = widget.cashBookViewModel.currentUser;
    final currentSettings = widget.settingsViewModel?.settings;

    // Use current settings name if personalized, otherwise current user person name
    final existingName = (currentSettings != null &&
            currentSettings.hasCompletedAccountSetup &&
            currentSettings.userName.isNotEmpty)
        ? currentSettings.userName
        : (currentUser.name == AppConstants.defaultCurrentUserName ? '' : currentUser.name);

    final existingPhone = currentSettings?.userPhone ?? currentUser.phoneNumber ?? '';
    final existingUpi = currentSettings?.userUpiId ?? currentUser.upiId ?? '';

    _nameController = TextEditingController(text: existingName);
    _phoneController = TextEditingController(text: existingPhone);
    _upiController = TextEditingController(text: existingUpi);
    _selectedColor = currentUser.colorValue;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  String _calculateInitials(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'ME';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final trimmedName = _nameController.text.trim();
    final nameToSave = trimmedName.isNotEmpty ? trimmedName : AppConstants.defaultCurrentUserName;
    final phoneToSave = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
    final upiToSave = _upiController.text.trim().isEmpty ? null : _upiController.text.trim();

    // 1. Update SQLite PersonModel for current user
    final currentUser = widget.cashBookViewModel.currentUser;
    final updatedPerson = currentUser.copyWith(
      name: nameToSave,
      phoneNumber: phoneToSave,
      upiId: upiToSave,
      colorValue: _selectedColor,
      isCurrentUser: true,
    );

    await widget.cashBookViewModel.updatePerson(updatedPerson);

    // 2. Update Settings preferences
    if (widget.settingsViewModel != null) {
      await widget.settingsViewModel!.updateAccountProfile(
        name: nameToSave,
        phone: phoneToSave,
        upiId: upiToSave,
        completed: true,
      );
    }

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account profile saved: $nameToSave'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.teal.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Title with Icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(
                        Icons.manage_accounts_rounded,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isFirstRun ? 'Welcome! Set Up Profile' : 'User Account Setup',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Personalize your name & payment details',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!widget.isFirstRun)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // Live Avatar Preview Card
                Center(
                  child: AnimatedBuilder(
                    animation: _nameController,
                    builder: (context, _) {
                      final initials = _calculateInitials(_nameController.text);
                      return Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Color(_selectedColor),
                              border: Border.all(
                                color: isDark ? Colors.white24 : Colors.black12,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(_selectedColor).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                            child: const Text(
                              'Primary Account (You)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 22),

                // Name Input
                TextFormField(
                  controller: _nameController,
                  autofocus: widget.isFirstRun,
                  decoration: const InputDecoration(
                    labelText: 'Your Full Name *',
                    hintText: 'e.g. Sasi Kumar',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    helperText: 'Shown on split bills, receipts, and reports',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Phone Number Input
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number (Optional)',
                    hintText: 'e.g. 9876543210',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // UPI ID Input
                TextFormField(
                  controller: _upiController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'UPI ID / Payment Handle (Optional)',
                    hintText: 'e.g. yourname@okhdfcbank, 9876543210@upi',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    helperText: 'Enables friends to pay or settle debts with 1 tap',
                  ),
                ),

                const SizedBox(height: 20),

                // Avatar Color Palette
                Text(
                  'Profile Color Theme',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colorPalette.map((colorVal) {
                    final isSelected = _selectedColor == colorVal;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedColor = colorVal;
                        });
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        color: Color(colorVal),
                        child: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 26),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(widget.isFirstRun ? 'Skip for now' : 'Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        widget.isFirstRun ? 'Complete Setup' : 'Save Changes',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

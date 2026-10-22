import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_constants.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/person_model.dart';
import '../utils/formatters.dart';
import '../view_models/settings_view_model.dart';
import '../view_models/cash_book_view_model.dart';
import '../widgets/user_account_setup_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsViewModel settingsViewModel;
  final CashBookViewModel? cashBookViewModel;

  const SettingsScreen({
    super.key,
    required this.settingsViewModel,
    this.cashBookViewModel,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _calcAmountController;
  String _calcFromCurrency = AppConstants.defaultCurrencyCode;

  @override
  void initState() {
    super.initState();
    _calcAmountController = TextEditingController(text: AppConstants.defaultCalculatorAmount);
  }

  @override
  void dispose() {
    _calcAmountController.dispose();
    super.dispose();
  }

  void _handleCurrencyTap(CurrencyOption cur, AppSettings settings) {
    if (settings.currencyCode == cur.code && settings.currencySymbol == cur.symbol) {
      return;
    }

    widget.settingsViewModel.setCurrency(
      code: cur.code,
      symbol: cur.symbol,
      symbolBeforeAmount: settings.symbolBeforeAmount,
      decimalDigits: cur.defaultDecimals,
      useIndianGrouping: cur.defaultIndianGrouping,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(cur.code == 'INR'
            ? 'Display currency set to INR (₹) - base values active'
            : 'Display currency set to ${cur.name} (${cur.symbol}) - display conversion active'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openCustomRatesDialog(AppSettings current) {
    final usdController = TextEditingController(
      text: (current.customExchangeRates['USD'] ?? AppConstants.defaultUsdRate).toStringAsFixed(2),
    );
    final eurController = TextEditingController(
      text: (current.customExchangeRates['EUR'] ?? AppConstants.defaultEurRate).toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.tune_rounded),
              SizedBox(width: 8),
              Text('Exchange Rates (to INR)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set exchange rate relative to Indian Rupee (INR is default base = ₹1.00):',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: usdController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '1 USD value in INR (₹)',
                    hintText: '${AppConstants.defaultUsdRate}',
                    prefixText: '₹ ',
                  ),
                  validator: (val) {
                    final d = double.tryParse(val ?? '');
                    if (d == null || d <= 0) return 'Enter a valid positive rate';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: eurController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '1 EUR value in INR (₹)',
                    hintText: '${AppConstants.defaultEurRate}',
                    prefixText: '₹ ',
                  ),
                  validator: (val) {
                    final d = double.tryParse(val ?? '');
                    if (d == null || d <= 0) return 'Enter a valid positive rate';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                widget.settingsViewModel.setExchangeRates(CurrencyConversionHelper.defaultRatesToInr);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Exchange rates reset to default market rates'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Reset Defaults'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final usdRate = double.parse(usdController.text.trim());
                  final eurRate = double.parse(eurController.text.trim());
                  widget.settingsViewModel.setExchangeRates({
                    'INR': 1.0,
                    'USD': usdRate,
                    'EUR': eurRate,
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Custom exchange rates saved'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Save Rates'),
            ),
          ],
        );
      },
    );
  }



  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Settings?'),
        content: const Text(
          'This will reset theme color, font, font size scale, currency, and date/time format to their original defaults.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              widget.settingsViewModel.resetToDefaults();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settingsViewModel,
      builder: (context, _) {
        final settings = widget.settingsViewModel.settings;
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.restart_alt_rounded),
                tooltip: 'Reset to Defaults',
                onPressed: _confirmReset,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // 0. Account & Profile Section
              _buildAccountProfileSection(theme, settings),
              const SizedBox(height: 24),

              // 1. Theme & Colors Section
              _buildSectionHeader(
                icon: Icons.palette_outlined,
                title: 'Theme & Colors',
                subtitle: 'Personalize theme mode and accent color palette',
              ),
              const SizedBox(height: 12),
              _buildThemeModeSelector(theme, settings),
              const SizedBox(height: 16),
              _buildColorPaletteGrid(theme, settings),
              const SizedBox(height: 24),

              // 2. Fonts Section
              _buildSectionHeader(
                icon: Icons.text_fields_rounded,
                title: 'Typography & Fonts',
                subtitle: 'Choose your preferred typeface for headings and figures',
              ),
              const SizedBox(height: 12),
              _buildFontPicker(theme, settings),
              const SizedBox(height: 24),

              // 3. Font Size & Scale Section
              _buildSectionHeader(
                icon: Icons.format_size_rounded,
                title: 'Font Size & Scale',
                subtitle: 'Adjust text size across all screens (${(settings.fontScale * 100).round()}%)',
              ),
              const SizedBox(height: 12),
              _buildFontSizeControls(theme, settings),
              const SizedBox(height: 24),

              // 4. Currency Section
              _buildSectionHeader(
                icon: Icons.currency_exchange_rounded,
                title: 'Currency & Number Format',
                subtitle: 'Select currency symbol, position, and digit formatting',
              ),
              const SizedBox(height: 12),
              _buildCurrencyControls(theme, settings),
              const SizedBox(height: 24),

              // 5. Date & Time Format Section
              _buildSectionHeader(
                icon: Icons.calendar_month_outlined,
                title: 'Date & Time Format',
                subtitle: 'Customize how transaction dates and timestamps appear',
              ),
              const SizedBox(height: 12),
              _buildDateTimeControls(theme, settings),
              const SizedBox(height: 24),

              // 6. Reset & Info Section
              _buildFooterSection(theme),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  // --- Header Builder ---
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, size: 20, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  // --- 0. Account & Profile Section ---
  Widget _buildAccountProfileSection(ThemeData theme, AppSettings settings) {
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = widget.cashBookViewModel?.currentUser ??
        PersonModel(
          id: AppConstants.defaultCurrentUserId,
          name: settings.userName,
          phoneNumber: settings.userPhone,
          upiId: settings.userUpiId,
          colorValue: AppConstants.defaultCurrentUserColor,
          isCurrentUser: true,
          createdAt: DateTime.now(),
        );

    final isDefaultUser = currentUser.name == AppConstants.defaultCurrentUserName &&
        !settings.hasCompletedAccountSetup;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.account_circle_outlined,
          title: 'Account & Profile',
          subtitle: 'Manage your primary ledger name, mobile & UPI handle',
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1.5,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(
              color: Color(0xFFCBD5E1),
              width: 1,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  color: currentUser.color,
                  alignment: Alignment.center,
                  child: Text(
                    currentUser.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              currentUser.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isDefaultUser
                                  ? (isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7))
                                  : (isDark ? const Color(0xFF134E4A) : const Color(0xFFCCFBF1)),
                              border: Border.all(
                                color: isDefaultUser
                                    ? (isDark ? const Color(0xFFB45309) : const Color(0xFFFCD34D))
                                    : (isDark ? const Color(0xFF0F766E) : const Color(0xFF5EEAD4)),
                              ),
                            ),
                            child: Text(
                              isDefaultUser ? 'Not Set Up' : 'Primary Account',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDefaultUser
                                    ? (isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E))
                                    : (isDark ? const Color(0xFF99F6E4) : const Color(0xFF115E59)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentUser.phoneNumber?.isNotEmpty == true
                            ? currentUser.phoneNumber!
                            : (currentUser.upiId?.isNotEmpty == true
                                ? 'UPI: ${currentUser.upiId!}'
                                : 'Tap to personalize profile & payment handle'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      if (currentUser.upiId != null && currentUser.phoneNumber?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          'UPI: ${currentUser.upiId}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: () {
                    if (widget.cashBookViewModel != null) {
                      UserAccountSetupDialog.show(
                        context,
                        cashBookViewModel: widget.cashBookViewModel!,
                        settingsViewModel: widget.settingsViewModel,
                      );
                    }
                  },
                  child: Text(
                    isDefaultUser ? 'Set Up' : 'Edit',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 1. Theme Mode Selector ---
  Widget _buildThemeModeSelector(ThemeData theme, AppSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: _buildThemeModeTile(
                icon: Icons.light_mode_outlined,
                selectedIcon: Icons.light_mode_rounded,
                label: 'Light',
                isSelected: settings.themeMode == ThemeMode.light,
                onTap: () => widget.settingsViewModel.setThemeMode(ThemeMode.light),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildThemeModeTile(
                icon: Icons.dark_mode_outlined,
                selectedIcon: Icons.dark_mode_rounded,
                label: 'Dark',
                isSelected: settings.themeMode == ThemeMode.dark,
                onTap: () => widget.settingsViewModel.setThemeMode(ThemeMode.dark),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildThemeModeTile(
                icon: Icons.brightness_auto_outlined,
                selectedIcon: Icons.brightness_auto_rounded,
                label: 'System',
                isSelected: settings.themeMode == ThemeMode.system,
                onTap: () => widget.settingsViewModel.setThemeMode(ThemeMode.system),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeModeTile({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                size: 20,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. Color Palette Grid ---
  Widget _buildColorPaletteGrid(ThemeData theme, AppSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accent Color',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              itemCount: AppSettings.colorPresets.length,
              itemBuilder: (context, index) {
                final preset = AppSettings.colorPresets[index];
                final isSelected = settings.primaryColorValue == preset.primaryColor.toARGB32();

                return InkWell(
                  onTap: () => widget.settingsViewModel.setPrimaryColor(
                    preset.primaryColor.toARGB32(),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? preset.primaryColor : theme.dividerColor,
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? preset.primaryColor.withValues(alpha: 0.08)
                          : Colors.transparent,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: preset.primaryColor,
                              border: Border.all(color: Colors.white, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: preset.primaryColor.withValues(alpha: 0.35),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 20, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            preset.name.split(' ').first,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? preset.primaryColor : theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getFontSubtitle(String font) {
    switch (font.toLowerCase().trim()) {
      case 'inter':
        return 'Modern UI • Default';
      case 'roboto':
        return 'Google Standard';
      case 'poppins':
        return 'Rounded Geometric';
      case 'system':
        return 'Device Native';
      default:
        return 'Typography';
    }
  }

  // --- 2. Fonts Picker (4 Necessary Fonts) ---
  Widget _buildFontPicker(ThemeData theme, AppSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Font Family',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '4 Selected Fonts',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.1,
              ),
              itemCount: AppSettings.fontPresets.length,
              itemBuilder: (context, index) {
                final font = AppSettings.fontPresets[index];
                final isSelected = settings.fontFamily.toLowerCase() == font.toLowerCase();

                return InkWell(
                  onTap: () => widget.settingsViewModel.setFontFamily(font),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  font,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  _getFontSubtitle(font),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. Font Size & Scale Controls ---
  Widget _buildFontSizeControls(ThemeData theme, AppSettings settings) {
    final scalePercent = (settings.fontScale * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Text Scaling',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '$scalePercent%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Quick preset chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildScaleChip('Small (85%)', 0.85, settings.fontScale),
                _buildScaleChip('Normal (100%)', 1.00, settings.fontScale),
                _buildScaleChip('Medium (115%)', 1.15, settings.fontScale),
                _buildScaleChip('Large (130%)', 1.30, settings.fontScale),
              ],
            ),
            const SizedBox(height: 14),
            // Interactive Slider
            Row(
              children: [
                const Text('A', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Slider(
                    value: settings.fontScale,
                    min: 0.80,
                    max: 1.45,
                    divisions: 13, // 0.05 increments
                    label: '$scalePercent%',
                    onChanged: (newScale) {
                      widget.settingsViewModel.setFontScale(newScale);
                    },
                  ),
                ),
                const Text('A', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScaleChip(String label, double scale, double currentScale) {
    final theme = Theme.of(context);
    final isSelected = (currentScale - scale).abs() < 0.02;

    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.15)
          : Colors.transparent,
      side: BorderSide(
        color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
        width: isSelected ? 1.5 : 1.0,
      ),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
      ),
      onPressed: () => widget.settingsViewModel.setFontScale(scale),
    );
  }

  Widget _buildRateBadge(ThemeData theme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildConvertedItem(
    ThemeData theme, {
    required String label,
    required String amountStr,
    required bool isSource,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isSource
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSource ? theme.colorScheme.primary : theme.dividerColor,
            width: isSource ? 1.5 : 1.0,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: isSource ? FontWeight.bold : FontWeight.w500,
                  color: isSource ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                amountStr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSource ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConverterResults(ThemeData theme, AppSettings settings) {
    final enteredAmount = double.tryParse(_calcAmountController.text.trim()) ?? 0.0;
    final inrVal = CurrencyConversionHelper.convert(
      enteredAmount,
      fromCode: _calcFromCurrency,
      toCode: 'INR',
      ratesToInr: settings.customExchangeRates,
    );
    final usdVal = CurrencyConversionHelper.convert(
      enteredAmount,
      fromCode: _calcFromCurrency,
      toCode: 'USD',
      ratesToInr: settings.customExchangeRates,
    );
    final eurVal = CurrencyConversionHelper.convert(
      enteredAmount,
      fromCode: _calcFromCurrency,
      toCode: 'EUR',
      ratesToInr: settings.customExchangeRates,
    );

    return Row(
      children: [
        _buildConvertedItem(
          theme,
          label: 'INR (₹)',
          amountStr: '₹${inrVal.toStringAsFixed(2)}',
          isSource: _calcFromCurrency == 'INR',
        ),
        const SizedBox(width: 6),
        _buildConvertedItem(
          theme,
          label: 'USD (\$)',
          amountStr: '\$${usdVal.toStringAsFixed(2)}',
          isSource: _calcFromCurrency == 'USD',
        ),
        const SizedBox(width: 6),
        _buildConvertedItem(
          theme,
          label: 'EUR (€)',
          amountStr: '€${eurVal.toStringAsFixed(2)}',
          isSource: _calcFromCurrency == 'EUR',
        ),
      ],
    );
  }

  // --- 4. Currency Controls (3 Formats with Conversion, INR Default) ---
  Widget _buildCurrencyControls(ThemeData theme, AppSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Currency',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'INR is Default',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Currency options grid - 3 currencies with conversion
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.10,
              ),
              itemCount: AppSettings.presetCurrencies.length,
              itemBuilder: (context, index) {
                final cur = AppSettings.presetCurrencies[index];
                final isSelected = settings.currencyCode == cur.code &&
                    settings.currencySymbol == cur.symbol;

                String rateDesc;
                if (cur.code == 'INR') {
                  rateDesc = 'Base (Default)';
                } else {
                  final rate = settings.customExchangeRates[cur.code] ?? cur.rateToInr;
                  rateDesc = '1 ${cur.code} = ₹${rate.toStringAsFixed(1)}';
                }

                return InkWell(
                  onTap: () => _handleCurrencyTap(cur, settings),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${cur.symbol} ${cur.code}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cur.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              rateDesc,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // Currency Converter Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.currency_exchange_rounded, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Currency Converter (INR Base)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _openCustomRatesDialog(settings),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined, size: 12, color: theme.colorScheme.primary),
                              const SizedBox(width: 3),
                              Text(
                                'Rates',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildRateBadge(theme, 'Base: ₹1.00 INR'),
                      _buildRateBadge(
                        theme,
                        '1 USD = ₹${(settings.customExchangeRates['USD'] ?? 86.50).toStringAsFixed(2)}',
                      ),
                      _buildRateBadge(
                        theme,
                        '1 EUR = ₹${(settings.customExchangeRates['EUR'] ?? 94.00).toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _calcAmountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Amount',
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: _calcFromCurrency,
                          isDense: true,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'From',
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'INR', child: Text('₹ INR')),
                            DropdownMenuItem(value: 'USD', child: Text('\$ USD')),
                            DropdownMenuItem(value: 'EUR', child: Text('€ EUR')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _calcFromCurrency = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildConverterResults(theme, settings),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Display-Only Conversion: Ledger records remain safely stored in base INR (₹). Display amounts convert dynamically without data mutation.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),

            // Placement: Prefix vs Suffix
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Symbol Position',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        settings.symbolBeforeAmount
                            ? 'Prefix: ${settings.currencySymbol} 100'
                            : 'Suffix: 100 ${settings.currencySymbol}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Prefix')),
                    ButtonSegment(value: false, label: Text('Suffix')),
                  ],
                  selected: {settings.symbolBeforeAmount},
                  onSelectionChanged: (selection) {
                    widget.settingsViewModel.setCurrency(
                      code: settings.currencyCode,
                      symbol: settings.currencySymbol,
                      symbolBeforeAmount: selection.first,
                      decimalDigits: settings.decimalDigits,
                      useIndianGrouping: settings.useIndianGrouping,
                    );
                  },
                ),
              ],
            ),
            const Divider(height: 20),

            // Decimals: 2 Decimals vs 0
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Decimal Digits',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        settings.decimalDigits == 2 ? 'Includes cents (.00)' : 'Whole numbers only',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 2, label: Text('.00')),
                    ButtonSegment(value: 0, label: Text('0')),
                  ],
                  selected: {settings.decimalDigits},
                  onSelectionChanged: (selection) {
                    widget.settingsViewModel.setCurrency(
                      code: settings.currencyCode,
                      symbol: settings.currencySymbol,
                      symbolBeforeAmount: settings.symbolBeforeAmount,
                      decimalDigits: selection.first,
                      useIndianGrouping: settings.useIndianGrouping,
                    );
                  },
                ),
              ],
            ),
            const Divider(height: 20),

            // Number grouping: Indian vs International
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Indian Lakh/Crore Format',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                settings.useIndianGrouping ? 'Example: 1,00,000.00' : 'Example: 100,000.00',
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
              ),
              value: settings.useIndianGrouping,
              onChanged: (val) {
                widget.settingsViewModel.setCurrency(
                  code: settings.currencyCode,
                  symbol: settings.currencySymbol,
                  symbolBeforeAmount: settings.symbolBeforeAmount,
                  decimalDigits: settings.decimalDigits,
                  useIndianGrouping: val,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- 5. Date & Time Format Controls (4 Formats Each) ---
  Widget _buildDateTimeControls(ThemeData theme, AppSettings settings) {
    final now = DateTime.now();
    final String currentPattern = settings.dateFormatPattern;
    final String currentTimePattern = settings.timeFormatPattern;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current formatted preview
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_available_rounded, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Display Preview',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${AppFormatters.date(now)} • ${AppFormatters.time(now)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date Format',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '4 Formats',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date Format Presets Grid - exactly 4 formats
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.0,
              ),
              itemCount: AppSettings.dateFormatPresets.length,
              itemBuilder: (context, index) {
                final preset = AppSettings.dateFormatPresets[index];
                final isSelected = currentPattern == preset.pattern;
                String formattedSample;
                try {
                  formattedSample = DateFormat(preset.pattern).format(now);
                } catch (_) {
                  formattedSample = preset.pattern;
                }

                return InkWell(
                  onTap: () => widget.settingsViewModel.setDateFormat(preset.pattern),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  formattedSample,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  preset.pattern,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 24),

            // Time Format (4 Presets)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Time Format',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '4 Formats',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Time Format Presets Grid - exactly 4 formats
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.95,
              ),
              itemCount: AppSettings.timeFormatPresets.length,
              itemBuilder: (context, index) {
                final preset = AppSettings.timeFormatPresets[index];
                final isSelected = currentTimePattern == preset.pattern;
                String formattedSample;
                try {
                  formattedSample = DateFormat(preset.pattern).format(now);
                } catch (_) {
                  formattedSample = preset.pattern;
                }

                return InkWell(
                  onTap: () => widget.settingsViewModel.setTimeFormatPattern(preset.pattern),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  formattedSample,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                            : theme.colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        preset.label,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      preset.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- 6. Footer Section ---
  Widget _buildFooterSection(ThemeData theme) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.refresh_rounded),
            title: const Text('Reset All Settings to Defaults'),
            subtitle: const Text('Restores Sapphire theme, Inter font, 100% scale, INR, and default date format'),
            onTap: _confirmReset,
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Cash Book v1.0.0 • Expense & Ledger Manager',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

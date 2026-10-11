import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/app_settings.dart';
import '../utils/formatters.dart';
import '../view_models/settings_view_model.dart';
import '../view_models/cash_book_view_model.dart';

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
  // Custom currency dialog controller
  void _openCustomCurrencyDialog(AppSettings current) {
    final codeController = TextEditingController(text: current.currencyCode);
    final symbolController = TextEditingController(text: current.currencySymbol);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit_outlined),
              SizedBox(width: 8),
              Text('Custom Currency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Currency Code (e.g. CAD, BRL, BTC)',
                    hintText: 'e.g. BTC',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Enter a currency code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: symbolController,
                  decoration: const InputDecoration(
                    labelText: 'Currency Symbol (e.g. ₿, R\$, ₺)',
                    hintText: 'e.g. ₿',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Enter a currency symbol';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final code = codeController.text.trim().toUpperCase();
                  final symbol = symbolController.text.trim();
                  widget.settingsViewModel.setCurrency(
                    code: code,
                    symbol: symbol,
                    symbolBeforeAmount: current.symbolBeforeAmount,
                    decimalDigits: current.decimalDigits,
                    useIndianGrouping: false,
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save'),
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
                childAspectRatio: 0.95,
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
                    child: Column(
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. Fonts Picker ---
  Widget _buildFontPicker(ThemeData theme, AppSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Font Family',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.3,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
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
                                'Sample 123',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
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

  // --- 4. Currency Controls ---
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
                TextButton.icon(
                  onPressed: () => _openCustomCurrencyDialog(settings),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Custom', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Currency options grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.8,
              ),
              itemCount: AppSettings.presetCurrencies.length,
              itemBuilder: (context, index) {
                final cur = AppSettings.presetCurrencies[index];
                final isSelected = settings.currencyCode == cur.code &&
                    settings.currencySymbol == cur.symbol;

                return InkWell(
                  onTap: () {
                    widget.settingsViewModel.setCurrency(
                      code: cur.code,
                      symbol: cur.symbol,
                      symbolBeforeAmount: settings.symbolBeforeAmount,
                      decimalDigits: cur.defaultDecimals,
                      useIndianGrouping: cur.defaultIndianGrouping,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
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
                        Text(
                          cur.name,
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
                );
              },
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

  // --- 5. Date & Time Format Controls ---
  Widget _buildDateTimeControls(ThemeData theme, AppSettings settings) {
    final now = DateTime.now();
    final bool is24Hour = settings.is24HourTime;
    final String currentPattern = settings.dateFormatPattern;

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

            Text(
              'Date Format',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Date Format Presets Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.2,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
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

            // Time Format (12h vs 24h)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Time Format',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        is24Hour
                            ? '24-Hour (e.g. ${DateFormat('HH:mm').format(now)})'
                            : '12-Hour (e.g. ${DateFormat('hh:mm a').format(now)})',
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
                    ButtonSegment(value: false, label: Text('12h')),
                    ButtonSegment(value: true, label: Text('24h')),
                  ],
                  selected: {is24Hour},
                  onSelectionChanged: (selection) {
                    widget.settingsViewModel.setTimeFormat(selection.first);
                  },
                ),
              ],
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

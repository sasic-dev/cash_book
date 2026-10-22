import 'package:flutter/material.dart';
import 'config/app_constants.dart';
import 'data/services/cash_book_database_service.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/utils/app_theme.dart';
import 'ui/view_models/cash_book_view_model.dart';
import 'ui/view_models/settings_view_model.dart';
import 'ui/widgets/settings_scope.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  CashBookDatabaseService.ensurePlatformInitialized();
  final viewModel = CashBookViewModel();
  final settingsViewModel = SettingsViewModel();
  await Future.wait([
    viewModel.init(),
    settingsViewModel.init(),
  ]);
  runApp(CashBookApp(
    viewModel: viewModel,
    settingsViewModel: settingsViewModel,
  ));
}

class CashBookApp extends StatefulWidget {
  final CashBookViewModel? viewModel;
  final SettingsViewModel? settingsViewModel;
  final bool showSplash;
  final Duration splashDuration;

  const CashBookApp({
    super.key,
    this.viewModel,
    this.settingsViewModel,
    this.showSplash = false,
    this.splashDuration = AppConstants.defaultSplashDuration,
  });

  @override
  State<CashBookApp> createState() => _CashBookAppState();
}

class _CashBookAppState extends State<CashBookApp> {
  late final SettingsViewModel _settingsViewModel;

  @override
  void initState() {
    super.initState();
    _settingsViewModel = widget.settingsViewModel ?? SettingsViewModel();
    if (widget.settingsViewModel == null) {
      _settingsViewModel.init();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settingsViewModel,
      builder: (context, _) {
        final settings = _settingsViewModel.settings;

        return SettingsScope(
          notifier: _settingsViewModel,
          child: MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.buildLightTheme(
              primaryColor: settings.primaryColor,
              fontFamily: settings.fontFamily,
            ),
            darkTheme: AppTheme.buildDarkTheme(
              primaryColor: settings.primaryColor,
              fontFamily: settings.fontFamily,
            ),
            themeMode: settings.themeMode,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(settings.fontScale),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: widget.showSplash
                ? SplashScreen(
                    injectedViewModel: widget.viewModel,
                    duration: widget.splashDuration,
                  )
                : _HomeWrapper(
                    injectedViewModel: widget.viewModel,
                    injectedSettingsViewModel: _settingsViewModel,
                  ),
          ),
        );
      },
    );
  }
}

class _HomeWrapper extends StatefulWidget {
  final CashBookViewModel? injectedViewModel;
  final SettingsViewModel? injectedSettingsViewModel;

  const _HomeWrapper({
    this.injectedViewModel,
    this.injectedSettingsViewModel,
  });

  @override
  State<_HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<_HomeWrapper> {
  late final CashBookViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.injectedViewModel ?? CashBookViewModel();
    if (widget.injectedViewModel == null) {
      _viewModel.init();
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      viewModel: _viewModel,
      settingsViewModel: widget.injectedSettingsViewModel,
    );
  }
}
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizzle_starter/src/feature/initialization/model/dependencies.dart';
import 'package:sizzle_starter/src/feature/initialization/model/initialization_progress.dart';
import 'package:sizzle_starter/src/feature/settings/bloc/settings_bloc.dart';
import 'package:sizzle_starter/src/feature/settings/data/locale_datasource.dart';
import 'package:sizzle_starter/src/feature/settings/data/settings_repository.dart';
import 'package:sizzle_starter/src/feature/settings/data/theme_datasource.dart';
import 'package:sizzle_starter/src/feature/settings/data/theme_mode_codec.dart';

/// A function which represents a single initialization step.
typedef StepAction = FutureOr<void>? Function(InitializationProgress progress);

/// The initialization steps, which are executed in the order they are defined.
///
/// The [Dependencies] object is passed to each step, which allows the step to
/// set the dependency, and the next step to use it.
mixin InitializationSteps {
  /// The initialization steps,
  /// which are executed in the order they are defined.
  final initializationSteps = <String, StepAction>{
    'Shared Preferences': (progress) async {
      final sharedPreferences = await SharedPreferences.getInstance();
      progress.dependencies.sharedPreferences = sharedPreferences;
    },
    'Settings Repository': (progress) {
      final sharedPreferences = progress.dependencies.sharedPreferences;
      final themeDataSource = ThemeDataSourceLocal(
        sharedPreferences: sharedPreferences,
        codec: const ThemeModeCodec(),
      );
      final localeDataSource = LocaleDataSourceLocal(
        sharedPreferences: sharedPreferences,
      );
      progress.dependencies.settingsRepository = SettingsRepositoryImpl(
        themeDataSource: themeDataSource,
        localeDataSource: localeDataSource,
      );
    },
    'SettingsBloc': (progress) async {
      final repository = progress.dependencies.settingsRepository;

      final localeFuture = repository.getLocale();
      final theme = await repository.getTheme();
      final locale = await localeFuture;

      final initialState = SettingsState.idle(
        appTheme: theme,
        locale: locale,
      );

      progress.dependencies.settingsBloc = SettingsBloc(
        initialState: initialState,
        settingsRepository: repository,
      );
    },
  };
}

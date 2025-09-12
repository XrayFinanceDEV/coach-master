import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:coachmaster/l10n/app_localizations.dart';

import 'package:coachmaster/core/router.dart';
import 'package:coachmaster/core/theme.dart';
import 'package:coachmaster/core/locale_provider.dart';
import 'package:coachmaster/models/season.dart';
import 'package:coachmaster/models/team.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/training.dart';
import 'package:coachmaster/models/training_attendance.dart';
import 'package:coachmaster/models/match.dart';
import 'package:coachmaster/models/match_convocation.dart';
import 'package:coachmaster/models/match_statistic.dart';
import 'package:coachmaster/models/onboarding_settings.dart';
import 'package:coachmaster/models/user.dart';
import 'package:coachmaster/models/note.dart';
import 'package:coachmaster/core/app_initialization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive with proper persistent storage directory
  if (kIsWeb) {
    await Hive.initFlutter('coachmaster_db');
  } else {
    final directory = await getApplicationDocumentsDirectory();
    Hive.init('${directory.path}/coachmaster_db');
  }
  
  print('=== HIVE INITIALIZATION DEBUG ===');
  print('Platform: ${kIsWeb ? "Web" : "Native"}');
  if (!kIsWeb) {
    final directory = await getApplicationDocumentsDirectory();
    print('Hive directory: ${directory.path}/coachmaster_db');
  } else {
    print('Hive initialized with subdir: coachmaster_db');
  }
  
  // Register all Hive adapters - check if already registered to prevent conflicts
  _registerAdapterSafely(() => Hive.registerAdapter(SeasonAdapter()));
  _registerAdapterSafely(() => Hive.registerAdapter(TeamAdapter()));
  _registerAdapterSafely(() => Hive.registerAdapter(PlayerAdapter()));
  _registerAdapterSafely(() => Hive.registerAdapter(TrainingAdapter()));
  _registerAdapterSafely(() => Hive.registerAdapter(TimeOfDayAdapter()));
  _registerAdapterSafely(() => Hive.registerAdapter(TrainingAttendanceAdapter()));
  _registerAdapterSafely(() => Hive.registerAdapter(TrainingAttendanceStatusAdapter()));
  _registerAdapterSafely(() => Hive.registerAdapter(MatchAdapter()));
  _registerAdapterSafely(() => Hive.registerAdapter(MatchStatusAdapter()));
  _registerAdapterSafely(() => Hive.registerAdapter(MatchResultAdapter()));
  _registerAdapterSafely(() => Hive.registerAdapter(MatchConvocationAdapter()));
  _registerAdapterSafely(() => Hive.registerAdapter(PlayerMatchStatusAdapter()));
  _registerAdapterSafely(() => Hive.registerAdapter(MatchStatisticAdapter()));
  _registerAdapterSafely(() => Hive.registerAdapter(OnboardingSettingsAdapter()));
  _registerAdapterSafely(() => Hive.registerAdapter(UserAdapter()));
  _registerAdapterSafely(() => Hive.registerAdapter(NoteTypeAdapter()));
  _registerAdapterSafely(() => Hive.registerAdapter(NoteAdapter()));

  runApp(const ProviderScope(child: CoachMasterApp()));
}

void _registerAdapterSafely(Function registerFunction) {
  try {
    registerFunction();
  } catch (e) {
    // Adapter already registered, ignore
  }
}

class CoachMasterApp extends ConsumerWidget {
  const CoachMasterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appReady = ref.watch(appReadyProvider);
    
    if (!appReady) {
      return MaterialApp(
        title: 'CoachMaster',
        theme: appTheme,
        home: const LoadingScreen(),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('it'),
        ],
      );
    }
    
    final appRouter = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    
    return MaterialApp.router(
      title: 'CoachMaster',
      theme: appTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('it'),
      ],
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_soccer,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'CoachMaster',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

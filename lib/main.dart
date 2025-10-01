import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:coachmaster/l10n/app_localizations.dart';

import 'package:coachmaster/core/router.dart';
import 'package:coachmaster/core/theme.dart';
import 'package:coachmaster/core/locale_provider.dart';
import 'package:coachmaster/core/app_initialization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configure Firestore offline persistence (single source of truth)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // Enable offline caching
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // No cache size limit
  );

  if (kDebugMode) {
    print('🔥 Firebase initialized with offline persistence');
    print('✅ Firestore is the single source of truth');
  }

  runApp(const ProviderScope(child: CoachMasterApp()));
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:coachmaster/core/router.dart';
import 'package:coachmaster/core/theme.dart';
import 'package:coachmaster/models/season.dart';
import 'package:coachmaster/models/team.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/training.dart';
import 'package:coachmaster/models/training_attendance.dart';
import 'package:coachmaster/models/match.dart';
import 'package:coachmaster/models/match_convocation.dart';
import 'package:coachmaster/models/match_statistic.dart';
import 'package:coachmaster/services/season_repository.dart';
import 'package:coachmaster/services/team_repository.dart';
import 'package:coachmaster/services/player_repository.dart';
import 'package:coachmaster/services/training_repository.dart';
import 'package:coachmaster/services/training_attendance_repository.dart';
import 'package:coachmaster/services/match_repository.dart';
import 'package:coachmaster/services/match_convocation_repository.dart';
import 'package:coachmaster/services/match_statistic_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(SeasonAdapter());
  Hive.registerAdapter(TeamAdapter());
  Hive.registerAdapter(PlayerAdapter());
  Hive.registerAdapter(TrainingAdapter());
  Hive.registerAdapter(TimeOfDayAdapter());
  Hive.registerAdapter(TrainingAttendanceAdapter());
  Hive.registerAdapter(MatchAdapter());
  Hive.registerAdapter(MatchConvocationAdapter());
  Hive.registerAdapter(MatchStatisticAdapter());

  // Initialize repositories
  await SeasonRepository().init();
  await TeamRepository().init();
  await PlayerRepository().init();
  await TrainingRepository().init();
  await TrainingAttendanceRepository().init();
  await MatchRepository().init();
  await MatchConvocationRepository().init();
  await MatchStatisticRepository().init();

  runApp(const ProviderScope(child: CoachMasterApp()));
}

class CoachMasterApp extends ConsumerWidget {
  const CoachMasterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'CoachMaster',
      theme: appTheme,
      routerConfig: appRouter,
    );
  }
}

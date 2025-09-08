// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:coachmaster/main.dart';
import 'package:coachmaster/models/season.dart';
import 'package:coachmaster/models/team.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/training.dart';
import 'package:coachmaster/models/training_attendance.dart';
import 'package:coachmaster/models/match.dart';
import 'package:coachmaster/models/match_convocation.dart';
import 'package:coachmaster/models/match_statistic.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    // Initialize Hive and register adapters
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
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CoachMasterApp());

    // Verify that our counter starts at 0.
    expect(find.byType(CoachMasterApp), findsOneWidget);
  });
}

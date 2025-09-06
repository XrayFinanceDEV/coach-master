import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/features/seasons/season_list_screen.dart';
import 'package:coachmaster/features/seasons/season_detail_screen.dart';
import 'package:coachmaster/features/teams/team_list_screen.dart';
import 'package:coachmaster/features/teams/team_detail_screen.dart';
import 'package:coachmaster/features/players/player_list_screen.dart';
import 'package:coachmaster/features/players/player_detail_screen.dart';
import 'package:coachmaster/features/trainings/training_list_screen.dart';
import 'package:coachmaster/features/trainings/training_detail_screen.dart';
import 'package:coachmaster/features/matches/match_list_screen.dart';
import 'package:coachmaster/features/matches/match_detail_screen.dart';

// Placeholder screens
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Home Screen')));
}

class PlayersScreen extends StatelessWidget {
  const PlayersScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Players Screen')));
}

class TrainingsScreen extends StatelessWidget {
  const TrainingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Trainings Screen')));
}

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Matches Screen')));
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Settings Screen')));
}

// Stateful navigation shell for persistent bottom navigation bar
class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  const ScaffoldWithNavBar({Key? key, required this.navigationShell}) : super(key: key ?? const ValueKey('ScaffoldWithNavBar'));

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Players'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Trainings'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Matches'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: widget.navigationShell.currentIndex,
        onTap: (int index) => _onTap(context, index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Home Branch
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ]),
          // Players Branch
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/players',
                builder: (context, state) => const PlayersScreen(),
                routes: [
                  GoRoute(
                    path: ':playerId',
                    builder: (context, state) => PlayerDetailScreen(
                      playerId: state.pathParameters['playerId']!,
                    ),
                  ),
                ]),
          ]),
          // Trainings Branch
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/trainings',
                builder: (context, state) => const TrainingsScreen(),
                routes: [
                  GoRoute(
                    path: ':trainingId',
                    builder: (context, state) => TrainingDetailScreen(
                      trainingId: state.pathParameters['trainingId']!,
                    ),
                  ),
                ]),
          ]),
          // Matches Branch
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/matches',
                builder: (context, state) => const MatchesScreen(),
                routes: [
                  GoRoute(
                    path: ':matchId',
                    builder: (context, state) => MatchDetailScreen(
                      matchId: state.pathParameters['matchId']!,
                    ),
                  ),
                ]),
          ]),
          // Settings Branch with Seasons and Teams
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
            GoRoute(
                path: '/seasons',
                builder: (context, state) => const SeasonListScreen(),
                routes: [
                  GoRoute(
                    path: ':seasonId',
                    builder: (context, state) => SeasonDetailScreen(
                      seasonId: state.pathParameters['seasonId']!,
                    ),
                  ),
                ]),
            GoRoute(
                path: '/teams/:teamId',
                builder: (context, state) => TeamDetailScreen(
                      teamId: state.pathParameters['teamId']!,
                    ),
                routes: [
                  GoRoute(
                    path: 'matches',
                    builder: (context, state) => MatchListScreen(
                      teamId: state.pathParameters['teamId']!,
                    ),
                  ),
                ]),
          ]),
        ],
      ),
    ],
  );
});

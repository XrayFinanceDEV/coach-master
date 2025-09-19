import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coachmaster/models/season.dart';
import 'package:coachmaster/models/team.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/core/app_initialization.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _seasonController = TextEditingController(text: '2025-26');
  final _teamNameController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _seasonController.dispose();
    _teamNameController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final seasonRepo = ref.read(seasonRepositoryProvider);
      final teamRepo = ref.read(teamRepositoryProvider);

      if (kDebugMode) {
        print('🚀 Onboarding: Starting team creation process');
        print('🚀 Onboarding: Season repo type: ${seasonRepo.runtimeType}');
        print('🚀 Onboarding: Team repo type: ${teamRepo.runtimeType}');
      }

      // Create the season
      final season = Season.create(name: _seasonController.text.trim());
      if (kDebugMode) {
        print('🚀 Onboarding: Created season: ${season.name} (ID: ${season.id})');
      }
      await seasonRepo.addSeason(season);
      if (kDebugMode) {
        print('🚀 Onboarding: Season saved to repository');
      }

      // Create the team - this is what completes onboarding
      final team = Team.create(
        name: _teamNameController.text.trim(),
        seasonId: season.id,
      );
      if (kDebugMode) {
        print('🚀 Onboarding: Created team: ${team.name} (ID: ${team.id}) for season ${season.id}');
      }
      await teamRepo.addTeam(team);
      if (kDebugMode) {
        print('🚀 Onboarding: Team saved to repository');

        // Verify the team was actually saved
        final allTeams = teamRepo.getTeams();
        print('🚀 Onboarding: Total teams after creation: ${allTeams.length}');
        for (final t in allTeams) {
          print('🚀 Onboarding: Team found: ${t.name} (ID: ${t.id})');
        }
      }

      // Increment refresh counter to trigger UI rebuilds across the app
      ref.read(refreshCounterProvider.notifier).increment();

      // Invalidate the onboarding status provider to trigger router rebuild
      ref.invalidate(onboardingStatusProvider);

      // Wait a moment to ensure provider refresh
      await Future.delayed(const Duration(milliseconds: 100));

      if (kDebugMode) {
        print('🚀 Onboarding: Checking onboarding status after team creation');
        final hasTeams = ref.read(onboardingStatusProvider);
        print('🚀 Onboarding: onboardingStatusProvider says hasTeams: $hasTeams');

        // Double-check by reading teams directly
        final directCheck = teamRepo.getTeams();
        print('🚀 Onboarding: Direct team check shows ${directCheck.length} teams');

        print('🚀 Onboarding: Redirecting to main app');
      }

      // Navigate to main app
      if (mounted) {
        context.go('/players');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing setup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // App Icon and Title
                Icon(
                  Icons.sports_soccer,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome to CoachMaster',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Let\'s create your first team',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Season Field
                TextFormField(
                  controller: _seasonController,
                  decoration: const InputDecoration(
                    labelText: 'Season',
                    hintText: 'e.g., 2025-26',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a season';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                
                // Team Name Field
                TextFormField(
                  controller: _teamNameController,
                  decoration: const InputDecoration(
                    labelText: 'Team Name',
                    hintText: 'Enter your team name',
                    prefixIcon: Icon(Icons.group),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your team name';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _completeOnboarding(),
                ),
                const SizedBox(height: 32),
                
                // Get Started Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _completeOnboarding,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Setting up...'),
                          ],
                        )
                      : const Text('Get Started'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
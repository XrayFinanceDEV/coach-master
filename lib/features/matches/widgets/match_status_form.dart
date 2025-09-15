import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/models/match.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/match_statistic.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/core/image_cache_utils.dart';
import 'package:coachmaster/l10n/app_localizations.dart';

class MatchStatusForm extends ConsumerStatefulWidget {
  final Match match;
  final VoidCallback onCompleted;

  const MatchStatusForm({
    super.key,
    required this.match,
    required this.onCompleted,
  });

  @override
  ConsumerState<MatchStatusForm> createState() => _MatchStatusFormState();
}

class _MatchStatusFormState extends ConsumerState<MatchStatusForm> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Match result data
  int _goalsFor = 0;
  int _goalsAgainst = 0;
  
  // Player statistics maps
  final Map<String, int> _playerGoals = {};
  final Map<String, int> _playerAssists = {};
  final Map<String, int> _playerYellowCards = {};
  final Map<String, int> _playerRedCards = {};
  final Map<String, int> _playerMinutes = {};
  final Map<String, double?> _playerRatings = {};
  
  // Form state
  bool _addPlayingTime = false;
  bool _isLoading = false;
  int _lastRefreshCounter = 0;
  
  List<Player> _convocatedPlayers = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Wrap in post frame callback to avoid state changes during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadConvocatedPlayers();
      }
    });
  }

  void _loadConvocatedPlayers() {
    try {
      // Use read instead of watch to avoid triggering rebuilds during data loading
      final playerRepository = ref.read(playerRepositoryProvider);
      final convocationRepository = ref.read(matchConvocationRepositoryProvider);
      final statisticRepository = ref.read(matchStatisticRepositoryProvider);
      
      final players = playerRepository.getPlayersForTeam(widget.match.teamId);
      final convocations = convocationRepository.getConvocationsForMatch(widget.match.id);
      final existingStats = statisticRepository.getStatisticsForMatch(widget.match.id);
      
      final newConvocatedPlayers = players.where((player) => 
          convocations.any((conv) => conv.playerId == player.id)).toList();
      
      // Only update state if mounted and data has changed
      if (mounted && _convocatedPlayers != newConvocatedPlayers) {
        setState(() {
          _convocatedPlayers = newConvocatedPlayers;
        });
      }
      
      // Load existing match result if available
      if (widget.match.goalsFor != null && widget.match.goalsAgainst != null) {
        _goalsFor = widget.match.goalsFor!;
        _goalsAgainst = widget.match.goalsAgainst!;
      }
      
      // Initialize player stats - load existing data if available, otherwise use zeros
      for (final player in newConvocatedPlayers) {
        final existingStat = existingStats.firstWhere(
          (stat) => stat.playerId == player.id,
          orElse: () => MatchStatistic.create(
            matchId: widget.match.id,
            playerId: player.id,
            goals: 0,
            assists: 0,
            yellowCards: 0,
            redCards: 0,
            minutesPlayed: 90,
            rating: null,
          ),
        );
        
        _playerGoals[player.id] = existingStat.goals;
        _playerAssists[player.id] = existingStat.assists;
        _playerYellowCards[player.id] = existingStat.yellowCards;
        _playerRedCards[player.id] = existingStat.redCards;
        _playerMinutes[player.id] = existingStat.minutesPlayed;
        _playerRatings[player.id] = existingStat.rating;
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 Error loading convocated players: $e');
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch for image updates to force rebuilds
    ref.watch(playerImageUpdateProvider);
    // Watch for refresh counter changes to trigger rebuilds with fresh data
    final refreshCounter = ref.watch(refreshCounterProvider);
    
    // Only reload if refresh counter changed
    if (_lastRefreshCounter != refreshCounter) {
      _lastRefreshCounter = refreshCounter;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadConvocatedPlayers();
        }
      });
    }
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            _buildProgressBar(),
            
            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  _buildMatchResultStep(),        // Step 0: Match result (5:2)
                  _buildGoalsDetailStep(),        // Step 1: Goals detail by player
                  _buildAssistCountStep(),        // Step 2: Assists count by player  
                  _buildCardsStep(),              // Step 3: Yellow and red cards
                  _buildPlayingTimeChoiceStep(),  // Step 4: Playing time choice
                  if (_addPlayingTime) _buildPlayingTimeStep(), // Step 5: Playing time (optional)
                  _buildRatingStep(),             // Step 6/7: Player ratings
                ],
              ),
            ),
            
            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final totalSteps = _addPlayingTime ? 7 : 6;
    final progress = (_currentStep + 1) / totalSteps;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _currentStep > 0 ? _previousStep : null,
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Step ${_currentStep + 1} of $totalSteps',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchResultStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_score,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          
          Text(
            AppLocalizations.of(context)!.matchResult,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.enterFinalScore,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          // Score input - responsive layout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Goals For
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.goalsFor,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildScoreCounter(_goalsFor, (value) => setState(() => _goalsFor = value)),
                    ],
                  ),
                ),
                
                // Colon separator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    ':',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 36,
                    ),
                  ),
                ),
                
                // Goals Against
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.goalsAgainst,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildScoreCounter(_goalsAgainst, (value) => setState(() => _goalsAgainst = value)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCounter(int value, ValueChanged<int> onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // + button at top
          IconButton(
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add),
            iconSize: 20,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 32),
            padding: const EdgeInsets.all(4),
          ),
          // Score display in middle
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              value.toString(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // - button at bottom
          IconButton(
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove),
            iconSize: 20,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 32),
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsDetailStep() {
    return _buildPlayerStatStep(
      title: AppLocalizations.of(context)!.goalsDetail,
      subtitle: AppLocalizations.of(context)!.whoScoredGoals,
      icon: Icons.sports_soccer,
      color: Colors.green,
      playerStats: _playerGoals,
      onStatChanged: (playerId, value) => setState(() => _playerGoals[playerId] = value),
      validation: () {
        final totalPlayerGoals = _playerGoals.values.fold<int>(0, (sum, goals) => sum + goals);
        if (totalPlayerGoals != _goalsFor) {
          return AppLocalizations.of(context)!.totalGoalsMustEqual(_goalsFor, totalPlayerGoals);
        }
        return null;
      },
    );
  }

  Widget _buildAssistCountStep() {
    final totalGoals = _playerGoals.values.fold<int>(0, (sum, goals) => sum + goals);
    
    return _buildPlayerStatStep(
      title: AppLocalizations.of(context)!.assistsCount,
      subtitle: AppLocalizations.of(context)!.whoProvidedAssists,
      icon: Icons.trending_up,
      color: Colors.blue,
      playerStats: _playerAssists,
      onStatChanged: (playerId, value) => setState(() => _playerAssists[playerId] = value),
      validation: () {
        final totalPlayerAssists = _playerAssists.values.fold<int>(0, (sum, assists) => sum + assists);
        if (totalPlayerAssists > totalGoals) {
          return AppLocalizations.of(context)!.totalAssistsCannotExceed(totalPlayerAssists, totalGoals);
        }
        return null;
      },
    );
  }

  Widget _buildCardsStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.rectangle,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          
          Text(
            AppLocalizations.of(context)!.cardsAndPenalties,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.trackYellowRedCards,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          Expanded(
            child: ListView.separated(
              itemCount: _convocatedPlayers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final player = _convocatedPlayers[index];
                return _buildPlayerCardRow(player);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCardRow(Player player) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Player avatar
          CircleAvatar(
            key: ValueKey('${player.id}-${player.photoPath}'),
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            backgroundImage: _getSafeImageProvider(player.photoPath),
            child: player.photoPath == null || player.photoPath!.isEmpty ||
                (kIsWeb && !player.photoPath!.startsWith('data:') && !player.photoPath!.startsWith('blob:') && !player.photoPath!.startsWith('http'))
                ? Text(
                    '${player.firstName[0]}${player.lastName[0]}'.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${player.firstName} ${player.lastName}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  player.position,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          
          // Card buttons - clickable toggle design
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Yellow cards (up to 2)
              _buildClickableCard(
                player.id,
                isYellow: true,
                cardNumber: 1,
                isActive: (_playerYellowCards[player.id] ?? 0) >= 1,
              ),
              const SizedBox(width: 6),
              _buildClickableCard(
                player.id,
                isYellow: true,
                cardNumber: 2,
                isActive: (_playerYellowCards[player.id] ?? 0) >= 2,
              ),
              const SizedBox(width: 12),
              // Red card (single)
              _buildClickableCard(
                player.id,
                isYellow: false,
                cardNumber: 1,
                isActive: (_playerRedCards[player.id] ?? 0) >= 1,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClickableCard(String playerId, {required bool isYellow, required int cardNumber, required bool isActive}) {
    final baseColor = isYellow ? Colors.yellow[700]! : Colors.red;
    final inactiveColor = Colors.grey[400]!;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isYellow) {
            final currentCount = _playerYellowCards[playerId] ?? 0;
            if (cardNumber == 1) {
              // Toggle first yellow card
              _playerYellowCards[playerId] = isActive ? 0 : 1;
            } else if (cardNumber == 2) {
              // Toggle second yellow card (only if first is active)
              if (currentCount >= 1) {
                _playerYellowCards[playerId] = isActive ? 1 : 2;
              }
            }
          } else {
            // Toggle red card
            _playerRedCards[playerId] = isActive ? 0 : 1;
          }
        });
      },
      child: Container(
        width: 24,
        height: 36,
        decoration: BoxDecoration(
          color: isActive 
              ? (isYellow ? Colors.yellow[100] : Colors.red[100])
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive 
                ? (isYellow ? Colors.yellow[800]! : Colors.red[800]!)
                : Colors.grey[400]!,
            width: 1.5,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isActive ? baseColor : inactiveColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayingTimeChoiceStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          
          Text(
            AppLocalizations.of(context)!.playingTime,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.trackIndividualPlayingTime,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    setState(() => _addPlayingTime = true);
                    _nextStep();
                  },
                  icon: const Icon(Icons.check_circle),
                  label: Text(AppLocalizations.of(context)!.yesTrackPlayingTime),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    setState(() => _addPlayingTime = false);
                    _nextStep();
                  },
                  icon: const Icon(Icons.skip_next),
                  label: Text(AppLocalizations.of(context)!.noSkipPlayingTime),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayingTimeStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.timer,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          
          Text(
            AppLocalizations.of(context)!.playingTime,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.setMinutesPlayedEachPlayer,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          Expanded(
            child: ListView.separated(
              itemCount: _convocatedPlayers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final player = _convocatedPlayers[index];
                return _buildPlayerMinutesSlider(player);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerMinutesSlider(Player player) {
    final minutes = _playerMinutes[player.id] ?? 90;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                key: ValueKey('${player.id}-${player.photoPath}'),
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                backgroundImage: player.photoPath != null && player.photoPath!.isNotEmpty
                    ? (kIsWeb && (player.photoPath!.startsWith('data:') || player.photoPath!.startsWith('blob:') || player.photoPath!.startsWith('http'))
                        ? NetworkImage(player.photoPath!) as ImageProvider
                        : (!kIsWeb ? FileImage(File(player.photoPath!)) as ImageProvider : null))
                    : null,
                child: player.photoPath == null || player.photoPath!.isEmpty ||
                    (kIsWeb && !player.photoPath!.startsWith('data:') && !player.photoPath!.startsWith('blob:') && !player.photoPath!.startsWith('http'))
                    ? Text(
                        '${player.firstName[0]}${player.lastName[0]}'.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${player.firstName} ${player.lastName}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$minutes min',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: minutes.toDouble(),
            min: 0,
            max: 120,
            divisions: 120,
            onChanged: (value) => setState(() => _playerMinutes[player.id] = value.toInt()),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.star,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          
          Text(
            AppLocalizations.of(context)!.playerRatings,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.ratePlayerPerformance,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          Expanded(
            child: ListView.separated(
              itemCount: _convocatedPlayers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final player = _convocatedPlayers[index];
                return _buildPlayerRatingSlider(player);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRatingSlider(Player player) {
    final rating = _playerRatings[player.id];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                key: ValueKey('${player.id}-${player.photoPath}'),
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                backgroundImage: player.photoPath != null && player.photoPath!.isNotEmpty
                    ? (kIsWeb && (player.photoPath!.startsWith('data:') || player.photoPath!.startsWith('blob:') || player.photoPath!.startsWith('http'))
                        ? NetworkImage(player.photoPath!) as ImageProvider
                        : (!kIsWeb ? FileImage(File(player.photoPath!)) as ImageProvider : null))
                    : null,
                child: player.photoPath == null || player.photoPath!.isEmpty ||
                    (kIsWeb && !player.photoPath!.startsWith('data:') && !player.photoPath!.startsWith('blob:') && !player.photoPath!.startsWith('http'))
                    ? Text(
                        '${player.firstName[0]}${player.lastName[0]}'.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${player.firstName} ${player.lastName}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (rating != null) ...[
                _buildStars(rating),
                const SizedBox(width: 8),
                Text(
                  rating.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else
                Text(
                  'Not rated',
                  style: TextStyle(color: Colors.grey[600]),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Always show slider (empty bar when rating is null)
          Slider(
            value: rating ?? 1.0, // Default to 1.0 when null for display purposes
            min: 1.0,
            max: 10.0,
            divisions: 18, // (10-1) * 2 = 18 divisions for 0.5 increments
            onChanged: (value) => setState(() => _playerRatings[player.id] = value),
            activeColor: rating != null ? Theme.of(context).colorScheme.primary : Colors.grey[300],
            inactiveColor: Colors.grey[300],
            thumbColor: rating != null ? Theme.of(context).colorScheme.primary : Colors.grey,
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => setState(() => _playerRatings[player.id] = null),
                child: Text(AppLocalizations.of(context)!.clear),
              ),
              TextButton(
                onPressed: () => setState(() => _playerRatings[player.id] = 6.0),
                child: const Text('6.0'),
              ),
              TextButton(
                onPressed: () => setState(() => _playerRatings[player.id] = 7.5),
                child: const Text('7.5'),
              ),
              TextButton(
                onPressed: () => setState(() => _playerRatings[player.id] = 9.0),
                child: const Text('9.0'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStars(double rating) {
    final fullStars = rating.floor();
    final hasHalfStar = rating - fullStars >= 0.5;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return const Icon(Icons.star, color: Colors.amber, size: 14);
        } else if (index == fullStars && hasHalfStar) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 14);
        } else {
          return Icon(Icons.star_border, color: Colors.grey[400], size: 14);
        }
      }),
    );
  }

  Widget _buildPlayerStatStep({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Map<String, int> playerStats,
    required Function(String playerId, int value) onStatChanged,
    String? Function()? validation,
  }) {
    // Group players by position matching the exact same logic as player form
    // Attacco (Attack)
    final attackPlayers = _convocatedPlayers.where((p) => 
        _isAttackPosition(p.position)).toList();
    
    // Centro Campo (Midfield)
    final midfieldPlayers = _convocatedPlayers.where((p) => 
        _isMidfieldPosition(p.position)).toList();
    
    // Difesa (Defense) - all remaining players including goalkeepers
    final defenseePlayers = _convocatedPlayers.where((p) => 
        _isDefensePosition(p.position)).toList();
    
    // Debug: Print player positions and categorization (remove in production)
    if (kDebugMode) {
      print('🔍 Match Stats Player Categorization:');
      for (final player in _convocatedPlayers) {
        final category = _isAttackPosition(player.position) 
            ? 'Attack' 
            : _isMidfieldPosition(player.position) 
                ? 'Midfield' 
                : 'Defense';
        print('  ${player.firstName} ${player.lastName}: "${player.position}" → $category');
      }
      print('📊 Categories: Attack(${attackPlayers.length}), Midfield(${midfieldPlayers.length}), Defense(${defenseePlayers.length})');
    }
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 16),
          
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          // Validation message
          if (validation != null) ...[
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final errorMessage = validation();
                if (errorMessage != null) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: TextStyle(color: Colors.red[600], fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
          
          const SizedBox(height: 24),
          
          Expanded(
            child: ListView(
              children: [
                // Always show all 3 position categories (Attack → Midfield → Defense)
                _buildPositionSection(_getLocalizedPositionName(context, 'attack'), attackPlayers, playerStats, onStatChanged, color),
                const SizedBox(height: 16),
                
                _buildPositionSection(_getLocalizedPositionName(context, 'midfield'), midfieldPlayers, playerStats, onStatChanged, color),
                const SizedBox(height: 16),
                
                _buildPositionSection(_getLocalizedPositionName(context, 'defense'), defenseePlayers, playerStats, onStatChanged, color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionSection(
    String positionTitle,
    List<Player> players,
    Map<String, int> playerStats,
    Function(String playerId, int value) onStatChanged,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          positionTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        if (players.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'No players in this category',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          )
        else
          ...players.map((player) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildPlayerStatRow(player, playerStats[player.id] ?? 0, onStatChanged, color),
          )),
      ],
    );
  }

  Widget _buildPlayerStatRow(
    Player player,
    int currentValue,
    Function(String playerId, int value) onStatChanged,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Player avatar
          CircleAvatar(
            key: ValueKey('${player.id}-${player.photoPath}'),
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            backgroundImage: _getSafeImageProvider(player.photoPath),
            child: _getSafeImageProvider(player.photoPath) == null
                ? Text(
                    '${player.firstName[0]}${player.lastName[0]}'.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          
          // Player name
          Expanded(
            child: Text(
              '${player.firstName} ${player.lastName}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          
          // Counter controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: currentValue > 0 ? () => onStatChanged(player.id, currentValue - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: color,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              Container(
                width: 40,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  currentValue.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: () => onStatChanged(player.id, currentValue + 1),
                icon: const Icon(Icons.add_circle_outline),
                color: color,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final totalSteps = _addPlayingTime ? 7 : 6;
    final isLastStep = _currentStep == totalSteps - 1;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: Text(AppLocalizations.of(context)!.previous),
              ),
            ),
          
          if (_currentStep > 0) const SizedBox(width: 16),
          
          Expanded(
            child: FilledButton(
              onPressed: _isLoading ? null : (isLastStep ? _saveMatchStatus : _nextStep),
              child: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isLastStep ? 'Complete Match' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    // Validation for specific steps
    if (_currentStep == 1) { // Goals detail step
      final totalPlayerGoals = _playerGoals.values.fold<int>(0, (sum, goals) => sum + goals);
      if (totalPlayerGoals != _goalsFor) {
        _showValidationError('Total goals must equal match result');
        return;
      }
    } else if (_currentStep == 2) { // Assists step
      final totalGoals = _playerGoals.values.fold<int>(0, (sum, goals) => sum + goals);
      final totalPlayerAssists = _playerAssists.values.fold<int>(0, (sum, assists) => sum + assists);
      if (totalPlayerAssists > totalGoals) {
        _showValidationError(AppLocalizations.of(context)!.totalAssistsCannotExceed(totalPlayerAssists, totalGoals));
        return;
      }
    }
    
    if (_currentStep == 4 && _addPlayingTime) {
      // Skip to playing time step
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentStep == 4 && !_addPlayingTime) {
      // Skip playing time, go directly to ratings
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _saveMatchStatus() async {
    setState(() => _isLoading = true);
    
    try {
      final matchRepository = ref.read(matchRepositoryProvider);
      final statisticRepository = ref.read(matchStatisticRepositoryProvider);
      
      // Update match with result
      final result = _goalsFor > _goalsAgainst 
          ? MatchResult.win
          : _goalsFor == _goalsAgainst 
              ? MatchResult.draw 
              : MatchResult.loss;
      
      final updatedMatch = Match(
        id: widget.match.id,
        teamId: widget.match.teamId,
        seasonId: widget.match.seasonId,
        opponent: widget.match.opponent,
        date: widget.match.date,
        location: widget.match.location,
        isHome: widget.match.isHome,
        status: MatchStatus.completed,
        result: result,
        goalsFor: _goalsFor,
        goalsAgainst: _goalsAgainst,
        tactics: widget.match.tactics,
      );
      
      await matchRepository.updateMatch(updatedMatch);
      
      // Delete existing statistics first to avoid duplicates
      final existingStats = statisticRepository.getStatisticsForMatch(widget.match.id);
      for (final stat in existingStats) {
        await statisticRepository.deleteStatistic(stat.id);
      }
      
      // Create new player statistics
      for (final player in _convocatedPlayers) {
        final statistic = MatchStatistic.create(
          matchId: widget.match.id,
          playerId: player.id,
          goals: _playerGoals[player.id] ?? 0,
          assists: _playerAssists[player.id] ?? 0,
          yellowCards: _playerYellowCards[player.id] ?? 0,
          redCards: _playerRedCards[player.id] ?? 0,
          minutesPlayed: _addPlayingTime ? (_playerMinutes[player.id] ?? 90) : 90,
          rating: _playerRatings[player.id],
        );
        
        await statisticRepository.addStatistic(statistic);
      }
      
      // Update player aggregate statistics from all their match stats
      final playerRepository = ref.read(playerRepositoryProvider);
      final allMatchStats = statisticRepository.getStatistics();
      
      // Update stats for all team players (not just convocated ones) to ensure consistency
      final teamPlayers = playerRepository.getPlayersForTeam(widget.match.teamId);
      for (final player in teamPlayers) {
        await playerRepository.updatePlayerStatisticsFromMatchStats(player.id, allMatchStats);
      }
      
      widget.onCompleted();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.matchStatusUpdated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorUpdatingMatch(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Safe image provider to avoid crashes on Android
  ImageProvider? _getSafeImageProvider(String? photoPath) {
    try {
      if (photoPath == null || photoPath.isEmpty) return null;
      
      if (kIsWeb) {
        if (photoPath.startsWith('data:') || photoPath.startsWith('blob:') || photoPath.startsWith('http')) {
          return NetworkImage(photoPath);
        }
        return null;
      } else {
        // For Android/iOS, safely check file existence
        final file = File(photoPath);
        if (file.existsSync()) {
          return FileImage(file);
        }
        return null;
      }
    } catch (e) {
      // Return null if any error occurs
      if (kDebugMode) {
        print('🔴 Error loading image: $e');
      }
      return null;
    }
  }

  // Position name localization
  String _getLocalizedPositionName(BuildContext context, String positionKey) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    
    if (currentLocale == 'it') {
      switch (positionKey) {
        case 'attack':
          return 'Attacco';
        case 'midfield':
          return 'Centrocampo';
        case 'defense':
          return 'Difesa';
        default:
          return 'Altro';
      }
    } else {
      // English position names
      switch (positionKey) {
        case 'attack':
          return 'Attack';
        case 'midfield':
          return 'Midfield';
        case 'defense':
          return 'Defense';
        default:
          return 'Other';
      }
    }
  }

  // Position categorization methods matching player form logic exactly
  bool _isAttackPosition(String position) {
    final pos = position.toLowerCase();
    // Match the exact same positions as in player_form_bottom_sheet.dart Attacco section
    return pos.contains('attaccante') ||
           pos.contains('trequartista') ||
           pos.contains('ala sinistra') ||
           pos.contains('ala destra') ||
           pos.contains('ala') ||
           pos.contains('punta') ||
           // English equivalents from player form - exact matches
           pos.contains('striker') ||
           pos.contains('attacking midfielder') ||
           pos.contains('left winger') ||
           pos.contains('right winger') ||
           pos.contains('winger') ||
           pos.contains('forward');
  }

  bool _isMidfieldPosition(String position) {
    final pos = position.toLowerCase();
    // Match the exact same positions as in player_form_bottom_sheet.dart Centro Campo section
    return pos.contains('centrocampista centrale') ||
           pos.contains('centrocampista') ||
           pos.contains('mediano') ||
           // English equivalents from player form - exact matches
           pos.contains('central midfielder') ||
           pos.contains('midfielder') ||
           pos.contains('defensive midfielder');
  }

  bool _isDefensePosition(String position) {
    final pos = position.toLowerCase();
    // Match the exact same positions as in player_form_bottom_sheet.dart Difesa section
    // This includes ALL remaining positions (goalkeepers, defenders, etc.)
    return pos.contains('portiere') ||
           pos.contains('difensore centrale') ||
           pos.contains('difensore') ||
           pos.contains('terzino sinistro') ||
           pos.contains('terzino destro') ||
           pos.contains('terzino') ||
           pos.contains('quinto') ||
           // English equivalents from player form - exact matches
           pos.contains('goalkeeper') ||
           pos.contains('center back') ||
           pos.contains('defender') ||
           pos.contains('left back') ||
           pos.contains('right back') ||
           pos.contains('full-back') ||
           pos.contains('wing-back') ||
           // Catch any unmatched positions to ensure all players are categorized
           (!_isAttackPosition(position) && !_isMidfieldPosition(position));
  }
}
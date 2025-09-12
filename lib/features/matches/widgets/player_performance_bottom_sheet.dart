import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/match_statistic.dart';
import 'package:coachmaster/core/repository_instances.dart';

class PlayerPerformanceBottomSheet extends ConsumerStatefulWidget {
  final String matchId;
  final Player player;
  final MatchStatistic? existingStats;
  final VoidCallback onSaved;

  const PlayerPerformanceBottomSheet({
    super.key,
    required this.matchId,
    required this.player,
    this.existingStats,
    required this.onSaved,
  });

  @override
  ConsumerState<PlayerPerformanceBottomSheet> createState() => _PlayerPerformanceBottomSheetState();
}

class _PlayerPerformanceBottomSheetState extends ConsumerState<PlayerPerformanceBottomSheet> {
  late int _minutesPlayed;
  late int _goals;
  late int _assists;
  late int _yellowCards;
  late int _redCards;
  late double? _rating;
  late String _notes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize values from existing stats or defaults
    final stats = widget.existingStats;
    _minutesPlayed = stats?.minutesPlayed ?? 0;
    _goals = stats?.goals ?? 0;
    _assists = stats?.assists ?? 0;
    _yellowCards = stats?.yellowCards ?? 0;
    _redCards = stats?.redCards ?? 0;
    _rating = stats?.rating;
    _notes = stats?.notes ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header with player info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: widget.player.photoPath != null 
                    ? FileImage(File(widget.player.photoPath!))
                    : null,
                  child: widget.player.photoPath == null 
                    ? Text(
                        '${widget.player.firstName[0]}${widget.player.lastName[0]}'.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.player.firstName} ${widget.player.lastName}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.player.position,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.sports_soccer,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Form content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Minutes played
                    _buildSectionHeader('Minutes Played'),
                    const SizedBox(height: 12),
                    _buildMinutesSelector(),
                    
                    const SizedBox(height: 24),
                    
                    // Performance stats
                    _buildSectionHeader('Performance'),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCounter(
                            'Goals',
                            _goals,
                            Icons.sports_soccer,
                            (value) => setState(() => _goals = value),
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCounter(
                            'Assists',
                            _assists,
                            Icons.trending_up,
                            (value) => setState(() => _assists = value),
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Cards
                    _buildSectionHeader('Cards'),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCounter(
                            'Yellow Cards',
                            _yellowCards,
                            Icons.rectangle,
                            (value) => setState(() => _yellowCards = value),
                            color: Colors.yellow[700]!,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCounter(
                            'Red Cards',
                            _redCards,
                            Icons.rectangle,
                            (value) => setState(() => _redCards = value),
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Player Rating
                    _buildSectionHeader('Player Rating'),
                    const SizedBox(height: 12),
                    _buildRatingSelector(),
                    
                    const SizedBox(height: 24),
                    
                    // Notes
                    _buildSectionHeader('Notes'),
                    const SizedBox(height: 12),
                    _buildNotesField(),
                    
                    const SizedBox(height: 32),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            onPressed: _isLoading ? null : _savePerformance,
                            child: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save Performance'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildRatingSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rating: ${_rating?.toStringAsFixed(1) ?? 'N/A'}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_rating != null)
                _buildRatingStars(_rating!)
              else
                Text(
                  'No rating',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          if (_rating != null) ...[
            const SizedBox(height: 8),
            Slider(
              value: _rating!,
              min: 0,
              max: 10,
              divisions: 100,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (value) => setState(() => _rating = value),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => setState(() => _rating = null),
                child: const Text('Clear'),
              ),
              TextButton(
                onPressed: () => setState(() => _rating = 5.0),
                child: const Text('5.0'),
              ),
              TextButton(
                onPressed: () => setState(() => _rating = 7.5),
                child: const Text('7.5'),
              ),
              TextButton(
                onPressed: () => setState(() => _rating = 10.0),
                child: const Text('10.0'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    final fullStars = rating.floor();
    final hasHalfStar = rating - fullStars >= 0.5;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star, color: Colors.amber, size: 16);
        } else if (index == fullStars && hasHalfStar) {
          return Icon(Icons.star_half, color: Colors.amber, size: 16);
        } else {
          return Icon(Icons.star_border, color: Colors.grey[400], size: 16);
        }
      }),
    );
  }

  Widget _buildNotesField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        initialValue: _notes,
        decoration: const InputDecoration(
          hintText: 'Add notes about player performance...',
          border: InputBorder.none,
        ),
        maxLines: 3,
        onChanged: (value) => _notes = value,
      ),
    );
  }

  Widget _buildMinutesSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Minutes: $_minutesPlayed',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(_minutesPlayed / 90 * 100).round()}%',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _minutesPlayed.toDouble(),
            min: 0,
            max: 120,
            divisions: 120,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (value) => setState(() => _minutesPlayed = value.toInt()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => setState(() => _minutesPlayed = 0),
                child: const Text('0'),
              ),
              TextButton(
                onPressed: () => setState(() => _minutesPlayed = 45),
                child: const Text('45'),
              ),
              TextButton(
                onPressed: () => setState(() => _minutesPlayed = 90),
                child: const Text('90'),
              ),
              TextButton(
                onPressed: () => setState(() => _minutesPlayed = 120),
                child: const Text('120'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCounter(String title, int value, IconData icon, ValueChanged<int> onChanged, {required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove_circle),
                color: color,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onChanged(value + 1),
                icon: const Icon(Icons.add_circle),
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _savePerformance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final statisticRepository = ref.read(matchStatisticRepositoryProvider);
      
      if (widget.existingStats != null) {
        // Update existing stats
        final updatedStats = MatchStatistic(
          id: widget.existingStats!.id,
          matchId: widget.matchId,
          playerId: widget.player.id,
          minutesPlayed: _minutesPlayed,
          goals: _goals,
          assists: _assists,
          yellowCards: _yellowCards,
          redCards: _redCards,
          rating: _rating,
          notes: _notes,
        );
        await statisticRepository.updateStatistic(updatedStats);
      } else {
        // Create new stats
        final newStats = MatchStatistic.create(
          matchId: widget.matchId,
          playerId: widget.player.id,
          minutesPlayed: _minutesPlayed,
          goals: _goals,
          assists: _assists,
          yellowCards: _yellowCards,
          redCards: _redCards,
          rating: _rating,
          notes: _notes,
        );
        await statisticRepository.addStatistic(newStats);
      }

      widget.onSaved();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Performance saved successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving performance: ${e.toString()}'),
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
}
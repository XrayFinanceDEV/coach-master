import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/models/player.dart';
import 'package:coachmaster/models/match_convocation.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/core/image_cache_utils.dart';
import 'package:coachmaster/l10n/app_localizations.dart';

class ConvocationManagementBottomSheet extends ConsumerStatefulWidget {
  final String matchId;
  final List<Player> players;
  final List<MatchConvocation> convocations;
  final VoidCallback onSaved;

  const ConvocationManagementBottomSheet({
    super.key,
    required this.matchId,
    required this.players,
    required this.convocations,
    required this.onSaved,
  });

  @override
  ConsumerState<ConvocationManagementBottomSheet> createState() => _ConvocationManagementBottomSheetState();
}

class _ConvocationManagementBottomSheetState extends ConsumerState<ConvocationManagementBottomSheet> {
  late Map<String, bool> _playerConvocations;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize convocation map - only existing convocations are selected
    _playerConvocations = {};
    final existingConvocations = {for (var conv in widget.convocations) conv.playerId: true};
    
    for (final player in widget.players) {
      _playerConvocations[player.id] = existingConvocations[player.id] ?? false;
    }
    
    // Debug: Print initialization state
    if (kDebugMode) {
      print('🔍 Convocation initialization:');
      print('  Total players: ${widget.players.length}');
      print('  Existing convocations: ${widget.convocations.length}');
      print('  Player convocation map: $_playerConvocations');
      print('  Initial count: ${_getConvocatedCount()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for image updates to force rebuilds
    ref.watch(playerImageUpdateProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
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
            
            // Header
            Row(
              children: [
                Icon(
                  Icons.group,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.matchConvocations,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.groups, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.totalPlayers,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_getConvocatedCount()}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      TextButton(
                        onPressed: () => _setAllConvocations(true),
                        child: Text(AppLocalizations.of(context)!.selectAll),
                      ),
                      TextButton(
                        onPressed: () => _setAllConvocations(false),
                        child: Text(AppLocalizations.of(context)!.deselectAll),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Player list
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: widget.players.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final player = widget.players[index];
                  final isConvocated = _playerConvocations[player.id] ?? false;
                  
                  return _buildPlayerConvocationCard(player, isConvocated);
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _isLoading ? null : _saveConvocations,
                    child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppLocalizations.of(context)!.saveConvocations),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerConvocationCard(Player player, bool isConvocated) {
    return InkWell(
      onTap: () => _togglePlayerConvocation(player.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isConvocated 
            ? Colors.green.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isConvocated 
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            // Player Avatar
            CircleAvatar(
              key: ValueKey('${player.id}-${player.photoPath}'), // Force rebuild when photo changes
              radius: 24,
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
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            
            // Player Info
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Convocation status
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isConvocated ? Colors.green[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isConvocated ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: isConvocated ? Colors.green[700] : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isConvocated 
                          ? AppLocalizations.of(context)!.present 
                          : AppLocalizations.of(context)!.absent,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isConvocated ? Colors.green[700] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Toggle switch
                Switch(
                  value: isConvocated,
                  onChanged: (value) => _togglePlayerConvocation(player.id),
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _getConvocatedCount() {
    return _playerConvocations.values.where((called) => called).length;
  }

  void _togglePlayerConvocation(String playerId) {
    setState(() {
      _playerConvocations[playerId] = !(_playerConvocations[playerId] ?? false);
    });
  }

  void _setAllConvocations(bool convocated) {
    setState(() {
      for (final player in widget.players) {
        _playerConvocations[player.id] = convocated;
      }
    });
    
    // Debug logging
    if (kDebugMode) {
      print('🔍 Set all convocations to: $convocated');
      print('  New count: ${_getConvocatedCount()}');
      print('  Player states: $_playerConvocations');
    }
  }

  Future<void> _saveConvocations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final convocationRepository = ref.read(matchConvocationRepositoryProvider);
      
      // First, delete all existing convocations for this match
      final existingConvocations = convocationRepository.getConvocationsForMatch(widget.matchId);
      for (final convocation in existingConvocations) {
        await convocationRepository.deleteConvocation(convocation.id);
      }
      
      // Then create new convocations based on current selections
      for (final entry in _playerConvocations.entries) {
        if (entry.value) { // Only create convocation if player is selected
          final convocation = MatchConvocation.create(
            matchId: widget.matchId,
            playerId: entry.key,
            status: PlayerMatchStatus.convoked,
          );
          await convocationRepository.addConvocation(convocation);
        }
      }

      widget.onSaved();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.convocationsSaved),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorSavingConvocations),
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
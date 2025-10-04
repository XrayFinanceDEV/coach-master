import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/models/match.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/l10n/app_localizations.dart';

class MatchFormBottomSheet extends ConsumerStatefulWidget {
  final String teamId;
  final Match? match; // null for creating new match
  final VoidCallback onSaved;
  final Function(String matchId)? onMatchCreated; // New callback for when match is created

  const MatchFormBottomSheet({
    super.key,
    required this.teamId,
    this.match,
    required this.onSaved,
    this.onMatchCreated,
  });

  @override
  ConsumerState<MatchFormBottomSheet> createState() => _MatchFormBottomSheetState();
}

class _MatchFormBottomSheetState extends ConsumerState<MatchFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _opponentController = TextEditingController();
  late DateTime _selectedDate;
  bool _isHome = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.match != null) {
      // Editing existing match
      _opponentController.text = widget.match!.opponent;
      _selectedDate = widget.match!.date;
      _isHome = widget.match!.isHome;
    } else {
      // Creating new match
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _opponentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.match != null;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
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
                  Icons.sports_soccer,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isEditing ? AppLocalizations.of(context)!.editMatch : AppLocalizations.of(context)!.addMatch,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Form
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Opponent field
                      TextFormField(
                        controller: _opponentController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.opponentTeam,
                          prefixIcon: Icon(
                            Icons.shield,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(context)!.pleaseEnterOpponentTeam;
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Date picker
                      InkWell(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.matchDate,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatDate(_selectedDate),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Home/Away toggle
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.matchType,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => _isHome = true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _isHome 
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _isHome 
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.home,
                                            color: _isHome 
                                              ? Colors.white
                                              : Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            AppLocalizations.of(context)!.home,
                                            style: TextStyle(
                                              color: _isHome 
                                                ? Colors.white
                                                : Colors.grey[600],
                                              fontWeight: _isHome 
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => _isHome = false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: !_isHome 
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: !_isHome 
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.flight_takeoff,
                                            color: !_isHome 
                                              ? Colors.white
                                              : Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            AppLocalizations.of(context)!.away,
                                            style: TextStyle(
                                              color: !_isHome 
                                                ? Colors.white
                                                : Colors.grey[600],
                                              fontWeight: !_isHome 
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
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
                              onPressed: _isLoading ? null : _saveMatch,
                              child: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(isEditing ? AppLocalizations.of(context)!.updateMatch : AppLocalizations.of(context)!.createMatch),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveMatch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final matchRepository = ref.read(matchRepositoryProvider);
      final teamRepository = ref.read(teamRepositoryProvider);
      final team = await teamRepository.getTeam(widget.teamId);

      if (team == null) {
        throw Exception('Team not found');
      }

      if (widget.match != null) {
        // Update existing match (preserve existing location)
        final updatedMatch = Match(
          id: widget.match!.id,
          teamId: widget.teamId,
          seasonId: team.seasonId,
          opponent: _opponentController.text.trim(),
          date: _selectedDate,
          location: widget.match!.location, // Preserve existing location
          isHome: _isHome,
          goalsFor: widget.match!.goalsFor,
          goalsAgainst: widget.match!.goalsAgainst,
          result: widget.match!.result,
          status: widget.match!.status,
          tactics: widget.match!.tactics,
        );
        
        await matchRepository.updateMatch(updatedMatch);
      } else {
        // Create new match with default location
        final newMatch = Match.create(
          teamId: widget.teamId,
          seasonId: team.seasonId,
          opponent: _opponentController.text.trim(),
          date: _selectedDate,
          location: _isHome ? AppLocalizations.of(context)!.home : AppLocalizations.of(context)!.away, // Default location based on home/away
          isHome: _isHome,
        );
        
        await matchRepository.addMatch(newMatch);
        
        // Call the onMatchCreated callback if provided to navigate to match detail
        // User can then manually set convocations via the convocation management screen
        if (widget.onMatchCreated != null) {
          widget.onMatchCreated!(newMatch.id);
        }
      }

      widget.onSaved();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.match != null 
                ? AppLocalizations.of(context)!.matchUpdatedSuccessfully
                : AppLocalizations.of(context)!.matchCreatedSuccessfully,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
import 'package:flutter/material.dart';
import 'package:coachmaster/models/season.dart';
import 'package:coachmaster/models/team.dart';

class TeamSelectionCard extends StatelessWidget {
  final List<Season> seasons;
  final List<Team> teams;
  final String? selectedSeasonId;
  final String? selectedTeamId;
  final ValueChanged<String?> onSeasonChanged;
  final ValueChanged<String?> onTeamChanged;

  const TeamSelectionCard({
    super.key,
    required this.seasons,
    required this.teams,
    required this.selectedSeasonId,
    required this.selectedTeamId,
    required this.onSeasonChanged,
    required this.onTeamChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Team Management',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Season Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Season',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    initialValue: seasons.any((s) => s.id == selectedSeasonId) ? selectedSeasonId : null,
                    hint: const Text('-- Select Season --'),
                    items: seasons.map((season) {
                      return DropdownMenuItem<String>(
                        value: season.id,
                        child: Text(season.name),
                      );
                    }).toList(),
                    onChanged: onSeasonChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Team Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Team',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    initialValue: teams.any((t) => t.id == selectedTeamId) ? selectedTeamId : null,
                    hint: const Text('-- Select Team --'),
                    items: teams.map((team) {
                      return DropdownMenuItem<String>(
                        value: team.id,
                        child: Text(team.name),
                      );
                    }).toList(),
                    onChanged: selectedSeasonId != null ? onTeamChanged : null,
                  ),
                ),
              ],
            ),

            if (teams.isEmpty && selectedSeasonId != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No teams in this season. Create your first team!',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
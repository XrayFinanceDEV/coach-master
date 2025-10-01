import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/models/training_attendance.dart';
import 'package:coachmaster/core/repository_instances.dart';
import 'package:coachmaster/core/firestore_repository_providers.dart';
import 'package:coachmaster/l10n/app_localizations.dart';

class TrainingAttendanceListScreen extends ConsumerWidget {
  final String trainingId;
  final String teamId;

  const TrainingAttendanceListScreen({super.key, required this.trainingId, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(playersForTeamStreamProvider(teamId));
    final attendancesAsync = ref.watch(attendancesForTrainingStreamProvider(trainingId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Attendance'),
      ),
      body: playersAsync.when(
        data: (players) => attendancesAsync.when(
          data: (attendances) => ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final attendance = attendances.firstWhere(
                (att) => att.playerId == player.id,
                orElse: () => TrainingAttendance.create(
                  trainingId: trainingId,
                  playerId: player.id,
                  status: TrainingAttendanceStatus.absent,
                ),
              );

          return ListTile(
            title: Text('${player.firstName} ${player.lastName}'),
            trailing: DropdownButton<TrainingAttendanceStatus>(
              value: attendance.status,
              items: TrainingAttendanceStatus.values.map((status) {
                return DropdownMenuItem<TrainingAttendanceStatus>(
                  value: status,
                  child: Text(status.toString().split('.').last),
                );
              }).toList(),
              onChanged: (status) async {
                if (status != null) {
                  final attendanceRepository = ref.read(trainingAttendanceRepositoryProvider);
                  final updatedAttendance = TrainingAttendance(
                    id: attendance.id,
                    trainingId: attendance.trainingId,
                    playerId: attendance.playerId,
                    status: status,
                    reason: attendance.reason,
                    arrivalTime: attendance.arrivalTime,
                  );
                  await attendanceRepository.updateAttendance(updatedAttendance);
                  // Streams will auto-update, no need to invalidate
                }
              },
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(AppLocalizations.of(context)!.errorLoadingAttendances(error.toString()))),
    ),
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, stack) => Center(child: Text(AppLocalizations.of(context)!.errorLoadingPlayers(error.toString()))),
      ),
    );
  }
}

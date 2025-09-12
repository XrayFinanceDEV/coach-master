import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/models/training_attendance.dart';
import 'package:coachmaster/core/repository_instances.dart';

class TrainingAttendanceListScreen extends ConsumerWidget {
  final String trainingId;
  final String teamId;

  const TrainingAttendanceListScreen({super.key, required this.trainingId, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceRepository = ref.watch(trainingAttendanceRepositoryProvider);
    final attendances = attendanceRepository.getAttendancesForTraining(trainingId);
    final playerRepository = ref.watch(playerRepositoryProvider);
    final players = playerRepository.getPlayersForTeam(teamId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Attendance'),
      ),
      body: ListView.builder(
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
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.toString().split('.').last),
                );
              }).toList(),
              onChanged: (status) {
                if (status != null) {
                  final updatedAttendance = TrainingAttendance(
                    id: attendance.id,
                    trainingId: attendance.trainingId,
                    playerId: attendance.playerId,
                    status: status,
                    reason: attendance.reason,
                    arrivalTime: attendance.arrivalTime,
                  );
                  attendanceRepository.updateAttendance(updatedAttendance);
                  ref.invalidate(trainingAttendanceRepositoryProvider);
                }
              },
            ),
          );
        },
      ),
    );
  }
}

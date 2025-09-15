import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coachmaster/core/sync_providers.dart';
import 'package:coachmaster/models/sync_status.dart';

class SyncStatusWidget extends ConsumerWidget {
  final bool showDetails;
  final bool isCompact;

  const SyncStatusWidget({
    super.key,
    this.showDetails = false,
    this.isCompact = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatusAsync = ref.watch(syncStatusProvider);
    final syncInfo = ref.watch(syncInfoProvider);
    final syncActions = ref.watch(syncActionsProvider);

    if (!syncInfo.isInitialized) {
      return const SizedBox.shrink(); // Don't show if sync not initialized
    }

    return syncStatusAsync.when(
      data: (status) => _buildStatusWidget(context, status, syncInfo, syncActions),
      loading: () => _buildLoadingWidget(context),
      error: (error, stack) => _buildErrorWidget(context, error),
    );
  }

  Widget _buildStatusWidget(
    BuildContext context,
    SyncStatus status,
    ({bool isOnline, int pendingSyncCount, bool isInitialized}) syncInfo,
    SyncActions syncActions,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Status color and icon
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case SyncStatus.ready:
        statusColor = Colors.green;
        statusIcon = Icons.cloud_done;
        statusText = syncInfo.isOnline ? 'Synced' : 'Offline';
        break;
      case SyncStatus.syncing:
      case SyncStatus.uploading:
        statusColor = colorScheme.primary;
        statusIcon = Icons.cloud_sync;
        statusText = 'Syncing';
        break;
      case SyncStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.cloud_upload;
        statusText = 'Pending (${syncInfo.pendingSyncCount})';
        break;
      case SyncStatus.error:
      case SyncStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.cloud_off;
        statusText = 'Sync Error';
        break;
      case SyncStatus.conflict:
        statusColor = Colors.amber;
        statusIcon = Icons.warning;
        statusText = 'Conflict';
        break;
      case SyncStatus.synced:
        statusColor = Colors.green;
        statusIcon = Icons.cloud_done;
        statusText = 'Synced';
        break;
    }

    if (isCompact) {
      return _buildCompactStatus(context, statusColor, statusIcon, statusText, syncActions);
    } else {
      return _buildDetailedStatus(context, status, syncInfo, syncActions, statusColor, statusIcon, statusText);
    }
  }

  Widget _buildCompactStatus(
    BuildContext context,
    Color statusColor,
    IconData statusIcon,
    String statusText,
    SyncActions syncActions,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: syncActions.canSync ? () => syncActions.performFullSync() : null,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              statusIcon,
              size: 16,
              color: statusColor,
            ),
            const SizedBox(width: 6),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStatus(
    BuildContext context,
    SyncStatus status,
    ({bool isOnline, int pendingSyncCount, bool isInitialized}) syncInfo,
    SyncActions syncActions,
    Color statusColor,
    IconData statusIcon,
    String statusText,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 12),
                Text(
                  'Sync Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (syncActions.canSync)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => syncActions.performFullSync(),
                    tooltip: 'Sync Now',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Status: '),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Connection: '),
                Text(
                  syncInfo.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: syncInfo.isOnline ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (syncInfo.pendingSyncCount > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('Pending: '),
                  Text(
                    '${syncInfo.pendingSyncCount} items',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            if (showDetails) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: syncActions.canSync ? () => syncActions.performFullSync() : null,
                    child: const Text('Sync Now'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: syncActions.canSync ? () => syncActions.syncAllToFirestore() : null,
                    child: const Text('Upload All'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading...',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, Object error) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 16,
            color: Colors.red,
          ),
          const SizedBox(width: 6),
          Text(
            'Sync Error',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
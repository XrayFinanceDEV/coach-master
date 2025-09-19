import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:coachmaster/models/sync_metadata.dart';
import 'package:coachmaster/models/sync_status.dart';

class FirestoreSyncService {
  static const String _syncMetadataBoxName = 'sync_metadata';
  static const String _pendingSyncBoxName = 'pending_sync_operations';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();
  
  Box<SyncMetadata>? _syncMetadataBox;
  Box<PendingSyncOperation>? _pendingSyncBox;
  String? _currentUserId;
  bool _isOnline = false;
  Timer? _syncTimer;
  
  final StreamController<SyncStatus> _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  // Initialize sync service for a specific user
  Future<void> initialize(String userId) async {
    if (kDebugMode) {
      print('🔄 FirestoreSyncService: Initializing for user $userId');
    }
    
    _currentUserId = userId;
    
    // Initialize Hive boxes for sync metadata
    _syncMetadataBox = await Hive.openBox<SyncMetadata>('${_syncMetadataBoxName}_$userId');
    _pendingSyncBox = await Hive.openBox<PendingSyncOperation>('${_pendingSyncBoxName}_$userId');
    
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((connectivityResults) {
      _onConnectivityChanged(connectivityResults);
    });
    
    // Check initial connectivity
    final connectivityResults = await _connectivity.checkConnectivity();
    _isOnline = !connectivityResults.contains(ConnectivityResult.none);
    
    if (kDebugMode) {
      print('🔄 FirestoreSyncService: Initial connectivity - ${_isOnline ? 'online' : 'offline'}');
    }
    
    // Start periodic sync if online
    if (_isOnline) {
      _startPeriodicSync();
    }
    
    _syncStatusController.add(SyncStatus.ready);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.any((result) => result != ConnectivityResult.none);
    
    if (kDebugMode) {
      print('🔄 FirestoreSyncService: Connectivity changed - ${_isOnline ? 'online' : 'offline'}');
    }
    
    if (!wasOnline && _isOnline) {
      // Just came online - start sync
      _startPeriodicSync();
      performFullSync();
    } else if (wasOnline && !_isOnline) {
      // Went offline - stop periodic sync
      _stopPeriodicSync();
    }
  }

  void _startPeriodicSync() {
    _stopPeriodicSync(); // Stop any existing timer
    _syncTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (_isOnline) {
        performFullSync();
      }
    });
  }

  void _stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  // Record that an entity needs to be synced
  Future<void> markEntityForSync({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> entityData,
    bool isDeleted = false,
  }) async {
    if (_currentUserId == null || _syncMetadataBox == null || _pendingSyncBox == null) {
      if (kDebugMode) {
        print('🔄 FirestoreSyncService: Not initialized, cannot mark entity for sync');
      }
      return;
    }

    if (kDebugMode) {
      print('🔄 FirestoreSyncService: Marking $entityType:$entityId for sync (deleted: $isDeleted)');
    }

    // Create or update sync metadata
    final syncMetadata = SyncMetadata.create(
      entityType: entityType,
      entityId: entityId,
      userId: _currentUserId!,
      isDeleted: isDeleted,
    );
    
    await _syncMetadataBox!.put(syncMetadata.id, syncMetadata);

    // Create pending sync operation
    final operation = isDeleted ? SyncOperation.delete : SyncOperation.update;
    final pendingOp = PendingSyncOperation.create(
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      userId: _currentUserId!,
      entityData: isDeleted ? null : entityData,
    );
    
    await _pendingSyncBox!.put(pendingOp.id, pendingOp);

    // Try immediate sync if online
    if (_isOnline) {
      _performSyncOperation(pendingOp);
    }
  }

  // Perform full sync
  Future<void> performFullSync() async {
    if (_currentUserId == null || !_isOnline || _pendingSyncBox == null) {
      return;
    }

    if (kDebugMode) {
      print('🔄 FirestoreSyncService: Starting full sync');
    }

    _syncStatusController.add(SyncStatus.syncing);

    try {
      // Get all pending operations
      final pendingOps = _pendingSyncBox!.values.toList();
      
      if (pendingOps.isEmpty) {
        if (kDebugMode) {
          print('🔄 FirestoreSyncService: No pending operations');
        }
        _syncStatusController.add(SyncStatus.ready);
        return;
      }

      if (kDebugMode) {
        print('🔄 FirestoreSyncService: Processing ${pendingOps.length} pending operations');
      }

      // Process each operation
      final failedOps = <PendingSyncOperation>[];
      
      for (final op in pendingOps) {
        try {
          await _performSyncOperation(op);
          await _pendingSyncBox!.delete(op.id);
        } catch (e) {
          if (kDebugMode) {
            print('🔄 FirestoreSyncService: Failed to sync ${op.entityType}:${op.entityId} - $e');
          }
          
          // Increment retry count
          final retriedOp = op.incrementRetry();
          if (retriedOp.retryCount < 3) {
            failedOps.add(retriedOp);
          } else {
            if (kDebugMode) {
              print('🔄 FirestoreSyncService: Max retries exceeded for ${op.entityType}:${op.entityId}');
            }
            await _pendingSyncBox!.delete(op.id);
          }
        }
      }

      // Update failed operations with incremented retry count
      for (final failedOp in failedOps) {
        await _pendingSyncBox!.put(failedOp.id, failedOp);
      }

      _syncStatusController.add(failedOps.isEmpty ? SyncStatus.ready : SyncStatus.error);
      
      if (kDebugMode) {
        print('🔄 FirestoreSyncService: Full sync completed. ${failedOps.length} operations failed');
      }

    } catch (e) {
      if (kDebugMode) {
        print('🔄 FirestoreSyncService: Full sync error - $e');
      }
      _syncStatusController.add(SyncStatus.error);
    }
  }

  Future<void> _performSyncOperation(PendingSyncOperation operation) async {
    if (_currentUserId == null) return;

    final collection = _firestore
        .collection('users')
        .doc(_currentUserId!)
        .collection(operation.entityType);

    switch (operation.operation) {
      case SyncOperation.create:
      case SyncOperation.update:
        if (operation.entityData != null) {
          final docData = Map<String, dynamic>.from(operation.entityData!);
          docData['lastModified'] = FieldValue.serverTimestamp();
          docData['userId'] = _currentUserId;
          
          await collection.doc(operation.entityId).set(docData, SetOptions(merge: true));
          
          if (kDebugMode) {
            print('🔄 FirestoreSyncService: Uploaded ${operation.entityType}:${operation.entityId}');
          }
        }
        break;
        
      case SyncOperation.delete:
        await collection.doc(operation.entityId).delete();
        
        if (kDebugMode) {
          print('🔄 FirestoreSyncService: Deleted ${operation.entityType}:${operation.entityId} from Firestore');
        }
        break;
    }

    // Update sync metadata
    if (_syncMetadataBox != null) {
      final syncId = '${operation.entityType}_${operation.entityId}_sync';
      final existingMetadata = _syncMetadataBox!.get(syncId);
      if (existingMetadata != null) {
        await _syncMetadataBox!.put(syncId, existingMetadata.markSynced());
      }
    }
  }

  // Download data from Firestore for a specific entity type
  Future<List<Map<String, dynamic>>> downloadEntities(String entityType) async {
    if (_currentUserId == null || !_isOnline) {
      return [];
    }

    try {
      if (kDebugMode) {
        print('🔄 FirestoreSyncService: Downloading $entityType entities');
      }

      final collection = _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection(entityType);

      final snapshot = await collection.get();
      
      final entities = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Ensure ID is included
        return data;
      }).toList();

      if (kDebugMode) {
        print('🔄 FirestoreSyncService: Downloaded ${entities.length} $entityType entities');
      }

      return entities;
    } catch (e) {
      if (kDebugMode) {
        print('🔄 FirestoreSyncService: Failed to download $entityType entities - $e');
      }
      return [];
    }
  }

  // Get sync status for UI
  bool get isOnline => _isOnline;
  int get pendingSyncCount => _pendingSyncBox?.length ?? 0;
  
  // Dispose resources
  Future<void> dispose() async {
    _stopPeriodicSync();
    await _syncStatusController.close();
    await _syncMetadataBox?.close();
    await _pendingSyncBox?.close();
    
    if (kDebugMode) {
      print('🔄 FirestoreSyncService: Disposed');
    }
  }
}
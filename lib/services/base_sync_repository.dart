import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:coachmaster/services/firestore_sync_service.dart';

abstract class BaseSyncRepository<T> {
  final String boxName;
  final String entityType;
  final FirestoreSyncService? _syncService;
  
  Box<T>? _box;
  String? _currentUserId;
  
  BaseSyncRepository({
    required this.boxName,
    required this.entityType,
    FirestoreSyncService? syncService,
  }) : _syncService = syncService;

  // Initialize repository for a specific user
  Future<void> initForUser(String userId) async {
    _currentUserId = userId;
    
    // Open user-specific box
    final userBoxName = '${boxName}_$userId';
    _box = await Hive.openBox<T>(userBoxName);
    
    if (kDebugMode) {
      print('🟢 ${entityType}Repository: Initialized for user $userId (${_box?.length ?? 0} items)');
    }
    
    // If sync service is available and we have no local data, try to download from Firestore
    if (_syncService != null && _syncService.isOnline && (_box?.isEmpty ?? true)) {
      await _downloadFromFirestore();
    }
  }

  // Get the current box (throws if not initialized)
  Box<T> get box {
    if (_box == null || _currentUserId == null) {
      throw Exception('$entityType repository not initialized. Call initForUser() first.');
    }
    return _box!;
  }

  // Check if repository is initialized
  bool get isInitialized => _box != null && _currentUserId != null;

  // Common CRUD operations with sync
  Future<void> addWithSync(T item) async {
    final itemId = getEntityId(item);
    await box.put(itemId, item);
    
    if (kDebugMode) {
      print('🟢 ${entityType}Repository: Added $itemId');
    }
    
    // Mark for sync
    await _markForSync(item, isDeleted: false);
  }

  Future<void> updateWithSync(T item) async {
    final itemId = getEntityId(item);
    await box.put(itemId, item);
    
    if (kDebugMode) {
      print('🟢 ${entityType}Repository: Updated $itemId');
    }
    
    // Mark for sync
    await _markForSync(item, isDeleted: false);
  }

  Future<void> deleteWithSync(String itemId) async {
    final existingItem = box.get(itemId);
    if (existingItem == null) return;
    
    await box.delete(itemId);
    
    if (kDebugMode) {
      print('🟢 ${entityType}Repository: Deleted $itemId');
    }
    
    // Mark for sync as deleted
    await _markForSync(existingItem, isDeleted: true);
  }

  // Regular CRUD without sync (for legacy compatibility)
  List<T> getAll() => box.values.toList();
  T? get(String id) => box.get(id);
  Future<void> add(T item) => box.put(getEntityId(item), item);
  Future<void> update(T item) => box.put(getEntityId(item), item);
  Future<void> delete(String id) => box.delete(id);

  // Mark item for sync
  Future<void> _markForSync(T item, {required bool isDeleted}) async {
    if (_syncService == null || _currentUserId == null) return;
    
    try {
      final entityData = isDeleted ? <String, dynamic>{} : toMap(item);
      await _syncService.markEntityForSync(
        entityType: entityType,
        entityId: getEntityId(item),
        entityData: entityData,
        isDeleted: isDeleted,
      );
    } catch (e) {
      if (kDebugMode) {
        print('🔴 ${entityType}Repository: Failed to mark for sync - $e');
      }
    }
  }

  // Download from Firestore and merge with local data
  Future<void> _downloadFromFirestore() async {
    if (_syncService == null || !_syncService.isOnline) return;
    
    try {
      if (kDebugMode) {
        print('🔄 ${entityType}Repository: Downloading from Firestore');
      }
      
      final remoteData = await _syncService.downloadEntities(entityType);
      
      for (final itemData in remoteData) {
        try {
          final item = fromMap(itemData);
          final itemId = getEntityId(item);
          
          // Only add if not already exists locally (avoid overwriting newer local changes)
          if (!box.containsKey(itemId)) {
            await box.put(itemId, item);
          }
        } catch (e) {
          if (kDebugMode) {
            print('🔴 ${entityType}Repository: Failed to deserialize item - $e');
          }
        }
      }
      
      if (kDebugMode) {
        print('🟢 ${entityType}Repository: Downloaded ${remoteData.length} items from Firestore');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('🔴 ${entityType}Repository: Failed to download from Firestore - $e');
      }
    }
  }

  // Force sync all local items to Firestore
  Future<void> syncAllToFirestore() async {
    if (_syncService == null || _currentUserId == null) return;
    
    final allItems = getAll();
    
    if (kDebugMode) {
      print('🔄 ${entityType}Repository: Syncing ${allItems.length} items to Firestore');
    }
    
    for (final item in allItems) {
      await _markForSync(item, isDeleted: false);
    }
  }

  // Close repository
  Future<void> close() async {
    await _box?.close();
    _box = null;
    _currentUserId = null;
    
    if (kDebugMode) {
      print('🟢 ${entityType}Repository: Closed');
    }
  }

  // Abstract methods that subclasses must implement
  String getEntityId(T item);
  Map<String, dynamic> toMap(T item);
  T fromMap(Map<String, dynamic> map);
}
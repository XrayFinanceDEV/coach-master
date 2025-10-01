/// Legacy repository instances file - replaced by Firestore-only architecture
/// This file is kept for backward compatibility but all functionality
/// has been moved to firestore_repository_providers.dart
///
/// DO NOT ADD NEW CODE HERE - Use firestore_repository_providers.dart instead

import 'package:flutter/foundation.dart';

// Re-export Firestore providers for backward compatibility
export 'package:coachmaster/core/firestore_repository_providers.dart';

// Legacy initialization flag (always true with Firestore-only approach)
bool _repositoriesInitialized = true;
bool get areRepositoriesInitialized => _repositoriesInitialized;

/// Legacy initialization function - no longer needed with Firestore-only architecture
/// Kept for backward compatibility
Future<void> initializeRepositories({String? userId}) async {
  _repositoriesInitialized = true;
  if (kDebugMode) {
    print('🔧 Repository initialization: Using Firestore-only architecture (no Hive)');
  }
}

/// Legacy close function - no longer needed with Firestore-only architecture
Future<void> closeAllRepositories() async {
  if (kDebugMode) {
    print('🔧 Close repositories: No-op with Firestore-only architecture');
  }
}

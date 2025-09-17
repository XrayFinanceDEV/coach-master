import 'package:flutter/foundation.dart';

class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, List<int>> _measurements = {};
  
  static void startMeasure(String operation) {
    if (kDebugMode) {
      _startTimes[operation] = DateTime.now();
    }
  }
  
  static void endMeasure(String operation) {
    if (kDebugMode && _startTimes.containsKey(operation)) {
      final duration = DateTime.now().difference(_startTimes[operation]!).inMilliseconds;
      _measurements[operation] = _measurements[operation] ?? [];
      _measurements[operation]!.add(duration);
      
      print('🚀 Performance: $operation took ${duration}ms');
      
      if (_measurements[operation]!.length >= 10) {
        final avg = _measurements[operation]!.reduce((a, b) => a + b) / _measurements[operation]!.length;
        print('🚀 Performance: $operation average: ${avg.toStringAsFixed(1)}ms over ${_measurements[operation]!.length} samples');
        _measurements[operation]!.clear();
      }
    }
  }
  
  static void logWidgetBuild(String widgetName) {
    if (kDebugMode) {
      print('🔄 Widget Rebuild: $widgetName at ${DateTime.now().millisecondsSinceEpoch}');
    }
  }
}
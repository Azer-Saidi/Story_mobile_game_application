import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SyncService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  static const String _pendingOperationsKey = 'pending_operations';

  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Enqueue an operation for later synchronization
  Future<void> enqueueOperation(String type, Map<String, dynamic> data) async {
    try {
      final operations = await _getPendingOperations();

      final operation = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': type,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'retryCount': 0,
      };

      operations.add(operation);
      await _savePendingOperations(operations);

      print('Operation enqueued: $type');

      // Try to sync immediately if online
      if (await isOnline) {
        await syncPendingOperations();
      }
    } catch (e) {
      print('Error enqueuing operation: $e');
    }
  }

  /// Synchronize all pending operations
  Future<void> syncPendingOperations() async {
    if (!await isOnline) {
      print('Cannot sync: device is offline');
      return;
    }

    try {
      final operations = await _getPendingOperations();
      final successfulOperations = <Map<String, dynamic>>[];

      for (final operation in operations) {
        try {
          await _executeOperation(operation);
          successfulOperations.add(operation);
          print('Successfully synced operation: ${operation['type']}');
        } catch (e) {
          print('Failed to sync operation ${operation['id']}: $e');

          // Increment retry count
          operation['retryCount'] = (operation['retryCount'] ?? 0) + 1;

          // Remove operation if it has failed too many times
          if (operation['retryCount'] >= 3) {
            print(
                'Removing operation ${operation['id']} after 3 failed attempts');
            successfulOperations.add(operation);
          }
        }
      }

      // Remove successfully synced operations
      final remainingOperations =
          operations.where((op) => !successfulOperations.contains(op)).toList();

      await _savePendingOperations(remainingOperations);

      print(
          'Sync completed. ${successfulOperations.length} operations synced, ${remainingOperations.length} remaining');
    } catch (e) {
      print('Error during sync: $e');
    }
  }

  /// Execute a specific operation
  Future<void> _executeOperation(Map<String, dynamic> operation) async {
    final type = operation['type'] as String;
    final data = operation['data'] as Map<String, dynamic>;

    switch (type) {
      case 'submit_summary':
        await _syncSummarySubmission(data);
        break;
      case 'update_user':
        await _syncUserUpdate(data);
        break;
      case 'record_reading_history':
        await _syncReadingHistory(data);
        break;
      case 'update_avatar_traits':
        await _syncAvatarTraits(data);
        break;
      default:
        throw Exception('Unknown operation type: $type');
    }
  }

  /// Sync summary submission
  Future<void> _syncSummarySubmission(Map<String, dynamic> data) async {
    await _firestore.collection('summaries').add({
      ...data,
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Sync user data update
  Future<void> _syncUserUpdate(Map<String, dynamic> data) async {
    final userId = data['userId'] as String;
    final updateData = Map<String, dynamic>.from(data);
    updateData.remove('userId');

    await _firestore.collection('users').doc(userId).update(updateData);
  }

  /// Sync reading history
  Future<void> _syncReadingHistory(Map<String, dynamic> data) async {
    final studentId = data['studentId'] as String;
    final historyData = Map<String, dynamic>.from(data);
    historyData.remove('studentId');
    historyData['timestamp'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('users')
        .doc(studentId)
        .collection('readingHistory')
        .add(historyData);
  }

  /// Sync avatar traits update
  Future<void> _syncAvatarTraits(Map<String, dynamic> data) async {
    final studentId = data['studentId'] as String;
    final traits = data['avatarTraits'] as Map<String, dynamic>;

    await _firestore.collection('users').doc(studentId).update({
      'avatarTraits': traits,
    });
  }

  /// Get pending operations from storage
  Future<List<Map<String, dynamic>>> _getPendingOperations() async {
    try {
      final operationsJson =
          await _secureStorage.read(key: _pendingOperationsKey);
      if (operationsJson == null) return [];

      final operationsList = jsonDecode(operationsJson) as List<dynamic>;
      return operationsList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error reading pending operations: $e');
      return [];
    }
  }

  /// Save pending operations to storage
  Future<void> _savePendingOperations(
      List<Map<String, dynamic>> operations) async {
    try {
      final operationsJson = jsonEncode(operations);
      await _secureStorage.write(
          key: _pendingOperationsKey, value: operationsJson);
    } catch (e) {
      print('Error saving pending operations: $e');
    }
  }

  /// Clear all pending operations (for testing or reset)
  Future<void> clearPendingOperations() async {
    await _secureStorage.delete(key: _pendingOperationsKey);
  }

  /// Get count of pending operations
  Future<int> getPendingOperationsCount() async {
    final operations = await _getPendingOperations();
    return operations.length;
  }

  /// Check if there are pending operations
  Future<bool> hasPendingOperations() async {
    final count = await getPendingOperationsCount();
    return count > 0;
  }

  /// Get pending operations summary for debugging
  Future<Map<String, int>> getPendingOperationsSummary() async {
    final operations = await _getPendingOperations();
    final summary = <String, int>{};

    for (final operation in operations) {
      final type = operation['type'] as String;
      summary[type] = (summary[type] ?? 0) + 1;
    }

    return summary;
  }
}

import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async'; // Pour le StreamSubscription
import '../services/sync_service.dart';
import '../services/auth_service.dart';

class SyncProvider with ChangeNotifier {
  final SyncService syncService;
  final AuthService authService;
  bool _isSyncing = false;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  SyncProvider({required this.syncService, required this.authService}) {
    // Lancer une première vérification
    checkConnectivityAndSync();

    // Écouter les changements de connectivité
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      if (result != ConnectivityResult.none) {
        print('Connection restored! Triggering sync.');
        syncData(); // Tenter de synchroniser dès que la connexion revient
      }
    }) as StreamSubscription<ConnectivityResult>;
  }

  @override
  void dispose() {
    _connectivitySubscription
        .cancel(); // Très important pour éviter les fuites de mémoire
    super.dispose();
  }

  bool get isSyncing => _isSyncing;

  Future<void> checkConnectivityAndSync() async {
    final result = await Connectivity().checkConnectivity();
    if (result != ConnectivityResult.none) {
      await syncData();
    }
  }

  Future<void> syncData() async {
    if (_isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      // S'assurer que l'utilisateur est connecté avant de synchroniser
      if (authService.currentUser != null) {
        await syncService.syncPendingOperations();
      }
    } catch (e) {
      print("Sync error: $e");
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Méthode générique pour ajouter une opération à la file d'attente.
  Future<void> addOperation(String type, Map<String, dynamic> data) async {
    await syncService.enqueueOperation(type, data);
  }
}

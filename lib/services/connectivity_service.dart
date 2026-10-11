import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  // Instance unique pour éviter de recréer l'objet Connectivity à chaque fois
  static final Connectivity _connectivity = Connectivity();

  /// Vérifie si l'appareil dispose d'une connexion réseau active (Wi-Fi, Mobile, etc.)
  static Future<bool> hasInternet() async {
    try {
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      
      // S'il n'y a aucune connexion ou que la liste contient uniquement 'none'
      if (results.isEmpty || (results.length == 1 && results.first == ConnectivityResult.none)) {
        return false;
      }
      return true;
    } catch (e) {
      // En cas d'erreur sur l'appareil, on retourne false par sécurité
      return false;
    }
  }

  /// Flux (Stream) qui écoute les changements de connexion en temps réel
  static Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((List<ConnectivityResult> results) {
      if (results.isEmpty || (results.length == 1 && results.first == ConnectivityResult.none)) {
        return false;
      }
      return true;
    });
  }
}
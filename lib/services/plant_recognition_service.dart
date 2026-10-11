// ============================================================
//  PlantaMed — Service Pl@ntNet API v2 & Offline TFLite
//  Clé API : 2b10VB2iEREG4uJ34Ltjrn1u
// ============================================================

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

// Importations de tes modèles et services existants
import '../models/plant_model.dart';
import '../models/identification_result.dart';
import 'firebase_service.dart';
import 'connectivity_service.dart'; // Ton service de connectivité mis à jour
import 'offline_recognition_service.dart'; // Ton service TFLite mis à jour

class PlantRecognitionService {
  static const String _apiKey  = '2b10VB2iEREG4uJ34Ltjrn1u';
  static const String _project = 'all';
  static String get _endpoint =>
      'https://my-api.plantnet.org/v2/identify/$_project'
      '?api-key=$_apiKey&lang=fr&include-related-images=true';

  final FirebaseService _db = FirebaseService();
  final Logger _logger = Logger();
  
  // Instance du service hors ligne TFLite
  final OfflineRecognitionService _offlineService = OfflineRecognitionService();

  // ── Identifier une plante depuis une photo via Pl@ntNet API ─────────────────
  Future<PlantNetResponse> identifyPlantOnline(File imageFile, {String organ = 'auto'}) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_endpoint));
      request.files.add(await http.MultipartFile.fromPath('images', imageFile.path, filename: 'plant.jpg'));
      request.fields['organs'] = organ;

      final streamed = await request.send();
      final body     = await streamed.stream.bytesToString();

      _logger.i('PlantNet status: ${streamed.statusCode}');

      if (streamed.statusCode == 200) {
        return PlantNetResponse.fromJson(jsonDecode(body) as Map<String, dynamic>);
      } else if (streamed.statusCode == 404) {
        return PlantNetResponse.notFound();
      } else {
        throw Exception('Erreur PlantNet: ${streamed.statusCode} — $body');
      }
    } catch (e) {
      _logger.e('Erreur identification en ligne: $e');
      rethrow;
    }
  }

  // ── Pipeline complet Hybride : En ligne (Pl@ntNet) / Hors ligne (TFLite) ──
  Future<RecognitionResult> recognizeAndGetMedicinalInfo(File imageFile, {String organ = 'auto'}) async {
    // 1. Vérifier l'état de la connexion Internet
    final bool isOnline = await ConnectivityService.hasInternet();

    if (isOnline) {
      _logger.i('Mode En Ligne : Utilisation de l\'API Pl@ntNet');
      return _processOnlineRecognition(imageFile, organ);
    } else {
      _logger.w('Mode Hors Ligne Détecté : Bascule sur le modèle TFLite local');
      return _processOfflineRecognition(imageFile);
    }
  }

  // ── Traitement en mode connecté ───────────────────────────────────────────
  Future<RecognitionResult> _processOnlineRecognition(File imageFile, String organ) async {
    final response = await identifyPlantOnline(imageFile, organ: organ);

    if (!response.found || response.results.isEmpty) {
      return RecognitionResult(
        isPlant: false, isMedicinal: false, confidence: 0.0,
        message: "Impossible d'identifier cette plante via l'API. Prends la feuille ou la fleur de plus près.",
      );
    }

    final top = response.results.first;
    _logger.i('Identifiée en ligne: ${top.scientificName} (${top.scorePercent})');

    // Recherche de vertus médicinales dans Firestore
    Plant? plant = await _db.findPlantByScientificName(top.scientificName);
    if (plant == null) {
      for (final name in top.commonNames) {
        plant = await _db.findPlantByCommonName(name);
        if (plant != null) break;
      }
    }

    return _buildRecognitionResult(top.scientificName, top.commonNames, top.score, plant, top.images, response.results);
  }

  // ── Traitement en mode déconnecté (Local TFLite) ───────────────────────────
  Future<RecognitionResult> _processOfflineRecognition(File imageFile) async {
    try {
      // Exécuter la classification avec l'interpréteur TFLite
      final offlineResult = await _offlineService.recognize(imageFile);

      if (!offlineResult.isReliable) {
        return RecognitionResult(
          isPlant: false, isMedicinal: false, confidence: offlineResult.confidence,
          message: "Confiance locale trop faible (${(offlineResult.confidence * 100).toStringAsFixed(1)}%). Essaie sous un meilleur angle.",
        );
      }

      _logger.i('Identifiée hors ligne (TFLite): ${offlineResult.label} (${(offlineResult.confidence * 100).toStringAsFixed(1)}%)');

      // Dans un mode 100% hors ligne sans réseau, Firestore échouera sauf si la persistance locale est activée.
      // Le code essaie tout de même de charger depuis le cache/Firestore local.
      Plant? plant;
      try {
        plant = await _db.findPlantByCommonName(offlineResult.label);
      } catch (dbError) {
        _logger.w('Impossible de joindre Firestore en mode déconnecté: $dbError. Utilisation des infos basiques.');
      }

      // Convertir le résultat d'allScores en format compatible PlantResult pour conserver l'historique de l'interface graphique
      List<PlantResult> alternatives = offlineResult.allScores.entries.map((e) {
        return PlantResult(
          score: e.value,
          scientificName: '',
          genus: '',
          family: '',
          commonNames: [e.key],
          images: [],
        );
      }).toList()..sort((a, b) => b.score.compareTo(a.score));

      return _buildRecognitionResult(
        offlineResult.label, 
        [offlineResult.label], 
        offlineResult.confidence, 
        plant, 
        [], // Pas d'images d'illustration distantes en mode hors ligne
        alternatives
      );
    } catch (e) {
      _logger.e('Erreur lors du traitement TFLite hors ligne: $e');
      return RecognitionResult(
        isPlant: false, isMedicinal: false, confidence: 0.0,
        message: "Erreur lors de l'analyse hors ligne de l'image.",
      );
    }
  }

  // ── Générateur de structure de réponse unifiée ────────────────────────────
  RecognitionResult _buildRecognitionResult(
    String name, List<String> commonNames, double score, Plant? plant, List<String> referenceImages, List<PlantResult> suggestions
  ) {
    if (plant != null) {
      return RecognitionResult(
        isPlant: true, isMedicinal: true, confidence: score,
        identifiedName: name, commonNames: commonNames,
        medicinalPlant: plant, referenceImages: referenceImages,
        allSuggestions: suggestions,
        message: '✅ [Local/TFLite] Plante médicinale identifiée : ${plant.nomCommun}',
      );
    } else {
      return RecognitionResult(
        isPlant: true, isMedicinal: false, confidence: score,
        identifiedName: name, commonNames: commonNames,
        referenceImages: referenceImages, allSuggestions: suggestions,
        message: '🌿 "$name" n\'est pas référencée dans notre dictionnaire médicinal.',
      );
    }
  }

  // ── Tester la connexion API ────────────────────────────────
  Future<bool> testApiConnection() async {
    try {
      final r = await http.get(Uri.parse('https://my-api.plantnet.org/v2/projects?api-key=$_apiKey'));
      return r.statusCode == 200;
    } catch (_) { return false; }
  }

  // Nettoyage de la mémoire du modèle à la fermeture du service
  void dispose() {
    _offlineService.dispose();
  }
}

// ════════════════════════════════════════════════════════════
//  MODÈLES DE RÉPONSE Pl@ntNet (Inchangés mais réutilisés)
// ════════════════════════════════════════════════════════════

class PlantNetResponse {
  final bool found;
  final List<PlantResult> results;

  PlantNetResponse({required this.found, required this.results});

  factory PlantNetResponse.notFound() => PlantNetResponse(found: false, results: []);

  factory PlantNetResponse.fromJson(Map<String, dynamic> json) {
    final raw     = json['results'] as List<dynamic>? ?? [];
    final results = raw.map((r) => PlantResult.fromJson(r as Map<String, dynamic>)).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return PlantNetResponse(found: results.isNotEmpty, results: results);
  }
}

class PlantResult {
  final double       score;
  final String       scientificName;
  final String       genus;
  final String       family;
  final List<String> commonNames;
  final List<String> images;

  PlantResult({required this.score, required this.scientificName,
    required this.genus, required this.family,
    required this.commonNames, required this.images});

  factory PlantResult.fromJson(Map<String, dynamic> json) {
    final sp      = json['species'] as Map<String, dynamic>? ?? {};
    final sciName = sp['scientificNameWithoutAuthor']?.toString() ?? '';
    final genus   = (sp['genus']  as Map?)?.containsKey('scientificNameWithoutAuthor') == true
        ? sp['genus']['scientificNameWithoutAuthor'].toString() : '';
    final family  = (sp['family'] as Map?)?.containsKey('scientificNameWithoutAuthor') == true
        ? sp['family']['scientificNameWithoutAuthor'].toString() : '';
    final names   = (sp['commonNames'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final imgs    = (json['images'] as List<dynamic>? ?? [])
        .map((i) => (i as Map<String, dynamic>)['url']?['m']?.toString() ?? '')
        .where((u) => u.isNotEmpty).take(3).toList();

    return PlantResult(score: (json['score'] as num?)?.toDouble() ?? 0.0,
        scientificName: sciName, genus: genus, family: family,
        commonNames: names, images: imgs);
  }

  String get displayName    => commonNames.isNotEmpty ? '${commonNames.first} ($scientificName)' : scientificName;
  String get scorePercent   => '${(score * 100).toStringAsFixed(1)}%';
  String get confidenceLabel {
    if (score >= 0.80) return 'Très haute confiance';
    if (score >= 0.60) return 'Haute confiance';
    if (score >= 0.40) return 'Confiance moyenne';
    return 'Faible confiance — Réessaie';
  }
}
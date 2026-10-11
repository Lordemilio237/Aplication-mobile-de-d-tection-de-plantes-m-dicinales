// ============================================================
//  PlantaMed — Service TFLite (Version Hybride Locale + API)
// ============================================================

import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../models/plant_model.dart';
import '../models/identification_result.dart';
import '../data/plants_data.dart';

// Importations des services additionnels
import 'plantnet_service.dart'; // Assure-toi que ce fichier existe avec ta clé API

// Gestion de l'import pour compatibilité Web/Mobile
import 'tflite_mobile.dart' if (dart.library.html) 'tflite_web.dart';

class _ModelResult {
  final String label;
  final double confidence;
  _ModelResult(this.label, this.confidence);
}

class TFLiteService {
  static const int _inputSize = 224;
  static const double _threshold = 0.45;

  dynamic _interpreter5;
  dynamic _interpreter24;
  dynamic _interpreter40;

  Map<String, String> _labels5 = {};
  Map<String, String> _labels24 = {};
  Map<String, String> _labels40 = {};

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  // Instance du service Expert
  final PlantNetService _plantNetService = PlantNetService();

  // ════════════════════════════════════════════════════════
  //  CHARGEMENT DES MODÈLES ET DES LABELS
  // ════════════════════════════════════════════════════════
  Future<void> loadModel() async {
    if (kIsWeb) return;
    
    try {
      // Modèle 1 - Toujours disponible
      try {
        _interpreter5 = await loadInterpreter('assets/models/plant_labels2.tflite');
        _labels5 = _parseLabels(await rootBundle.loadString('assets/models/plant_labels2.json'));
        debugPrint('✅ [TFLiteService] Modèle 1 (plant_labels2) chargé');
      } catch (e) {
        debugPrint('⚠️ [TFLiteService] Erreur chargement modèle 1: $e');
      }

      // Modèle 2 - Optionnel (peut ne pas exister)
      try {
        _interpreter24 = await loadInterpreter('assets/models/plant_labels.tflite');
        _labels24 = _parseLabels(await rootBundle.loadString('assets/models/plant_labels.json'));
        debugPrint('✅ [TFLiteService] Modèle 2 (plant_labels) chargé');
      } catch (e) {
        debugPrint('⚠️ [TFLiteService] Modèle 2 non disponible: $e');
        _interpreter24 = null;
        _labels24 = {};
      }

      // Modèle 3 - Optionnel (peut ne pas exister)
      try {
        _interpreter40 = await loadInterpreter('assets/models/plant_model_40classes.tflite');
        _labels40 = _parseLabels(await rootBundle.loadString('assets/models/plant_labels_40classes.json'));
        debugPrint('✅ [TFLiteService] Modèle 3 (plant_model_40classes) chargé');
      } catch (e) {
        debugPrint('⚠️ [TFLiteService] Modèle 3 non disponible: $e');
        _interpreter40 = null;
        _labels40 = {};
      }

      // Vérifier qu'au moins UN modèle s'est chargé
      if (_interpreter5 != null || _interpreter24 != null || _interpreter40 != null) {
        _isLoaded = true;
        debugPrint('--- [TFLiteService] : Initialisation réussie (${[_interpreter5, _interpreter24, _interpreter40].where((e) => e != null).length} modèle(s) actif(s)) ---');
      } else {
        _isLoaded = false;
        debugPrint('❌ [TFLiteService] ERREUR : Aucun modèle n\'a pu être chargé');
      }
    } catch (e) {
      debugPrint('❌ Erreur initialisation TFLite : $e');
      _isLoaded = false;
    }
  }

  Map<String, String> _parseLabels(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  // ════════════════════════════════════════════════════════
  //  RECONNAISSANCE PRINCIPALE (MODIFIÉE POUR PLANTNET)
  // ════════════════════════════════════════════════════════
  Future<RecognitionResult> recognizePlant(File imageFile) async {
    if (kIsWeb) {
      return RecognitionResult(isPlant: false, isMedicinal: false, confidence: 0.0, message: 'TFLite non disponible sur Web');
    }
    
    if (!_isLoaded) {
      debugPrint('[TFLiteService] Modèle non chargé, tentative de chargement...');
      try {
        await loadModel();
      } catch (e) {
        debugPrint('[TFLiteService] Erreur lors du chargement du modèle: $e');
      }
    }
    
    if (!_isLoaded) {
      final errorMsg = 'Modèle IA non disponible. Assurez-vous que les fichiers "assets/models/" sont bien inclus dans le projet.';
      debugPrint('[TFLiteService] ERREUR - $errorMsg');
      return RecognitionResult(isPlant: false, isMedicinal: false, confidence: 0.0, message: errorMsg);
    }

    try {
      final inputData = await _preprocessImage(imageFile);

      // 1. Exécution des modèles locaux (Rapide / Hors-ligne)
      final r5 = _runModel(_interpreter5, _labels5, inputData);
      final r24 = _runModel(_interpreter24, _labels24, inputData);
      final r40 = _runModel(_interpreter40, _labels40, inputData);

      // Choix du meilleur score local
      _ModelResult bestLocal = r40;
      if (r24.confidence > bestLocal.confidence) bestLocal = r24;
      if (r5.confidence > bestLocal.confidence) bestLocal = r5;

      String finalLabel = bestLocal.label;
      double finalConfidence = bestLocal.confidence;

      debugPrint('Score TFLite local : $finalLabel (${(finalConfidence * 100).toStringAsFixed(1)}%)');

      // 2. LOGIQUE D'ARBITRAGE : Si l'IA locale doute (ex: 45% - 75%), on appelle Pl@ntNet
      // C'est ici que ton problème de "Castor" sera résolu !
      if (finalConfidence >= _threshold && finalConfidence < 0.75) {
        debugPrint('--- [TFLiteService] : Confiance moyenne, appel Pl@ntNet Expert ---');
        
        final expertResult = await _plantNetService.identifierPlante(imageFile);
        
        if (expertResult != null) {
          // On privilégie le nom scientifique renvoyé par Pl@ntNet
          finalLabel = expertResult['scientificName'];
          finalConfidence = expertResult['score']; 
          debugPrint('--- [Pl@ntNet] : Correction appliquée -> $finalLabel ---');
        }
      }

      if (finalConfidence < _threshold) {
        return RecognitionResult(
          isPlant: false, isMedicinal: false,
          confidence: finalConfidence,
          message: 'Plante non reconnue précisément.',
        );
      }

      // 3. Recherche dans la base de données locale (PlantsData)
      final plant = _findPlant(finalLabel);
      
      if (plant != null) {
        return RecognitionResult(
          isPlant: true, isMedicinal: true,
          confidence: finalConfidence,
          identifiedName: plant.nomScientifique,
          commonNames: [plant.nomCommun],
          medicinalPlant: plant,
          message: '${plant.nomCommun}\n${plant.nomScientifique}',
        );
      }

      // Si identifiée mais pas dans la base médicinale
      return RecognitionResult(
        isPlant: true, isMedicinal: false,
        confidence: finalConfidence,
        identifiedName: finalLabel,
        message: '$finalLabel\nPlante identifiée (Hors base médicinale)',
      );

    } catch (e) {
      debugPrint('Erreur reconnaissance : $e');
      return RecognitionResult(isPlant: false, isMedicinal: false, confidence: 0.0, message: 'Erreur d\'analyse');
    }
  }

  // ════════════════════════════════════════════════════════
  //  INFÉRENCE AUTO-ADAPTATIVE
  // ════════════════════════════════════════════════════════
  _ModelResult _runModel(
    dynamic interpreter,
    Map<String, String> labels,
    List<List<List<List<double>>>> inputData,
  ) {
    if (interpreter == null) return _ModelResult('Inconnu', 0.0);

    try {
      final outputShape = interpreter.getOutputTensor(0).shape;
      final realNumClasses = outputShape[1]; 
      
      var output = List.generate(1, (_) => List<double>.filled(realNumClasses, 0.0));

      interpreter.run(inputData, output);
      
      final List<double> preds = output[0];

      double maxScore = -1.0;
      int maxIndex = 0;
      for (int i = 0; i < preds.length; i++) {
        if (preds[i] > maxScore) {
          maxScore = preds[i];
          maxIndex = i;
        }
      }

      final String labelName = labels[maxIndex.toString()] ?? 'Inconnu ($maxIndex)';
      return _ModelResult(labelName, maxScore);

    } catch (e) {
      debugPrint('Erreur Inférence : $e');
      return _ModelResult('Erreur Technique', 0.0);
    }
  }

  // ════════════════════════════════════════════════════════
  //  PRÉTRAITEMENT DE L'IMAGE
  // ════════════════════════════════════════════════════════
  Future<List<List<List<List<double>>>>> _preprocessImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(Uint8List.fromList(bytes));
    if (image == null) throw Exception('Image invalide');
    
    final resized = img.copyResize(image, width: _inputSize, height: _inputSize);

    return List.generate(1, (_) =>
      List.generate(_inputSize, (y) =>
        List.generate(_inputSize, (x) {
          final pixel = resized.getPixel(x, y);
          return [
            (pixel.r / 127.5) - 1.0, 
            (pixel.g / 127.5) - 1.0, 
            (pixel.b / 127.5) - 1.0
          ];
        })
      )
    );
  }

  // ════════════════════════════════════════════════════════
  //  RECHERCHE SÉCURISÉE (DART DATA MATCHING)
  // ════════════════════════════════════════════════════════
  Plant? _findPlant(String label) {
    final plants = PlantsData.getPlants();
    
    String clean(String text) {
      return text.toLowerCase()
          .replaceAll(' ', '')
          .replaceAll('_', '')
          .replaceAll('-', '')
          .trim();
    }

    final query = clean(label);

    for (final plant in plants) {
      final nomCommun = clean(plant.nomCommun);
      final nomScientifique = clean(plant.nomScientifique);

      if (query == nomCommun || 
          query == nomScientifique ||
          nomCommun.contains(query) ||
          nomScientifique.contains(query)) {
        return plant;
      }
      
      if (plant.tags.any((tag) => clean(tag) == query)) {
        return plant;
      }
    }
    return null;
  }

  void dispose() {
    if (!kIsWeb) {
      _interpreter5?.close();
      _interpreter24?.close();
      _interpreter40?.close();
    }
    _isLoaded = false;
  }
}
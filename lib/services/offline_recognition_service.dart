import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class OfflineRecognitionService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;

  static const int INPUT_SIZE = 224; 
  static const double CONFIDENCE_THRESHOLD = 0.5;

  // Chemins d'accès par défaut (modifiables lors du chargement)
  final String modelPath;
  final String labelsPath;

  OfflineRecognitionService({
    this.modelPath = 'assets/models/plant_model_40classes.tflite',
    this.labelsPath = 'assets/models/plant_labels_40classes.json', // Ou plant_labels.json
  });

  // ── Charger le modèle ──────────────────────────────────────
  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      _interpreter = await Interpreter.fromAsset(modelPath);
      await _loadLabels();
      _isLoaded = true;
    } catch (e) {
      throw Exception('Erreur chargement modèle: $e');
    }
  }

  Future<void> _loadLabels() async {
    try {
      final raw = await rootBundle.loadString(labelsPath);
      final Map<String, dynamic> jsonMap = jsonDecode(raw);

      // 1. Convertir les clés en entiers et trier pour respecter l'ordre des sorties du modèle
      final sortedKeys = jsonMap.keys.map((k) => int.parse(k)).toList()..sort();

      // 2. Remplir la liste des labels dans le bon ordre
      _labels = sortedKeys.map((key) => jsonMap[key.toString()].toString()).toList();
    } catch (e) {
      throw Exception('Erreur lors du traitement des labels JSON: $e');
    }
  }

  // ── Prétraitement de l'image ───────────────────────────────
  List<List<List<List<double>>>> _preprocessImage(File imageFile) {
    final bytes = imageFile.readAsBytesSync();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) throw Exception("Impossible de décoder l'image");
    
    image = img.copyResize(image, width: INPUT_SIZE, height: INPUT_SIZE);

    // Normalisation [0, 1] - Corrigée pour la version 4.x de package:image
    return List.generate(1, (_) =>
      List.generate(INPUT_SIZE, (y) =>
        List.generate(INPUT_SIZE, (x) {
          final pixel = image!.getPixel(x, y);
          return [
            pixel.r / 255.0,
            pixel.g / 255.0,
            pixel.b / 255.0,
          ];
        })
      )
    );
  }

  // ── Reconnaissance ─────────────────────────────────────────
  Future<OfflineResult> recognize(File imageFile) async {
    if (!_isLoaded) await loadModel();

    final input  = _preprocessImage(imageFile);
    
    // La taille de l'output s'adapte automatiquement au nombre de labels chargés
    final output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);

    _interpreter!.run(input, output);

    final scores   = List<double>.from(output[0]);
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final maxIndex = scores.indexOf(maxScore);

    return OfflineResult(
      label      : _labels[maxIndex],
      confidence : maxScore,
      allScores  : Map.fromIterables(_labels, scores),
    );
  }

  void dispose() {
    _interpreter?.close();
    _isLoaded = false;
  }
}

class OfflineResult {
  final String            label;
  final double            confidence;
  final Map<String, double> allScores;

  OfflineResult({
    required this.label,
    required this.confidence,
    required this.allScores,
  });

  bool get isReliable => confidence >= OfflineRecognitionService.CONFIDENCE_THRESHOLD;

  String get confidenceLabel {
    if (confidence >= 0.80) return 'Très haute confiance';
    if (confidence >= 0.60) return 'Haute confiance';
    if (confidence >= 0.40) return 'Confiance moyenne';
    return 'Faible confiance';
  }
}
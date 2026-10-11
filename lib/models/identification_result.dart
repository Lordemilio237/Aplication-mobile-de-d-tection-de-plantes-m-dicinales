// ============================================================
//  PlantaMed — Modèles résultats d'identification Pl@ntNet
// ============================================================

import '../models/plant_model.dart';
import '../services/plant_recognition_service.dart'; // Pour PlantResult

// ── Résultat global d'identification d'une plante ──────────
class RecognitionResult {
  final bool isPlant;
  final bool isMedicinal;
  final double confidence;
  final String? identifiedName;
  final List<String> commonNames;
  final Plant? medicinalPlant;
  final List<String> referenceImages;
  final List<PlantResult> allSuggestions;
  final String message;

  RecognitionResult({
    required this.isPlant,
    required this.isMedicinal,
    required this.confidence,
    this.identifiedName,
    this.commonNames = const [],
    this.medicinalPlant,
    this.referenceImages = const [],
    this.allSuggestions = const [],
    required this.message,
  });

  RecognitionStatus get status {
    if (!isPlant) return RecognitionStatus.notAPlant;
    if (!isMedicinal) return RecognitionStatus.plantButNotMedicinal;
    return RecognitionStatus.medicinalPlantFound;
  }

  String get statusEmoji {
    switch (status) {
      case RecognitionStatus.notAPlant:
        return '❌';
      case RecognitionStatus.plantButNotMedicinal:
        return '🌿';
      case RecognitionStatus.medicinalPlantFound:
        return '✅';
    }
  }
}

// ── Enum pour le statut d'identification ───────────────────
enum RecognitionStatus {
  notAPlant,
  plantButNotMedicinal,
  medicinalPlantFound,
}
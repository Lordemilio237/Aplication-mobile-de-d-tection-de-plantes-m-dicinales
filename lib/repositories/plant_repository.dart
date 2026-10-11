// ============================================================
//  PlantaMed — Repository (couche métier)
//  Utilisé par l'UI pour accéder aux données
// ============================================================

import 'dart:async';
import '../models/plant_model.dart';
import '../services/firebase_service.dart';

class PlantRepository {
  final FirebaseService _service = FirebaseService();

  // ── Lecture ────────────────────────────────────────────────
  Future<List<Plant>> getAllPlants()                       => _service.getAllPlants();
  Future<Plant?>      getPlantById(String id)             => _service.getPlantById(id);
  Future<List<Plant>> searchPlants(String query)          => _service.searchPlants(query);
  Future<List<Plant>> getByCategory(String cat)           => _service.getPlantsByCategorie(cat);
  Future<List<Plant>> getPopular({int limit = 6})         => _service.getPopularPlants(limit: limit);
  Future<List<Plant>> getFavorites(String userId)         => _service.getFavoritePlants(userId);
  Future<List<String>> getCategories()                    => _service.getAvailableCategories();

  // ── Recherche IA ───────────────────────────────────────────
  Future<Plant?> findByScientificName(String name)        => _service.findPlantByScientificName(name);
  Future<Plant?> findByCommonName(String name)            => _service.findPlantByCommonName(name);

  // ── Favoris ────────────────────────────────────────────────
  Future<void> toggleFavorite(String userId, String plantId, bool add) =>
      _service.toggleFavorite(userId, plantId, add);

  // ── Historique ─────────────────────────────────────────────
  Future<void> addToHistory({
    required String userId,
    required String plantId,
    required String plantName,
    String? imagePath,
    double? confidenceScore,
  }) => _service.addToHistory(
    userId         : userId,
    plantId        : plantId,
    plantName      : plantName,
    imagePath      : imagePath,
    confidenceScore: confidenceScore,
  );

  Stream<List<Map<String, dynamic>>> watchHistory(String userId) =>
      _service.watchHistory(userId);

  Future<void> clearHistory(String userId) => _service.clearHistory(userId);

  // ── Import dataset ─────────────────────────────────────────
  Future<String> importDataset() => _service.importDatasetToFirestore();
}

// ============================================================
//  PlantaMed — Service Firebase / Firestore
//  Dépendances : cloud_firestore, firebase_core
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plant_model.dart';

class FirebaseService {
  // ── Singleton ──────────────────────────────────────────────
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _plantsCol =>
      _firestore.collection('plantes');
  CollectionReference<Map<String, dynamic>> get _historyCol =>
      _firestore.collection('historique');
  CollectionReference<Map<String, dynamic>> get _favoritesCol =>
      _firestore.collection('favoris');

  // ════════════════════════════════════════════════════════════
  //  IMPORT JSON → FIRESTORE (1 seule fois au 1er lancement)
  // ════════════════════════════════════════════════════════════
  Future<String> importDatasetToFirestore() async {
    try {
      // Vérifier si déjà importé
      final existing = await _plantsCol.limit(1).get();
      if (existing.docs.isNotEmpty) {
        return 'Dataset déjà présent dans Firestore ✅';
      }

      // Charger le JSON depuis assets
      final jsonString = await rootBundle.loadString('assets/data/plants_dataset.json');
      final jsonData   = json.decode(jsonString) as Map<String, dynamic>;
      final plantes    = jsonData['plantes'] as List<dynamic>;

      // Import par batch
      WriteBatch batch = _firestore.batch();
      int count = 0;

      for (int i = 0; i < plantes.length; i++) {
        final plant  = plantes[i] as Map<String, dynamic>;
        final docRef = _plantsCol.doc(plant['id'] as String);
        batch.set(docRef, {
          ...plant,
          'createdAt': FieldValue.serverTimestamp(),
        });
        count++;
        if ((i + 1) % 400 == 0) {
          await batch.commit();
          batch = _firestore.batch();
        }
      }
      await batch.commit();
      return 'Import réussi : $count plantes ✅';
    } catch (e) {
      return 'Erreur import : $e ❌';
    }
  }

  // ════════════════════════════════════════════════════════════
  //  LECTURE DES PLANTES
  // ════════════════════════════════════════════════════════════

  Future<List<Plant>> getAllPlants() async {
    final snap = await _plantsCol.orderBy('nom_commun').get();
    return snap.docs.map((d) => Plant.fromFirestore(d.data(), d.id)).toList();
  }

  Future<Plant?> getPlantById(String id) async {
    final doc = await _plantsCol.doc(id).get();
    if (!doc.exists) return null;
    return Plant.fromFirestore(doc.data()!, doc.id);
  }

  Future<List<Plant>> getPlantsByCategorie(String categorie) async {
    if (categorie == 'Toutes') return getAllPlants();
    final snap = await _plantsCol
        .where('categorie', isEqualTo: categorie)
        .orderBy('nom_commun')
        .get();
    return snap.docs.map((d) => Plant.fromFirestore(d.data(), d.id)).toList();
  }

  Future<List<Plant>> getPopularPlants({int limit = 6}) async {
    final snap = await _plantsCol
        .orderBy('popularite', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => Plant.fromFirestore(d.data(), d.id)).toList();
  }

  Future<List<Plant>> searchPlants(String query) async {
    if (query.trim().isEmpty) return getAllPlants();
    final all = await getAllPlants();
    final q   = query.toLowerCase();
    return all.where((p) =>
      p.nomCommun.toLowerCase().contains(q) ||
      p.nomScientifique.toLowerCase().contains(q) ||
      p.maladiesTraitees.any((m) => m.toLowerCase().contains(q)) ||
      p.vertusTherapeutiques.any((v) => v.toLowerCase().contains(q)) ||
      p.tags.any((t) => t.toLowerCase().contains(q))
    ).toList();
  }

  // ── Recherche pour l'IA ────────────────────────────────────
  Future<Plant?> findPlantByScientificName(String name) async {
    final all   = await getAllPlants();
    final query = name.toLowerCase();
    // Correspondance exacte
    for (final p in all) {
      if (p.nomScientifique.toLowerCase() == query) return p;
    }
    // Correspondance par genre (1er mot)
    final genre = query.split(' ').first;
    for (final p in all) {
      if (p.nomScientifique.toLowerCase().startsWith(genre)) return p;
    }
    return null;
  }

  Future<Plant?> findPlantByCommonName(String name) async {
    final all   = await getAllPlants();
    final query = name.toLowerCase();
    for (final p in all) {
      if (p.nomCommun.toLowerCase().contains(query) ||
          query.contains(p.nomCommun.toLowerCase()) ||
          p.tags.any((t) => t.toLowerCase() == query)) {
        return p;
      }
    }
    return null;
  }

  // ════════════════════════════════════════════════════════════
  //  FAVORIS
  // ════════════════════════════════════════════════════════════

  Future<void> toggleFavorite(String userId, String plantId, bool add) async {
    final docRef = _favoritesCol.doc(userId);
    if (add) {
      await docRef.set({
        'plant_ids': FieldValue.arrayUnion([plantId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await docRef.update({
        'plant_ids': FieldValue.arrayRemove([plantId]),
      });
    }
  }

  Future<List<Plant>> getFavoritePlants(String userId) async {
    final doc = await _favoritesCol.doc(userId).get();
    if (!doc.exists) return [];
    final ids = List<String>.from(doc.data()?['plant_ids'] ?? []);
    if (ids.isEmpty) return [];
    final List<Plant> plants = [];
    for (int i = 0; i < ids.length; i += 10) {
      final chunk = ids.skip(i).take(10).toList();
      final snap  = await _plantsCol
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      plants.addAll(snap.docs.map((d) => Plant.fromFirestore(d.data(), d.id)));
    }
    return plants;
  }

  // ════════════════════════════════════════════════════════════
  //  HISTORIQUE
  // ════════════════════════════════════════════════════════════

  Future<void> addToHistory({
    required String userId,
    required String plantId,
    required String plantName,
    String? imagePath,
    double? confidenceScore,
  }) async {
    await _historyCol.add({
      'user_id'         : userId,
      'plant_id'        : plantId,
      'plant_name'      : plantName,
      'image_path'      : imagePath,
      'confidence_score': confidenceScore,
      'scanned_at'      : FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchHistory(String userId, {int limit = 20}) {
    return _historyCol
        .where('user_id', isEqualTo: userId)
        .orderBy('scanned_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<void> clearHistory(String userId) async {
    final snap  = await _historyCol.where('user_id', isEqualTo: userId).get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ════════════════════════════════════════════════════════════
  //  UTILITAIRES
  // ════════════════════════════════════════════════════════════

  Future<List<String>> getAvailableCategories() async {
    final snap = await _plantsCol.get();
    final cats = snap.docs
        .map((d) => d.data()['categorie'] as String? ?? '')
        .toSet()
        .toList()
      ..sort();
    return ['Toutes', ...cats];
  }
}

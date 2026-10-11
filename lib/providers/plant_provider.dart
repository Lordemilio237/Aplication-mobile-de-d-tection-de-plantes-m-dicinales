// ============================================================
//  PlantaMed — Provider (Firebase Firestore)
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plant_model.dart';
import '../data/plants_data.dart';

class PlantProvider extends ChangeNotifier {

  List<Plant>  _plants           = [];
  final List<Plant>  _favorites        = [];
  List<Plant>  _searchResults    = [];
  List<String> _categories       = [];
  String       _selectedCategory = 'Toutes';
  bool         _isLoading        = false;
  String?      _error;
  String       _searchQuery      = '';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Plant>  get plants           => _plants;
  List<Plant>  get favorites        => _favorites;
  List<Plant>  get searchResults    => _searchResults;
  List<String> get categories       => _categories;
  String       get selectedCategory => _selectedCategory;
  bool         get isLoading        => _isLoading;
  String?      get error            => _error;
  String       get searchQuery      => _searchQuery;
  List<Plant>  get displayedPlants  =>
      _searchQuery.isNotEmpty ? _searchResults : _plants;

  // ════════════════════════════════════════════════════════
  //  IMPORT AUTOMATIQUE : synchronisation locale ↔ Firestore
  // ════════════════════════════════════════════════════════
  Future<void> importPlantsIfNeeded() async {
    try {
      // 1. Récupérer les plantes locales (39 plantes)
      final localPlants = PlantsData.getPlants();
      
      // 2. Vérifier combien il y en a dans Firestore
      final snap = await _firestore.collection('plantes').get();

      // 3. Condition : On importe si c'est vide OU si le nombre a changé
      if (snap.docs.length == localPlants.length) {
        debugPrint('✅ Données déjà à jour (${snap.docs.length} plantes).');
        return; 
      }

      debugPrint('🔄 Synchronisation des données en cours...');
      
      // 4. Utilisation d'un Batch pour tout envoyer d'un coup
      final batch = _firestore.batch();

      for (var plant in localPlants) {
        // On crée un identifiant unique (ID) basé sur le nom scientifique
        // Cela évite les doublons : si la plante existe, elle est mise à jour
        final docRef = _firestore.collection('plantes').doc(
          plant.nomScientifique.replaceAll(' ', '_').toLowerCase(),
        );
        
        batch.set(docRef, plant.toFirestore());
      }

      await batch.commit();
      debugPrint('✅ ${localPlants.length} plantes synchronisées avec succès !');
      
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la synchronisation Firestore : $e');
    }
  }

  // ════════════════════════════════════════════════════════
  //  CHARGEMENT DES PLANTES
  // ════════════════════════════════════════════════════════
  Future<void> loadPlants({String? categorie}) async {
    _setLoading(true);
    try {
      // Essayer Firestore d'abord
      await importPlantsIfNeeded();

      Query<Map<String, dynamic>> query =
          _firestore.collection('plantes').orderBy('nom_commun');

      if (categorie != null && categorie != 'Toutes') {
        query = query.where('categorie', isEqualTo: categorie);
      }

      final snap = await query.get();

      if (snap.docs.isNotEmpty) {
        // ✅ Données Firestore
        _plants = snap.docs
            .map((d) => Plant.fromFirestore(d.data(), d.id))
            .toList();
        debugPrint('✅ ${_plants.length} plantes chargées depuis Firestore');
      } else {
        // 🔄 Fallback : données locales
        _plants = _filterLocal(PlantsData.getPlants(), categorie);
        debugPrint('📱 Données locales utilisées');
      }

      // Charger les catégories
      await _loadCategories();
      _error = null;

    } catch (e) {
      debugPrint('⚠️ Erreur Firestore, fallback local : $e');
      // Fallback données locales si Firestore indisponible
      _plants = _filterLocal(PlantsData.getPlants(), categorie);
      _categories = PlantsData.getCategories();
      _error = null; // Pas d'erreur visible car fallback fonctionne
    } finally {
      _setLoading(false);
    }
  }

  List<Plant> _filterLocal(List<Plant> all, String? categorie) {
    if (categorie != null && categorie != 'Toutes') {
      return all.where((p) => p.categorie == categorie).toList();
    }
    return all;
  }

  Future<void> _loadCategories() async {
    try {
      final snap = await _firestore.collection('plantes').get();
      final cats = snap.docs
          .map((d) => d.data()['categorie'] as String? ?? '')
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      _categories = ['Toutes', ...cats];
    } catch (e) {
      _categories = PlantsData.getCategories();
    }
  }

  // ════════════════════════════════════════════════════════
  //  RECHERCHE
  // ════════════════════════════════════════════════════════
  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    final q   = query.toLowerCase();
    // Recherche dans les plantes déjà chargées
    _searchResults = _plants.where((p) =>
      p.nomCommun.toLowerCase().contains(q)           ||
      p.nomScientifique.toLowerCase().contains(q)     ||
      p.maladiesTraitees.any((m) => m.toLowerCase().contains(q)) ||
      p.vertusTherapeutiques.any((v) => v.toLowerCase().contains(q)) ||
      p.tags.any((t) => t.toLowerCase().contains(q))
    ).toList();

    notifyListeners();
  }

  void clearSearch() {
    _searchQuery   = '';
    _searchResults = [];
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════
  //  FILTRE CATÉGORIE
  // ════════════════════════════════════════════════════════
  Future<void> filterByCategory(String categorie) async {
    _selectedCategory = categorie;
    await loadPlants(categorie: categorie);
  }

  // ════════════════════════════════════════════════════════
  //  FAVORIS (stockage Firestore)
  // ════════════════════════════════════════════════════════
  void toggleFavorite(Plant plant) {
    final idx = _favorites.indexWhere(
        (p) => p.nomScientifique == plant.nomScientifique);

    if (idx == -1) {
      _favorites.add(plant.copyWith(estFavori: true));
    } else {
      _favorites.removeAt(idx);
    }

    final plantIdx = _plants.indexWhere(
        (p) => p.nomScientifique == plant.nomScientifique);
    if (plantIdx != -1) {
      _plants[plantIdx] = plant.copyWith(estFavori: idx == -1);
    }

    notifyListeners();
  }

  bool isFavorite(Plant plant) =>
      _favorites.any((p) => p.nomScientifique == plant.nomScientifique);

  // ════════════════════════════════════════════════════════
  //  UTILITAIRES
  // ════════════════════════════════════════════════════════
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  Plant? getPlantById(String nomScientifique) {
    try {
      return _plants.firstWhere(
          (p) => p.nomScientifique == nomScientifique);
    } catch (_) {
      return null;
    }
  }
}
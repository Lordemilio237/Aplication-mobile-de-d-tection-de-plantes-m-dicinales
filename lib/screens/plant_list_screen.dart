import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plant_provider.dart';
import '../models/plant_model.dart';
import 'plant_detail_screen.dart';
import '../utils/image_helper.dart';

class PlantListScreen extends StatefulWidget {
  const PlantListScreen({super.key});

  @override
  State<PlantListScreen> createState() => _PlantListScreenState();
}

class _PlantListScreenState extends State<PlantListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlantProvider>().loadPlants();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlantProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('🌿 Plantes médicinales',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Barre de recherche ─────────────────────────
          Container(
            color: const Color(0xFF2E7D32),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (q) => provider.search(q),
              decoration: InputDecoration(
                hintText: 'Rechercher une plante, maladie...',
                prefixIcon:
                    const Icon(Icons.search, color: Color(0xFF2E7D32)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.clearSearch();
                        })
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // ── Filtres catégories ─────────────────────────
          if (provider.categories.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                itemCount: provider.categories.length,
                itemBuilder: (_, i) {
                  final cat = provider.categories[i];
                  final selected = provider.selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => provider.filterByCategory(cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF2E7D32)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: const Color(0xFF2E7D32)),
                      ),
                      child: Text(cat,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF2E7D32),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                  );
                },
              ),
            ),

          // ── Compteur ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text(
                  '${provider.displayedPlants.length} plante(s) trouvée(s)',
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),

          // ── Liste ──────────────────────────────────────
          Expanded(
            child: provider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32)))
                : provider.displayedPlants.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 60, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('Aucune plante trouvée',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 16)),
                          ],
                        ))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: provider.displayedPlants.length,
                        itemBuilder: (_, i) => _PlantTile(
                            plant: provider.displayedPlants[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  TUILE PLANTE — corrigée pour Network ET Asset
// ════════════════════════════════════════════════════════════
class _PlantTile extends StatelessWidget {
  final Plant plant;
  const _PlantTile({required this.plant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(
              builder: (_) => PlantDetailScreen(plant: plant))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06), blurRadius: 8)
          ],
        ),
        child: Row(
          children: [
            // ✅ Image intelligente (Network ou Asset)
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12)),
              child: SizedBox(
                width: 90,
                height: 90,
                child: buildPlantImage(plant.imageUrl,
                    height: 90, width: 90),
              ),
            ),

            // Infos
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(plant.nomCommun,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15))),
                      Text(plant.niveauDangerEmoji),
                    ]),
                    Text(plant.nomScientifique,
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(plant.categorie,
                          style: const TextStyle(
                              color: Color(0xFF2E7D32), fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

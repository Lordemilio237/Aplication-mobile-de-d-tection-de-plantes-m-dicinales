import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plant_provider.dart';
import 'plant_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlantProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('❤️ Mes Favoris', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: provider.favorites.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 70, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucun favori pour l\'instant', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Appuie sur ❤️ sur une fiche plante\npour l\'ajouter ici', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.favorites.length,
              itemBuilder: (_, i) {
                final plant = provider.favorites[i];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlantDetailScreen(plant: plant))),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: plant.imageUrl.isNotEmpty
                            ? Image.network(plant.imageUrl, width: 56, height: 56, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: const Color(0xFFE8F5E9), child: const Icon(Icons.eco, color: Color(0xFF4CAF50))))
                            : Container(width: 56, height: 56, color: const Color(0xFFE8F5E9), child: const Icon(Icons.eco, color: Color(0xFF4CAF50))),
                      ),
                      title: Text(plant.nomCommun, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(plant.nomScientifique, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(plant.niveauDangerEmoji),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ]),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

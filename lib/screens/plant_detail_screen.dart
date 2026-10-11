import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plant_model.dart';
import '../providers/plant_provider.dart';

class PlantDetailScreen extends StatelessWidget {
  final Plant plant;
  const PlantDetailScreen({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // ── Image Header ─────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: plant.imageUrl.isNotEmpty
                  ? Image.network(
                      plant.imageUrl, 
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            actions: [
              Consumer<PlantProvider>(
                builder: (context, provider, child) {
                  // Vérifier l'état mis à jour dans le provider
                  final estFavori = provider.isFavorite(plant);
                  return IconButton(
                    icon: Icon(
                      estFavori ? Icons.favorite : Icons.favorite_border, 
                      color: estFavori ? Colors.redAccent : Colors.white,
                    ),
                    onPressed: () {
                      provider.toggleFavorite(plant);
                    },
                  );
                },
              ),
            ],
          ),

          // ── Contenu Principal ─────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Nom + niveau danger
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plant.nomCommun, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                          Text(plant.nomScientifique, style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 15)),
                          Text('Famille : ${plant.famille}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                    _DangerBadge(niveau: plant.niveauDanger, emoji: plant.niveauDangerEmoji),
                  ],
                ),
                const SizedBox(height: 12),

                // Catégorie + Origine
                Wrap(
                  spacing: 8,
                  children: [
                    _Tag(text: plant.categorie, color: const Color(0xFF2E7D32)),
                    _Tag(text: '📍 ${plant.origine}', color: Colors.orange.shade700),
                  ],
                ),
                const SizedBox(height: 20),

                // Description
                _Section(
                  title: '📖 Description',
                  child: Text(plant.description, style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87)),
                ),

                // Vertus thérapeutiques
                if (plant.vertusTherapeutiques.isNotEmpty)
                  _Section(
                    title: '💚 Vertus thérapeutiques',
                    child: Column(
                      children: plant.vertusTherapeutiques
                          .map((v) => _BulletItem(text: v, color: const Color(0xFF2E7D32)))
                          .toList(),
                    ),
                  ),

                // Maladies traitées
                if (plant.maladiesTraitees.isNotEmpty)
                  _Section(
                    title: '🩺 Maladies traitées',
                    child: Wrap(
                      spacing: 8, runSpacing: 6,
                      children: plant.maladiesTraitees
                          .map((m) => _Tag(text: m, color: Colors.blue.shade700))
                          .toList(),
                    ),
                  ),

                // Parties utilisées
                if (plant.partiesUtilisees.isNotEmpty)
                  _Section(
                    title: '🌱 Parties utilisées',
                    child: Wrap(
                      spacing: 8, runSpacing: 6,
                      children: plant.partiesUtilisees
                          .map((p) => _Tag(text: p, color: Colors.brown.shade600))
                          .toList(),
                    ),
                  ),

                // Modes d'utilisation
                if (plant.modesUtilisation.isNotEmpty)
                  _Section(
                    title: '⚗️ Modes d\'utilisation',
                    child: Column(
                      children: plant.modesUtilisation
                          .map((m) => _BulletItem(text: m, color: Colors.blue))
                          .toList(),
                    ),
                  ),

                // Posologie
                if (plant.posologie.isNotEmpty)
                  _Section(
                    title: '💊 Posologie',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(plant.posologie, style: const TextStyle(fontSize: 14, height: 1.6)),
                    ),
                  ),

                // Précautions
                if (plant.precautions.isNotEmpty)
                  _Section(
                    title: '⚠️ Précautions',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: plant.precautions
                            .map((p) => _BulletItem(text: p, color: Colors.orange.shade800))
                            .toList(),
                      ),
                    ),
                  ),

                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        color: const Color(0xFFE8F5E9),
        child: const Center(child: Icon(Icons.eco, size: 80, color: Color(0xFF4CAF50))),
      );
}

// ── Widgets réutilisables internes ───────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 20),
      ],
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  final Color color;
  const _BulletItem({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: Icon(Icons.circle, size: 6, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}

class _DangerBadge extends StatelessWidget {
  final String niveau;
  final String emoji;
  const _DangerBadge({required this.niveau, required this.emoji});

  Color get _color {
    switch (niveau.toLowerCase().trim()) {
      case 'sûr':
      case 'sur':
        return Colors.green;
      case 'modéré':
      case 'modere':
        return Colors.orange;
      case 'attention':
      case 'dangereux':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          Text(niveau, style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
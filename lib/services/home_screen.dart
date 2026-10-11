import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importations absolues et sécurisées pour le projet 'plantamed'
import 'package:plantamed/models/plant_model.dart';
import 'package:plantamed/providers/plant_provider.dart';

// Importations absolues et sécurisées de tous les écrans
import 'package:plantamed/screens/plant_list_screen.dart';
import 'package:plantamed/screens/scan_screen.dart';
import 'package:plantamed/screens/favorites_screen.dart';
import 'package:plantamed/screens/plant_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Liste des écrans gérés par la NavigationBar
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    
    // Initialisation de la liste des écrans
    _screens = [
      _HomeTab(onScanPressed: () => setState(() => _currentIndex = 2)),
      const PlantListScreen(),
      const ScanScreen(),
      const FavoritesScreen(),
    ];

    // Charger les plantes depuis la base de données au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PlantProvider>().loadPlants();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: const Color(0xFF2E7D32).withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined), 
            selectedIcon: Icon(Icons.home, color: Color(0xFF2E7D32)), 
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_florist_outlined), 
            selectedIcon: Icon(Icons.local_florist, color: Color(0xFF2E7D32)), 
            label: 'Plantes',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined), 
            selectedIcon: Icon(Icons.camera_alt, color: Color(0xFF2E7D32)), 
            label: 'Scanner',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline), 
            selectedIcon: Icon(Icons.favorite, color: Color(0xFF2E7D32)), 
            label: 'Favoris',
          ),
        ],
      ),
    );
  }
}

// ── Onglet Accueil ─────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final VoidCallback onScanPressed;

  const _HomeTab({required this.onScanPressed});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlantProvider>();

    // Extraction sécurisée des 6 premières plantes pour le carrousel horizontal
    final popularPlants = provider.plants.take(6).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // ── AppBar Animée ───────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                '🌿 PlantaMed', 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              centerTitle: false,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Icon(Icons.eco, size: 60, color: Colors.white70),
                      const SizedBox(height: 8),
                      Text(
                        'Détection intelligente de plantes médicinales',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Bouton Scanner ───────────────────────
                _ScanButton(onPressed: onScanPressed),
                const SizedBox(height: 24),

                // ── Plantes populaires ───────────────────
                const Text(
                  '🌱 Plantes populaires', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                if (provider.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
                  )
                else if (popularPlants.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(child: Text('Aucune plante disponible', style: TextStyle(color: Colors.grey))),
                  )
                else
                  SizedBox(
                    height: 185,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: popularPlants.length,
                      itemBuilder: (ctx, i) => _PlantCard(plant: popularPlants[i]),
                    ),
                  ),

                const SizedBox(height: 24),

                // ── Statistiques ────────────────────────────────
                _StatsRow(count: provider.plants.length),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bouton Scanner ─────────────────────────────────────────
class _ScanButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ScanButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3), 
              blurRadius: 12, 
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, color: Colors.white, size: 32),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scanner une plante', 
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Prends une photo pour l\'identifier', 
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Carte plante horizontale ───────────────────────────────
class _PlantCard extends StatelessWidget {
  final Plant plant;
  const _PlantCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (_) => PlantDetailScreen(plant: plant),
        ),
      ),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12, bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08), 
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: plant.imageUrl.isNotEmpty
                  ? Image.network(
                      plant.imageUrl, 
                      height: 100, 
                      width: 140, 
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _plantPlaceholder(),
                    )
                  : _plantPlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.nomCommun.isNotEmpty ? plant.nomCommun : 'Inconnu', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    plant.nomScientifique, 
                    style: const TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic), 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plant.niveauDangerEmoji, 
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _plantPlaceholder() => Container(
        height: 100, 
        width: 140, 
        color: const Color(0xFFE8F5E9),
        child: const Icon(Icons.eco, size: 40, color: Color(0xFF4CAF50)),
      );
}

// ── Statistiques ───────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int count;
  const _StatsRow({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(icon: Icons.eco, label: 'Plantes', value: '$count'),
        const SizedBox(width: 12),
        const _StatCard(icon: Icons.category, label: 'Catégories', value: '9'),
        const SizedBox(width: 12),
        const _StatCard(icon: Icons.bolt, label: 'IA Hybride', value: 'Offline'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF2E7D32), size: 24),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
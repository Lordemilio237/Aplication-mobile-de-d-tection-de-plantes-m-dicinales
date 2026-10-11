import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plant_provider.dart';
import 'plant_list_screen.dart';
import 'scan_screen.dart';
import 'favorites_screen.dart';
import 'plant_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _HomeTab(),
    PlantListScreen(),
    ScanScreen(),
    FavoritesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Charger les plantes au démarrage pour s'assurer que les données sont fraîches
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlantProvider>().loadPlants();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        elevation: 10,
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
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlantProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // ── AppBar avec Gradient ──────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('🌿 PlantaMed',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
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
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8), fontSize: 13),
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
                _ScanButton(),
                const SizedBox(height: 24),

                // ── Plantes populaires ───────────────────
                const Text('🌱 Plantes populaires',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                if (provider.isLoading)
                  const SizedBox(
                    height: 180,
                    child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF2E7D32))),
                  )
                else if (provider.plants.isEmpty)
                  const SizedBox(
                    height: 180,
                    child: Center(child: Text("Aucune plante disponible")),
                  )
                else
                  SizedBox(
                    height: 200, // Augmenté pour éviter les débordements
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: provider.plants.take(10).length,
                      itemBuilder: (ctx, i) =>
                          _PlantCard(plant: provider.plants[i]),
                    ),
                  ),

                const SizedBox(height: 24),

                // ── Statistiques ────────────────────────────────
                const Text('📊 Aperçu de la base',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _StatsRow(count: provider.plants.length),
                const SizedBox(height: 30),
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
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ScanScreen())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4))
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
                Text('Scanner une plante',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text('Prends une photo pour l\'identifier',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Carte plante horizontale (CORRIGÉE) ───────────────────────────────
class _PlantCard extends StatelessWidget {
  final dynamic plant;
  const _PlantCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PlantDetailScreen(plant: plant))),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: _buildPlantImage(plant.imageUrl),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plant.nomCommun ?? "Inconnu",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(plant.nomScientifique ?? "",
                      style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  // On vérifie si niveauDangerEmoji existe, sinon on met un check vert
                  Text(plant.niveauDangerEmoji ?? "✅",
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LOGIQUE DE CORRECTION DES IMAGES ---
  Widget _buildPlantImage(String url) {
    if (url.isEmpty) return _plantPlaceholder();

    // Si l'URL commence par http, on utilise Image.network
    if (url.startsWith('http')) {
      return Image.network(
        url,
        height: 100,
        width: 150,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _plantPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 100,
            width: 150,
            color: Colors.grey[200],
            child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        },
      );
    } 
    // Sinon, on considère que c'est un asset local
    else {
      return Image.asset(
        url,
        height: 100,
        width: 150,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _plantPlaceholder(),
      );
    }
  }

  Widget _plantPlaceholder() => Container(
        height: 100,
        width: 150,
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
        const _StatCard(icon: Icons.camera_alt, label: 'IA Ready', value: '✅'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)
          ],
        ),
        child: Column(children: [
          Icon(icon, color: const Color(0xFF2E7D32), size: 24),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ]),
      ),
    );
  }
}
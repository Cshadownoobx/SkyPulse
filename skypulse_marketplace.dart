import 'package:flutter/material.dart';
import 'dart:ui';

/// SkyPulse Clean UI 2.0 - Flutter/Dart Port
/// Translating the high-contrast, border-less HTML/CSS into native Flutter code.

void main() {
  runApp(const SkyPulseApp());
}

class SkyPulseApp extends StatelessWidget {
  const SkyPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkyPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF020617), // Deep Slate
        fontFamily: 'Inter', // Standard modern font
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6366f1), // Indigo
          secondary: const Color(0xFFf43f5e), // Rose
          surface: const Color(0x990f172a), // Glass Panel BG
        ),
      ),
      home: const SkyPulseDashboard(),
    );
  }
}

class SkyPulseDashboard extends StatefulWidget {
  const SkyPulseDashboard({super.key});

  @override
  State<SkyPulseDashboard> createState() => _SkyPulseDashboardState();
}

class _SkyPulseDashboardState extends State<SkyPulseDashboard> {
  String _currentTab = 'deals';
  bool _isSearching = false;

  void _switchTab(String tab) {
    setState(() {
      _currentTab = tab;
      // Reset search state when leaving package deals to demonstrate the dynamic layout
      if (tab != 'booking') {
        _isSearching = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Determine the animated width of our main panel.
    // If we are in the 'booking' tab (Package Deals), expand to 100vw!
    final bool isFullScreen = _currentTab == 'booking';
    final double panelWidth = isFullScreen ? screenWidth : 600.0;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient to replicate the radial CSS gradients
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF020617),
                    Color(0xFF000000), // Dark base
                  ],
                ),
              ),
            ),
          ),
          
          // Simulated Map Frame in the background
          Positioned.fill(
            child: Row(
              children: [
                SizedBox(width: isFullScreen ? screenWidth : 600.0), // Spacer for sidebar
                Expanded(
                  child: Container(
                    color: Colors.blueGrey.shade900,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_outlined, size: 100, color: Colors.white24),
                          SizedBox(height: 16),
                          Text(
                            "ADSB Global Flight Radar Map",
                            style: TextStyle(color: Colors.white54, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // The Animated Glass Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.fastOutSlowIn,
            width: panelWidth,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 60,
                  offset: const Offset(20, 0),
                )
              ],
            ),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBrandHeader(),
                      const SizedBox(height: 24),
                      _buildTabBar(),
                      const SizedBox(height: 24),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _buildActiveTabContent(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text("✈", style: TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          "SkyPulse",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
          ),
        ),
        const Spacer(),
        if (_currentTab != 'booking') 
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.withOpacity(0.5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Colors.redAccent, size: 10),
                SizedBox(width: 6),
                Text("LIVE API", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent)),
              ],
            ),
          )
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, inset: true)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _TabButton(
            title: "Deals",
            isActive: _currentTab == 'deals',
            onTap: () => _switchTab('deals'),
          ),
          _TabButton(
            title: "Profile 👤",
            isActive: _currentTab == 'profile',
            onTap: () => _switchTab('profile'),
          ),
          _TabButton(
            title: "Package Deals 🌴",
            isActive: _currentTab == 'booking',
            onTap: () => _switchTab('booking'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_currentTab) {
      case 'deals':
        return _buildDealsTab();
      case 'profile':
        return const Center(child: Text("Profile Management"));
      case 'booking':
        return _buildMarketplaceTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDealsTab() {
    return ListView(
      children: [
        const Text("🔥 Live Route Monitoring", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _GlassCard(child: const ListTile(title: Text("LHR ➔ DXB"), subtitle: Text("Trending · \$350 Drops"))),
        const SizedBox(height: 12),
        _GlassCard(child: const ListTile(title: Text("JFK ➔ LHR"), subtitle: Text("Hot Route · \$210 Deals"))),
      ],
    );
  }

  // MARK: - The Full-Screen Marketplace
  Widget _buildMarketplaceTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal Search Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.05), Colors.transparent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 40)],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(flex: 2, child: _buildSearchInput("Departure Hub", "LHR")),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text("⇄", style: TextStyle(color: Colors.white54, fontSize: 20)),
              ),
              Expanded(flex: 2, child: _buildSearchInput("Arrival Hub", "DXB")),
              const SizedBox(width: 16),
              Expanded(flex: 1, child: _buildSearchInput("Depart", "12 Nov")),
              const SizedBox(width: 16),
              Expanded(flex: 1, child: _buildSearchInput("Return", "20 Nov")),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: () => setState(() => _isSearching = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366f1), Color(0xFFf43f5e)], // Indigo to Rose
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF6366f1).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    child: const Text("SEARCH", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Marketplace Content
        Expanded(
          child: _isSearching ? _buildDynamicMarketplaceInject() : _buildCuratedAsianPackages(),
        ),
      ],
    );
  }

  Widget _buildSearchInput(String label, String placeholder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54)),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: Colors.black45,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  // Pre-Search: Curated Asian Packages
  Widget _buildCuratedAsianPackages() {
    return ListView(
      children: [
        const Text("🌴 Curated Asian Package Deals", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 1.5,
          children: [
            _buildPackageCard("Bali, Indonesia", "POPULAR", "£849", "Flights + 7 Nights 5★ Resort", Colors.teal),
            _buildPackageCard("Phuket, Thailand", "HOT DEAL", "£799", "Flights + 10 Nights Beach Villa", Colors.pinkAccent),
            _buildPackageCard("Kuala Lumpur", "PREMIUM", "£949", "Flights + 14 Nights Twin Center", Colors.indigo),
          ],
        ),
        const SizedBox(height: 48),
        const Text("🤝 SkyPulse Premium Travel Partners", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildPartnerBox("Qatar Airways", "Official Qsuite Partner")),
            const SizedBox(width: 16),
            Expanded(child: _buildPartnerBox("Marriott Bonvoy", "Exclusive Resort Rates")),
            const SizedBox(width: 16),
            Expanded(child: _buildPartnerBox("Emirates", "A380 First Class Access")),
          ],
        )
      ],
    );
  }

  // Post-Search: The Massive Marketplace Insights
  Widget _buildDynamicMarketplaceInject() {
    return ListView(
      children: [
        const Text("🌍 SkyPulse Marketplace Insights for DXB", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 32),
        
        const Text("✈️ Top Flight Connectivity", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _GlassCard(
          child: ListTile(
            leading: const Text("✈️", style: TextStyle(fontSize: 24)),
            title: const Text("Emirates EK100", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("12h 30m · Direct"),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Text("£450", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text("Per Passenger", style: TextStyle(fontSize: 10, color: Colors.white54)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),
        const Text("🏨 Premium & Budget Apartments", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 1.5,
          children: [
            _buildPackageCard("Beachfront Villa", "★★★★★", "£120", "Entire Home · 6 Guests", Colors.cyan),
            _buildPackageCard("Downtown Loft", "★★★★", "£75", "1 Bedroom · 2 Guests", Colors.cyan),
            _buildPackageCard("Sunset Boutique", "★★★★★", "£210", "Private Suite · Spa", Colors.cyan),
          ],
        ),

        const SizedBox(height: 32),
        const Text("🏄‍♂️ Experiences & Activities", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 1.5,
          children: [
            _buildPackageCard("Deep Sea Scuba", "5 HOURS", "£85", "PADI Certified Guide", Colors.amber),
            _buildPackageCard("Helicopter Tour", "VIP", "£299", "45 Minutes · Champagne", Colors.amber),
            _buildPackageCard("Street Food Safari", "NIGHT", "£45", "8 Tastings · Hosted", Colors.amber),
          ],
        ),
      ],
    );
  }

  // --- Helpers ---

  Widget _buildPackageCard(String title, String badge, String price, String desc, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border(bottom: BorderSide(color: accentColor.withOpacity(0.5), width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: accentColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(badge, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 10)),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(price, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.white),
                onPressed: () {},
                child: const Text("VIEW", style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPartnerBox(String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 12, color: Colors.white54)),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({required this.title, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isActive ? [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))] : [],
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: child,
    );
  }
}

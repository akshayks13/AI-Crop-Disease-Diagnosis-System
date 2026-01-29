import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredCommodities = [];

  final List<Map<String, dynamic>> _allCommodities = [
    {'name': 'Tomato', 'price': 2500, 'unit': 'Quintal', 'trend': 'up', 'change': '+5%', 'location': 'Kolar Mandi'},
    {'name': 'Potato', 'price': 1800, 'unit': 'Quintal', 'trend': 'down', 'change': '-2%', 'location': 'Hassan Mandi'},
    {'name': 'Onion', 'price': 3200, 'unit': 'Quintal', 'trend': 'up', 'change': '+8%', 'location': 'Yeshwanthpur'},
    {'name': 'Green Chilli', 'price': 4500, 'unit': 'Quintal', 'trend': 'stable', 'change': '0%', 'location': 'Chikkaballapur'},
    {'name': 'Wheat', 'price': 2100, 'unit': 'Quintal', 'trend': 'up', 'change': '+1%', 'location': 'Belgaum'},
    {'name': 'Rice (Sona Masoori)', 'price': 4800, 'unit': 'Quintal', 'trend': 'down', 'change': '-1.5%', 'location': 'Raichur'},
    {'name': 'Cotton', 'price': 6200, 'unit': 'Quintal', 'trend': 'up', 'change': '+3%', 'location': 'Haveri'},
    {'name': 'Maize', 'price': 1950, 'unit': 'Quintal', 'trend': 'stable', 'change': '0%', 'location': 'Davangere'},
    {'name': 'Tur Dal', 'price': 8500, 'unit': 'Quintal', 'trend': 'up', 'change': '+10%', 'location': 'Kalaburagi'},
    {'name': 'Groundnut', 'price': 5600, 'unit': 'Quintal', 'trend': 'down', 'change': '-4%', 'location': 'Chitradurga'},
  ];

  @override
  void initState() {
    super.initState();
    _filteredCommodities = _allCommodities;
    _searchController.addListener(_filterCommodities);
  }

  void _filterCommodities() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCommodities = _allCommodities.where((item) {
        return item['name'].toString().toLowerCase().contains(query) ||
               item['location'].toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Accessing theme data
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Prices'),
      ),
      body: Column(
        children: [
          // Search Bar Area
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen, // Changed to Green for high visibility
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26, 
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search crop or mandi...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white, // White box on Green background
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
          
          // Commodity List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _filteredCommodities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = _filteredCommodities[index];
                return _buildPriceCard(item, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(Map<String, dynamic> item, ThemeData theme) {
    final bool isUp = item['trend'] == 'up';
    final bool isDown = item['trend'] == 'down';
    
    // Using standard financial colors, but consistent nicely with the theme
    final Color trendColor = isUp 
        ? AppTheme.primaryGreen 
        : (isDown ? AppTheme.errorRed : Colors.grey);
    
    final Color trendBg = trendColor.withOpacity(0.1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Crop Icon / Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryGreen.withOpacity(0.2),
                  AppTheme.secondaryGreen.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                item['name'][0],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Crop Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: theme.colorScheme.secondary),
                    const SizedBox(width: 4),
                    Text(
                      item['location'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Price & Trend
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${item['price']}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trendBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUp ? Icons.trending_up : (isDown ? Icons.trending_down : Icons.trending_flat),
                      size: 16,
                      color: trendColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item['change'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

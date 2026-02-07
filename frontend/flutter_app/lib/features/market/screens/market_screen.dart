import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/market_provider.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marketState = ref.watch(marketProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Prices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(marketProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.scaffoldBackgroundColor, // Seamless with body
            child: TextField(
              controller: _searchController,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search Crop or Location (Eg: Tomato, Kolar)',
                hintStyle: TextStyle(
                  color: theme.hintColor,
                  fontSize: 14,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.never,
                prefixIcon: Icon(Icons.search, color: theme.hintColor),
                filled: true,
                fillColor: theme.cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              onChanged: (value) {
                ref.read(marketProvider.notifier).setSearchQuery(value);
              },
            ),
          ),

          // 📊 PRICE LIST
          Expanded(
            child: marketState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : marketState.error != null
                    ? _buildErrorWidget(marketState.error!)
                    : marketState.filteredPrices.isEmpty
                        ? _buildEmptyWidget()
                        : RefreshIndicator(
                            onRefresh: () =>
                                ref.read(marketProvider.notifier).refresh(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount:
                                  marketState.filteredPrices.length,
                              itemBuilder: (context, index) {
                                final price =
                                    marketState.filteredPrices[index];
                                return _buildPriceCard(price);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // 🧾 PRICE CARD
  Widget _buildPriceCard(MarketPrice price) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final isUp = price.trend == 'up';
    final isDown = price.trend == 'down';
    
    // Use theme colors where appropriate, but keep semantic meaning for up/down
    final trendColor =
        isUp ? Colors.green : (isDown ? colorScheme.error : Colors.grey);
    final trendIcon =
        isUp ? Icons.arrow_upward : (isDown ? Icons.arrow_downward : Icons.remove);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 🌱 ICON
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: _buildCommodityImage(price.commodity),
              ),
            ),
            const SizedBox(width: 16),

            // 📝 DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    price.commodity,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 14, color: theme.textTheme.bodySmall?.color),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          price.location,
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 💰 PRICE
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${price.price.toStringAsFixed(0)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  '/${price.unit}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendIcon,
                          size: 14, color: trendColor),
                      const SizedBox(width: 4),
                      Text(
                        price.changeString,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildCommodityImage(String commodity) {
  final imagePath = _getCommodityImagePath(commodity);

  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.asset(
      imagePath,
      width: 36,
      height: 36,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.agriculture,
          size: 28,
          color: Theme.of(context).colorScheme.primary,
        );
      },
    ),
  );
}

String _getCommodityImagePath(String commodity) {
  final lower = commodity.toLowerCase();

   if (lower.contains('tomato')) return 'assets/crops/tomato.png';
  if (lower.contains('potato')) return 'assets/crops/potato.jpg';
  if (lower.contains('onion')) return 'assets/crops/onion.jpg';
  if (lower.contains('wheat')) return 'assets/crops/wheat.jpg';
  if (lower.contains('rice')) return 'assets/crops/rice_sona_masoori.jpg';
  if (lower.contains('cotton')) return 'assets/crops/cotton.jpg';
  if (lower.contains('maize') || lower.contains('corn')) {
    return 'assets/crops/maize.jpg';
  }
  if (lower.contains('green chilli')) {
    return 'assets/crops/green_chilli.jpg';
  }
  if (lower.contains('red chilli')) {
    return 'assets/crops/red_chilli.jpg';
  }
  if (lower.contains('groundnut') || lower.contains('peanut')) {
    return 'assets/crops/groundnut.jpg';
  }
  if (lower.contains('tur') || lower.contains('dal')) {
    return 'assets/crops/tur_dal.jpg';
  }

  return 'assets/crops/default.jpg';
}


  // ❌ ERROR UI
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 64, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Failed to load prices',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () =>
                ref.read(marketProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // 📭 EMPTY UI
  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 64, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          Text(
            'No market prices found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

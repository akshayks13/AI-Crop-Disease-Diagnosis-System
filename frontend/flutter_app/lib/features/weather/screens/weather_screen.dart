import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WeatherService _weatherService = WeatherService();
  
  WeatherData? _currentWeather;
  List<ForecastData> _forecast = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWeather();
  }

  Future<void> _loadWeather([String? cityName]) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final weather = cityName == null 
          ? await _weatherService.getCurrentWeather()
          : await _weatherService.getCityWeather(cityName);
      
      // Only fetch forecast if getting by location (for now api doesn't support free forecast by city neatly without lat/lon, 
      // but if we have weather we can get lat/lon from it to get forecast)
      // For simplicity in this iteration, we might just fetch forecast based on location
       List<ForecastData> forecast = [];
       try {
         // If we searched by city, we could use the coord from weather, but let's stick to current location forecast or 
         // implement lat/lon support in service for forecast. 
         // Current service uses current location for forecast. 
         forecast = await _weatherService.getHourlyForecast();
       } catch (e) {
         // Forecast might fail if location permission denied but city search worked. Ignore for now.
         debugPrint('Forecast error: $e');
       }

      setState(() {
        _currentWeather = weather;
        _forecast = forecast;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showSearchDialog() {
    final TextEditingController searchCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Search City'),
        content: TextField(
          controller: searchCtrl,
          decoration: const InputDecoration(hintText: 'Enter city name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (searchCtrl.text.isNotEmpty) {
                _loadWeather(searchCtrl.text);
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Forecast'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () => _loadWeather(),
          ),
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            onPressed: () => Navigator.pushNamed(context, '/chat'),
            tooltip: 'Ask AI',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryGreen,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Hourly'), // Changed text to reflect data better
          ],
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_errorMessage', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _loadWeather(),
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTodayWeather(theme),
                    _buildForecastList(theme),
                  ],
                ),
    );
  }

  Widget _buildTodayWeather(ThemeData theme) {
    if (_currentWeather == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Current Main Weather Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: _getBackgroundGradient(_currentWeather!.description),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded( // Added Expanded to prevent overflow
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentWeather!.cityName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis, // Safe
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, d MMM').format(_currentWeather!.date),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8), // Spacing
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('Current', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Image.network(
                       'https://openweathermap.org/img/wn/${_currentWeather!.iconCode}@2x.png', // Fixed interpolation
                       width: 64,
                       height: 64,
                       errorBuilder: (_,__,___) => const Icon(Icons.wb_sunny, size: 64, color: AppTheme.warningYellow),
                     ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_currentWeather!.temp.round()}°C', // Fixed interpolation
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _currentWeather!.description.toUpperCase(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _weatherDetailItem(Icons.water_drop, 'Humidity', '${_currentWeather!.humidity}%', theme),
                    _weatherDetailItem(Icons.air, 'Wind', '${_currentWeather!.windSpeed} km/h', theme),
                    _weatherDetailItem(Icons.thermostat, 'Feels Like', '${_currentWeather!.temp.round()}°', theme),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Crop Advisory Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.secondaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.tips_and_updates, color: AppTheme.primaryGreen, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Farming Tip',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getFarmingTip(_currentWeather!),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Hourly Forecast (Horizontal Scroll)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Next 24 Hours',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _forecast.length > 8 ? 8 : _forecast.length, // Show next 8 items (3h * 8 = 24h)
              itemBuilder: (context, index) {
                final item = _forecast[index];
                final isNow = index == 0;
                return _hourlyItem(item, isNow, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastList(ThemeData theme) {
    if (_forecast.isEmpty) {
      return const Center(child: Text("No forecast available"));
    }
    // Simple list view of the 3-hour forecast for next 5 days
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _forecast.length,
      itemBuilder: (context, index) {
        final item = _forecast[index];
        final dayName = DateFormat('EEE, MMM d').format(item.dt);
        final time = DateFormat('h:mm a').format(item.dt);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayName,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      time,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Image.network(
                'https://openweathermap.org/img/wn/${item.icon}@2x.png', // Fixed interpolation
                width: 40,
                height: 40,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '${item.temp.round()}°C', // Fixed interpolation
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Flexible( // Use Flexible to allow description to shrink if needed
                child: Text(
                  item.description,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _weatherDetailItem(IconData icon, String label, String value, ThemeData theme) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _hourlyItem(ForecastData item, bool isSelected, ThemeData theme) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryGreen : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? null : Border.all(color: Colors.grey.shade200),
        boxShadow: isSelected ? [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('h a').format(item.dt),
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Image.network(
              'https://openweathermap.org/img/wn/${item.icon}.png', // Fixed interpolation
              width: 32,
              height: 32,
          ),
          const SizedBox(height: 8),
          Text(
            '${item.temp.round()}°', // Fixed interpolation
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getBackgroundGradient(String description) {
    // Basic mapping based on description keywords
    description = description.toLowerCase();
    if (description.contains('rain')) {
      return LinearGradient(
        colors: [Colors.grey.shade700, Colors.blue.shade900],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (description.contains('cloud')) {
      return LinearGradient(
        colors: [Colors.blueGrey.shade300, Colors.blueGrey.shade600],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (description.contains('clear') || description.contains('sun')) {
       return LinearGradient(
         colors: [Colors.orange.shade400, Colors.blue.shade400],
         begin: Alignment.topLeft,
         end: Alignment.bottomRight,
       );
    }
    // Default
    return LinearGradient(
      colors: [Colors.blue.shade400, Colors.blue.shade800],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  String _getFarmingTip(WeatherData weather) {
    if (weather.humidity > 80) return "High humidity risks fungal diseases. Monitor crops closely.";
    if (weather.temp > 35) return "High heat stress likely. Ensure adequate irrigation.";
    if (weather.description.contains('rain')) return "Avoid spraying pesticides during rain.";
    if (weather.windSpeed > 15) return "Avoid spraying operations; wind drift is high.";
    return "Conditions are good for general field work.";
  }
}


// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/stockdata.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _symbolController = TextEditingController();
  final TextEditingController _periodController = TextEditingController(); 
  final ApiService _apiService = ApiService();
  
  // UI State
  bool _isLoading = false;
  bool _isBackendChecking = true;
  bool _isBackendAvailable = false;
  String? _errorMessage;
  AnalysisResult? _result;
  
  // Chart state
  bool _showVolume = false;
  
  @override
  void initState() {
    super.initState();
    _checkBackend();
  }
  
  @override
  void dispose() {
    _symbolController.dispose();
    super.dispose();
  }
  
  Future<void> _checkBackend() async {
    setState(() {
      _isBackendChecking = true;
    });
    
    final isAvailable = await _apiService.checkBackendHealth();
    
    setState(() {
      _isBackendAvailable = isAvailable;
      _isBackendChecking = false;
      if (!isAvailable) {
        _errorMessage = 'Backend service not running. Please start the Python backend first.';
      }
    });
  }
  
  Future<void> _analyzeStock() async {
    final symbol = _symbolController.text.trim().toUpperCase();
    final symbol = _periodController.text.trim().toLowerCase();  
    if (symbol.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a stock symbol (e.g., AAPL, TSLA, MSFT)';
      });
      return;
    }
    if (period.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a time period (e.g., 1mo 6mo)';
      });
      return;
    }    
    if (!_isBackendAvailable) {
      setState(() {
        _errorMessage = 'Backend is not available. Please check your connection.';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });
    
    try {
      final result = await _apiService.analyzeStock(symbol,period);
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DeepSeek Stock Analyzer'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          // Backend status indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  _isBackendAvailable ? Icons.check_circle : Icons.error,
                  color: _isBackendAvailable ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _isBackendChecking ? 'Checking...' : (_isBackendAvailable ? 'Backend OK' : 'Backend Offline'),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    // Backend checking state
    if (_isBackendChecking) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking backend connection...'),
            SizedBox(height: 8),
            Text(
              'Make sure Python backend is running: python app.py',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Input section
          _buildInputSection(),
          const SizedBox(height: 20),
          
          // Main content
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : _result != null
                        ? _buildResultState()
                        : _buildEmptyState(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInputSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column (
          children: [ 
		  //add period textfield
            Expanded(
              child: TextField(
                controller: _symbolController,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Enter stock symbol (e.g., AAPL)',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => _analyzeStock(),
              ),
            ),
			
			SizedBox(height: 16), // Add spacing between fields
			
			Expanded(
              child: TextField(
                controller: _periodController,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'enter time period(e.g.， 6mo)',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => _analyzeStock(),
              ),
            ),

			SizedBox(height: 16), // Add spacing between fields
            //const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _analyzeStock,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.analytics),
              label: const Text('Analyze'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Fetching data and generating AI analysis...'),
          SizedBox(height: 8),
          Text(
            'This may take 10-20 seconds',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _analyzeStock,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _checkBackend,
            icon: const Icon(Icons.settings, size: 16),
            label: const Text('Check Backend Status'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Enter a stock symbol to analyze',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Powered by Yahoo Finance & DeepSeek AI',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultState() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stock info card
          _buildInfoCard(),
          const SizedBox(height: 16),
          
          // Chart toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Price Chart',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ToggleButtons(
                isSelected: [!_showVolume, _showVolume],
                onPressed: (index) {
                  setState(() {
                    _showVolume = index == 1;
                  });
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Price'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Volume'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildChartCard(),
          const SizedBox(height: 16),
          
          // Technical indicators
          _buildIndicatorsCard(),
          const SizedBox(height: 16),
          
          // Support/Resistance
          _buildSupportResistanceCard(),
          const SizedBox(height: 16),
          
          // Patterns
          if (_result!.patterns.isNotEmpty) _buildPatternsCard(),
          if (_result!.patterns.isNotEmpty) const SizedBox(height: 16),
          
          // AI Analysis
          _buildAnalysisCard(),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard() {
    final price = _result!.indicators['Current_Price'] ?? 0.0;
    final change = price - (_result!.data.isNotEmpty ? _result!.data.last.close : price);
    final changePercent = _result!.data.isNotEmpty 
        ? ((change / _result!.data.last.close) * 100) 
        : 0.0;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _result!.symbol,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Last updated: ${DateFormat('HH:mm:ss').format(_result!.timestamp)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: change >= 0 ? Colors.green.shade100 : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${change >= 0 ? '+' : ''}\$${change.abs().toStringAsFixed(2)} (${changePercent.toStringAsFixed(2)}%)',
                        style: TextStyle(
                          color: change >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (price - (_result!.supportResistance['nearest_support'] ?? price - 10)) /
                  ((_result!.supportResistance['nearest_resistance'] ?? price + 10) - 
                   (_result!.supportResistance['nearest_support'] ?? price - 10)),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(Colors.blue.shade700),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Support: \$${_result!.supportResistance['nearest_support']?.toStringAsFixed(2) ?? 'N/A'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  'Resistance: \$${_result!.supportResistance['nearest_resistance']?.toStringAsFixed(2) ?? 'N/A'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildChartCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 300,
          child: _showVolume 
              ? _buildVolumeChart() 
              : _buildPriceChart(),
        ),
      ),
    );
  }
  
  Widget _buildPriceChart() {
    final spots = <FlSpot>[];
    final prices = _result!.data.map((d) => d.close).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    
    for (int i = 0; i < _result!.data.length; i++) {
      spots.add(FlSpot(i.toDouble(), _result!.data[i].close));
    }
    
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue.shade700,
            barWidth: 2,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.shade100.withOpacity(0.3),
            ),
            dotData: const FlDotData(show: false),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 40,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 20 == 0 && value.toInt() < _result!.data.length) {
                  return Text(
                    DateFormat('MM/dd').format(_result!.data[value.toInt()].date),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: (maxPrice - minPrice) / 5,
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: _result!.data.length - 1,
        minY: minPrice - (maxPrice - minPrice) * 0.1,
        maxY: maxPrice + (maxPrice - minPrice) * 0.1,
      ),
    );
  }
  
  Widget _buildVolumeChart() {
    final bars = <BarChartGroupData>[];
    
    for (int i = 0; i < _result!.data.length; i++) {
      final volume = _result!.data[i].volume;
      final maxVolume = _result!.data.map((d) => d.volume).reduce((a, b) => a > b ? a : b);
      
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: volume.toDouble(),
              color: Colors.blue.shade300,
              width: 5,
            ),
          ],
        ),
      );
    }
    
    return BarChart(
      BarChartData(
        barGroups: bars,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value >= 1000000) {
                  return Text('${(value / 1000000).toStringAsFixed(0)}M');
                } else if (value >= 1000) {
                  return Text('${(value / 1000).toStringAsFixed(0)}K');
                }
                return Text(value.toStringAsFixed(0));
              },
              reservedSize: 50,
            ),
          ),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
  
  Widget _buildIndicatorsCard() {
    final ind = _result!.indicators;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Technical Indicators',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildIndicatorChip('RSI', ind['RSI'], _getRsiColor(ind['RSI'])),
                _buildIndicatorChip('SMA 20', ind['SMA_20']),
                _buildIndicatorChip('SMA 50', ind['SMA_50']),
                _buildIndicatorChip('MACD', ind['MACD_Line']),
                _buildIndicatorChip('ATR', ind['ATR']),
                _buildIndicatorChip('Volume', ind['Volume'], formatAsInt: true),
                _buildIndicatorChip('OBV', ind['OBV'], formatAsInt: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildIndicatorChip(String label, double? value, [Color? color, {bool formatAsInt = false}]) {
    if (value == null) return const SizedBox.shrink();
    
    final displayValue = formatAsInt 
        ? value.toInt().toString()
        : value.toStringAsFixed(value.abs() > 100 ? 0 : 2);
    
    return Chip(
      label: Text('$label: $displayValue'),
      backgroundColor: (color ?? Colors.blue.shade100).withOpacity(0.3),
      labelStyle: TextStyle(
        color: color ?? Colors.blue.shade800,
        fontWeight: FontWeight.w500,
      ),
    );
  }
  
  Color _getRsiColor(double? rsi) {
    if (rsi == null) return Colors.grey;
    if (rsi > 70) return Colors.red;
    if (rsi < 30) return Colors.green;
    return Colors.orange;
  }
  
  Widget _buildSupportResistanceCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Key Price Levels',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text('Resistance', style: TextStyle(color: Colors.red)),
                        const SizedBox(height: 4),
                        Text(
                          '\$${_result!.supportResistance['nearest_resistance']?.toStringAsFixed(2) ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text('Support', style: TextStyle(color: Colors.green)),
                        const SizedBox(height: 4),
                        Text(
                          '\$${_result!.supportResistance['nearest_support']?.toStringAsFixed(2) ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPatternsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, size: 20),
                SizedBox(width: 8),
                Text(
                  'Detected Patterns',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _result!.patterns.map((pattern) {
                return Chip(
                  label: Text(pattern),
                  backgroundColor: Colors.amber.shade200,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnalysisCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology, size: 24),
                SizedBox(width: 8),
                Text(
                  'DeepSeek AI Analysis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              _result!.analysis,
              style: const TextStyle(height: 1.6, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Analysis generated by DeepSeek AI model based on technical indicators and market data',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/api_service.dart';
import 'models/stockdata.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Analyzer AI',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E2F),
        primaryColor: const Color(0xFF5E8BFF),
      ),
      home: const StockAnalysisScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class StockAnalysisScreen extends StatefulWidget {
  const StockAnalysisScreen({super.key});

  @override
  State<StockAnalysisScreen> createState() => _StockAnalysisScreenState();
}

class _StockAnalysisScreenState extends State<StockAnalysisScreen> {
  final TextEditingController _symbolController = TextEditingController();
  final TextEditingController _periodController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  String? _errorMessage;
  AnalysisResult? _result;
  
  String _currentSymbol = '';
  String _currentPeriod = '';

  Future<void> _fetchAnalysis() async {
    final symbol = _symbolController.text.trim().toUpperCase();
    if (symbol.isEmpty) {
      setState(() => _errorMessage = 'Please enter a stock symbol (e.g., AAPL)');
      return;
    }
    
    final period = _periodController.text.trim().toLowerCase();
    if (period.isEmpty) {
      setState(() => _errorMessage = 'Enter time period (e.g., 3mo 6mo 12mo)');
      return;
    }
    _currentSymbol = symbol;
    _currentPeriod = period;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final analysis = await _apiService.analyzeStock(symbol, period);
      setState(() {
        _result = analysis;
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
        title: const Text('AI Stock Analyzer'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input Section
            Column(
              children: [
                TextField(
                  controller: _symbolController,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'Enter Symbol (e.g., TSLA)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _periodController,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'Enter time period (e.g., 6mo)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.timer),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _fetchAnalysis,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Analyze', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Results Section
            Expanded(
              child: _buildResultView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Contacting backend AI...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text('Error: $_errorMessage', textAlign: TextAlign.center),
          ],
        ),
      );
    }

    if (_result != null) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStockInfoCard(),
            const SizedBox(height: 20),
            _buildChartCard(_currentSymbol ,_currentPeriod),
            const SizedBox(height: 20),
            _buildIndicatorsCard(),
            const SizedBox(height: 20),
            _buildAnalysisCard(),
          ],
        ),
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Enter a stock symbol to begin', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStockInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_result!.symbol, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const Text('Current Price', style: TextStyle(color: Colors.grey)),
              ],
            ),
            Text(
              '\$${_result!.indicators['current_price']?.toStringAsFixed(2) ?? 'N/A'}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF5E8BFF)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String symbol,String period) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${symbol} Price History ${period}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: _buildLineChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    List<FlSpot> spots = [];
    for (int i = 0; i < _result!.data.length; i++) {
      spots.add(FlSpot(i.toDouble(), _result!.data[i].close));
    }
    
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF5E8BFF),
            barWidth: 3,
            belowBarData:  BarAreaData(show: false),
          ),
        ],
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData:  FlBorderData(show: false),
      ),
    );
  }

  Widget _buildIndicatorsCard() {
    final ind = _result!.indicators;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Technical Indicators', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _indicatorTile('RSI (14)', ind['rsi']?.toStringAsFixed(2) ?? 'N/A'),
                _indicatorTile('SMA (20)', ind['sma_20'] != null ? '\$${ind['sma_20']!.toStringAsFixed(2)}' : 'N/A'),
                _indicatorTile('SMA (50)', ind['sma_50'] != null ? '\$${ind['sma_50']!.toStringAsFixed(2)}' : 'N/A'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _indicatorTile(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAnalysisCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF1E2746),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF5E8BFF)),
                SizedBox(width: 8),
                Text('Backend AI Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text(_result!.analysis, style: const TextStyle(height: 1.5, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
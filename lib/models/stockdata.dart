// lib/models/stockdata.dart
class StockDataPoint {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  StockDataPoint({required this.date, required this.open, required this.high, required this.low, required this.close, required this.volume});

  factory StockDataPoint.fromJson(Map<String, dynamic> json) {
    return StockDataPoint(
      date: DateTime.parse(json['Date']),
      open: json['Open'].toDouble(),
      high: json['High'].toDouble(),
      low: json['Low'].toDouble(),
      close: json['Close'].toDouble(),
      volume: json['Volume'],
    );
  }
}

class AnalysisResult {
  final String symbol;
  final List<StockDataPoint> data;
  final Map<String, dynamic> indicators;
  final String analysis;

  AnalysisResult({required this.symbol, required this.data, required this.indicators, required this.analysis});

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    var dataList = (json['data'] as List).map((i) => StockDataPoint.fromJson(i)).toList();
    return AnalysisResult(
      symbol: json['symbol'],
      data: dataList,
      indicators: json['indicators'],
      analysis: json['analysis'],
    );
  }
}
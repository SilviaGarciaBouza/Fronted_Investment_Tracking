import 'dart:convert';
import 'package:http/http.dart' as http;

class StockService {
  final String _apiKey = 'ROG6THSVC2RJHD1D';

  String _getFunction(String symbol) {
    if (symbol.contains(RegExp(r'USD|EUR|JPY|GBP'))) {
      return 'FX_DAILY';
    } else {
      return 'GLOBAL_QUOTE';
    }
  }

  Future<double> getStockPrice(String symbol) async {
    if (symbol.isEmpty) return 0.0;

    final function = _getFunction(symbol);
    String url;

    // A. Construir la URL según el tipo de función
    if (function == 'FX_DAILY') {
      // Para FX (ej. EURUSD) necesitamos separar la divisa base y la cotizada (from/to)
      if (symbol.length != 6) return 0.0;
      final fromCurrency = symbol.substring(0, 3);
      final toCurrency = symbol.substring(3, 6);
      // Usamos el endpoint de Tasa de Cambio para obtener el precio actual
      url =
          'https://www.alphavantage.co/query?function=CURRENCY_EXCHANGE_RATE&from_currency=$fromCurrency&to_currency=$toCurrency&apikey=$_apiKey';
    } else {
      // Para Acciones y Criptos usamos GLOBAL_QUOTE
      url =
          'https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$_apiKey';
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // B. Parsear la respuesta según la función utilizada
        if (function == 'FX_DAILY') {
          final Map<String, dynamic>? rateData =
              data['Realtime Currency Exchange Rate'];
          if (rateData != null && rateData.containsKey('5. Exchange Rate')) {
            final priceString = rateData['5. Exchange Rate'] as String;
            return double.tryParse(priceString) ?? 0.0;
          }
        } else if (function == 'GLOBAL_QUOTE') {
          final Map<String, dynamic>? quoteData = data['Global Quote'];
          if (quoteData != null && quoteData.containsKey('05. price')) {
            final priceString = quoteData['05. price'] as String;
            return double.tryParse(priceString) ?? 0.0;
          }
        }

        // C. Manejo de errores
        print('Error: Data not found or price key missing for $symbol.');
        return 0.0;
      } else {
        print(
          'Failed to connect to Alpha Vantage API. Status: ${response.statusCode}',
        );
        return 0.0;
      }
    } catch (e) {
      print('Network error occurred while fetching price for $symbol: $e');
      return 0.0;
    }
  }
}

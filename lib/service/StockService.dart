import 'dart:convert';
import 'package:http/http.dart' as http;

class StockService {
  final String _apiKey = 'ROG6THSVC2RJHD1D';

  Future<double> getStockPrice(String symbol) async {
    if (symbol.isEmpty) {
      return 0.0;
    }

    final url =
        'https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        //  decodificar
        final data = json.decode(response.body);

        // Acceso más seguro a los datos
        final Map<String, dynamic>? quoteData = data['Global Quote'];

        //  Comprobar que los datos existen y contienen el precio
        if (quoteData != null && quoteData.containsKey('05. price')) {
          final priceString = quoteData['05. price'] as String;

          // Devolver el precio, o 0.0 si el parseo falla
          return double.tryParse(priceString) ?? 0.0;
        }

        // Si la respuesta es 200 pero no hay datos de cotización (símbolo inválido)
        print(
          'Error: Stock symbol "$symbol" not found or price data missing in response.',
        );
        return 0.0;
      } else {
        // Fallo de conexión o error de servidor (404, 500, etc.)
        print(
          'Failed to connect to Alpha Vantage API. Status: ${response.statusCode}',
        );
        return 0.0;
      }
    } catch (e) {
      //  Capturar errores de red (timeout, no hay internet, etc.)
      print('Network error occurred while fetching price for $symbol: $e');
      return 0.0;
    }
  }
}

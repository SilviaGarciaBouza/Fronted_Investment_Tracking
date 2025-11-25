/*
class StockService {
  final String _apiKey = 'ROG6THSVC2RJHD1D';

  Future<double> getStockPrice(String symbol) async {
    final url =
        'https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$_apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final quoteData = data['Global Quote'];

      if (quoteData != null && quoteData.containsKey('05. price')) {
        final priceString = quoteData['05. price'];

        return double.tryParse(priceString) ?? 0.0;
      }

      print('Error: Stock symbol $symbol not found or price data missing.');
      return 0.0;
    } else {
      print(
        'Failed to connect to Alpha Vantage API. Status: ${response.statusCode}',
      );
      return 0.0;
    }
  }
}
*/
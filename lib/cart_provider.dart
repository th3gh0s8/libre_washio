
import 'package:flutter/foundation.dart';

class CartProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => [..._items];

  int get itemCount => _items.length;

  double get totalPrice {
    var total = 0.0;
    for (var item in _items) {
      // Assumes 'service_price' is the key and its value is a number.
      total += (item['service_price'] as num?) ?? 0.0;
    }
    return total;
  }

  // Adds a service to the cart.
  void addItem(Map<String, dynamic> service) {
    // For now, we allow duplicate services. A more advanced cart might
    // check for existence and increase a quantity counter.
    _items.add(service);
    notifyListeners(); // This tells widgets listening to this provider to rebuild.
  }

  // Removes a service from the cart.
  // Assumes the service map contains a unique 'id'.
  void removeItem(Map<String, dynamic> service) {
    _items.removeWhere((item) => item['id'] == service['id']);
    notifyListeners();
  }

  // Clears all items from the cart.
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Check if a specific service is already in the cart.
  bool isInCart(Map<String, dynamic> service) {
    return _items.any((item) => item['id'] == service['id']);
  }
}

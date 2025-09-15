
import 'package:flutter/foundation.dart';

class CartProvider with ChangeNotifier {
  // Use a Map to store items, with the service ID as the key.
  // The value will be a map containing the service details and its quantity.
  final Map<int, Map<String, dynamic>> _items = {};

  // Getter to return all cart items as a list.
  List<Map<String, dynamic>> get items => _items.values.toList();

  // Getter for the total number of items (sum of all quantities).
  int get itemCount {
    return _items.values.fold(0, (sum, item) => sum + (item['quantity'] as int));
  }

  // Getter for the total price, considering quantities.
  double get totalPrice {
    return _items.values.fold(0.0, (sum, item) {
      final price = (item['service_price'] as num?) ?? 0.0;
      final quantity = (item['quantity'] as int?) ?? 0;
      return sum + (price * quantity);
    });
  }

  // Adds a service to the cart or increments its quantity.
  void addItem(Map<String, dynamic> service) {
    final int serviceId = service['id'] as int;

    if (_items.containsKey(serviceId)) {
      // If item already exists, just increase the quantity.
      _items.update(serviceId, (existingItem) {
        existingItem['quantity'] = (existingItem['quantity'] as int) + 1;
        return existingItem;
      });
    } else {
      // If it's a new item, add it to the cart with a quantity of 1.
      _items[serviceId] = {
        ...service,
        'quantity': 1,
      };
    }
    notifyListeners();
  }

  // Decrements an item's quantity or removes it if quantity is 1.
  // This is useful for an "undo" action.
  void removeItem(Map<String, dynamic> service) {
    final int serviceId = service['id'] as int;

    if (!_items.containsKey(serviceId)) {
      return; // Item not in cart
    }

    if ((_items[serviceId]?['quantity'] as int) > 1) {
      _items.update(serviceId, (existingItem) {
        existingItem['quantity'] = (existingItem['quantity'] as int) - 1;
        return existingItem;
      });
    } else {
      // If quantity is 1, remove the item completely.
      _items.remove(serviceId);
    }
    notifyListeners();
  }

  // Completely removes an item from the cart, regardless of quantity.
  void removeFullItem(int serviceId) {
    if (_items.containsKey(serviceId)) {
      _items.remove(serviceId);
      notifyListeners();
    }
  }

  // Clears all items from the cart.
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Check if a specific service is already in the cart.
  bool isInCart(Map<String, dynamic> service) {
    final int serviceId = service['id'] as int;
    return _items.containsKey(serviceId);
  }
}

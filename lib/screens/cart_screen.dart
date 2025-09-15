import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../cart_provider.dart';
import '../api.dart'; // For API base URL

class CartScreen extends StatefulWidget {
  final int userId;

  const CartScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isProcessing = false;

  Future<void> _handleCheckout(CartProvider cart) async {
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final firstItem = cart.items.first;
    final stationId = firstItem['station_id'] as int? ?? 0; // Ensure station_id exists in your service item map

    final url = Uri.parse('${ApiService.baseUrl}/create_order.php');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'station_id': stationId,
          'items': cart.items,
          'total_amount': cart.totalPrice,
          'payment_method': 'cash_on_delivery', // Or get from UI
        }),
      );

      if (!mounted) return;

      final responseData = jsonDecode(response.body);

      if (responseData['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message']), backgroundColor: Colors.green),
        );
        cart.clearCart();
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message']), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
      ),
      body: Column(
        children: [
          Expanded(
            child: cart.items.isEmpty
                ? const Center(
                    child: Text(
                      'Your cart is empty.',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      final itemName = item['service_name']?.toString() ?? 'Service';
                      final itemPrice = (item['service_price'] as num?)?.toStringAsFixed(2) ?? '0.00';
                      final quantity = item['quantity'] as int? ?? 1;

                      return ListTile(
                        title: Text(itemName),
                        subtitle: Text('\$$itemPrice x $quantity'),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () {
                            cart.removeFullItem(item['id'] as int);
                          },
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${cart.totalPrice.toStringAsFixed(2)}',
                   style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: (cart.items.isEmpty || _isProcessing) ? null : () => _handleCheckout(cart),
              child: _isProcessing
                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                  : const Text('Proceed to Checkout', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

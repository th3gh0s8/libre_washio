import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../cart_provider.dart';
import '../api.dart';

class CheckoutScreen extends StatefulWidget {
  final int userId;

  const CheckoutScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isProcessing = false;

  Future<void> _placeOrder(CartProvider cart) async {
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot place an empty order.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final response = await ApiService.createOrder(
        userId: widget.userId,
        items: cart.items,
      );

      if (!mounted) return;

      if (response['status'] == 'success') {
        cart.clearCart();
        // Get the user-facing order count from the response
        final displayOrderId = response['display_order_id'];
        final successMessage = displayOrderId != null
            ? 'Order #$displayOrderId has been confirmed!'
            : response['message'] ?? 'Order placed successfully!'; // Fallback message

        _showOrderSuccessDialog(successMessage);
      } else {
        _showError(response['message'] ?? 'An unknown error occurred.');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showOrderSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Order Confirmed'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(ctx).pop(); // Close the dialog
                Navigator.of(context).popUntil((route) => route.isFirst); // Go back to the dashboard
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Order'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text('Order Summary', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...cart.items.map((item) {
                  final itemName = item['service_name']?.toString() ?? 'Service';
                  final itemPrice = (item['service_price'] as num?) ?? 0;
                  final quantity = item['quantity'] as int? ?? 1;
                  return ListTile(
                    title: Text(itemName),
                    subtitle: Text('Quantity: $quantity'),
                    trailing: Text('\$${(itemPrice * quantity).toStringAsFixed(2)}'),
                  );
                }).toList(),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total:', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      '\$${cart.totalPrice.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (cart.items.isEmpty || _isProcessing) ? null : () => _placeOrder(cart),
                  child: _isProcessing
                      ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                      : const Text('Place Order'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

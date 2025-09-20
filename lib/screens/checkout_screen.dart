import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Added import
import '../cart_provider.dart';
import '../api.dart';

class CheckoutScreen extends StatefulWidget {
  final int userId;

  const CheckoutScreen({super.key, required this.userId});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isProcessing = false;
  final List<String> _paymentMethods = ['Cash on Delivery', 'Online Payment (Coming Soon)'];
  String _selectedPaymentMethod = 'Cash on Delivery'; // Default selection

  Future<void> _placeOrder(CartProvider cart) async {
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot place an empty order.')),
      );
      return;
    }
    // Additional check for disabled payment method, though UI should prevent selection
    if (_selectedPaymentMethod == 'Online Payment (Coming Soon)'){
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid payment method.')),
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
        paymentMethod: _selectedPaymentMethod, // Pass the selected method
      );

      if (!mounted) return;

      if (response['status'] == 'success') {
        cart.clearCart();
        final displayOrderId = response['display_order_id'];
        final successMessage = displayOrderId != null
            ? 'Order #$displayOrderId has been confirmed!'
            : response['message'] ?? 'Order placed successfully!';

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
  final currencyFormatter = NumberFormat.currency(symbol: '\$');

  return Scaffold(
    appBar: AppBar(
      title: const Text('Confirm Order'),
    ),
    body: Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0), // Padding for the whole scrollable area
            children: [
              // Section 1: Order Summary
              Text(
                'Order Summary',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              Card( // Card for the list of items
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 24.0), // Space after this card
                elevation: 2.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                child: Column(
                  children: cart.items.map((item) {
                    final itemName = item['service_name']?.toString() ?? 'Service';
                    final itemPrice = (item['service_price'] as num?) ?? 0;
                    final quantity = item['quantity'] as int? ?? 1;
                    final formattedItemTotal = currencyFormatter.format(itemPrice * quantity);
                    return ListTile(
                      title: Text(itemName, style: theme.textTheme.titleMedium),
                      subtitle: Text('Quantity: $quantity', style: theme.textTheme.bodyMedium),
                      trailing: Text(
                        formattedItemTotal,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Section 2: Payment Method - REMOVED FROM HERE
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
                  Text(
                    'Total:',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    currencyFormatter.format(cart.totalPrice),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0), // Space before dropdown

              // NEW: Payment Method Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  filled: true,
                  // fillColor: theme.canvasColor, // Adapts to theme, or use a specific color
                ),
                value: _selectedPaymentMethod,
                isExpanded: true,
                items: _paymentMethods.map((String method) {
                  bool isEnabled = method != 'Online Payment (Coming Soon)';
                  return DropdownMenuItem<String>(
                    value: method,
                    enabled: isEnabled,
                    child: Text(
                      method,
                      style: TextStyle(
                        color: isEnabled ? null : Colors.grey, // Grey out disabled text
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedPaymentMethod = newValue;
                    });
                  }
                },
                // icon: Icon(Icons.arrow_drop_down_circle_outlined, color: theme.colorScheme.primary),
              ),

              const SizedBox(height: 24.0), // Space after dropdown, before button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: (cart.items.isEmpty || _isProcessing) ? null : () => _placeOrder(cart),
                child: _isProcessing
                    ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                    : Text('Place Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

}

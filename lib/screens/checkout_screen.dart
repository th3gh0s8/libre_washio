import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../cart_provider.dart';
import '../api.dart';
import './order_details_screen.dart'; // Added import

class CheckoutScreen extends StatefulWidget {
  final int userId;

  const CheckoutScreen({super.key, required this.userId});

  @override
  CheckoutScreenState createState() => CheckoutScreenState();
}

class CheckoutScreenState extends State<CheckoutScreen> {
  bool _isProcessing = false;
  final List<String> _paymentMethods = ['Cash on Delivery', 'Online Payment (Coming Soon)'];
  String _selectedPaymentMethod = 'Cash on Delivery';

  Future<void> _placeOrder(CartProvider cart) async {
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot place an empty order.')),
      );
      return;
    }
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
        paymentMethod: _selectedPaymentMethod,
      );

      if (!mounted) return;

      if (response['status'] == 'success') {
        cart.clearCart();
        
        final actualOrderId = response['actual_order_id']?.toString();
        final displayOrderId = response['display_order_id']?.toString();
        final stationName = response['station_name']?.toString();

        final successMessage = displayOrderId != null && displayOrderId.isNotEmpty
            ? 'Order #$displayOrderId has been confirmed!'
            : response['message'] ?? 'Order placed successfully!';

        if (actualOrderId != null && stationName != null) {
          _showOrderSuccessDialog(successMessage, actualOrderId, displayOrderId ?? actualOrderId, stationName);
        } else {
          _showError('Order placed, but could not retrieve all details for navigation.');
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext ctx) {
                return AlertDialog(
                  title: const Text('Order Confirmed'),
                  content: Text(successMessage),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('OK'),
                      onPressed: () {
                        Navigator.of(ctx).pop(); 
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                    ),
                  ],
                );
              },
            );
        }
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

  void _showOrderSuccessDialog(String message, String actualOrderId, String displayOrderId, String stationName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Order Confirmed'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('View Details'),
              onPressed: () {
                Navigator.of(ctx).pop(); // Close the dialog

                Navigator.of(context).popUntil((route) => route.isFirst); 

                Navigator.push( 
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetailsScreen(
                      orderId: actualOrderId,
                      displayOrderId: displayOrderId,
                      stationName: stationName,
                    ),
                  ),
                );
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
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  'Order Summary',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Card(
                  clipBehavior: Clip.antiAlias,
                  margin: const EdgeInsets.only(bottom: 24.0),
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
                const SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                    filled: true,
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
                          color: isEnabled ? null : Colors.grey,
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
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: (cart.items.isEmpty || _isProcessing) ? null : () => _placeOrder(cart),
                  child: _isProcessing
                      ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                      : const Text('Place Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

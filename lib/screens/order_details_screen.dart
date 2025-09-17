import 'package:flutter/material.dart';
import '../api.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  final String stationName;

  const OrderDetailsScreen({
    Key? key,
    required this.orderId,
    required this.stationName,
  }) : super(key: key);

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Future<List<Map<String, dynamic>>> _orderDetailsFuture;

  @override
  void initState() {
    super.initState();
    // Convert orderId to int for the API call
    final int orderIdInt = int.tryParse(widget.orderId) ?? 0;
    _orderDetailsFuture = ApiService.getOrderDetails(orderIdInt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId}'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _orderDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading order details: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No items found for this order.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final items = snapshot.data!;
          final theme = Theme.of(context);

          // Calculate the total amount from the items fetched
          final double totalAmount = items.fold(0.0, (sum, item) {
            final price = double.tryParse(item['price']?.toString() ?? '0.0') ?? 0.0;
            final quantity = int.tryParse(item['item_quantity']?.toString() ?? '1') ?? 1;
            return sum + (price * quantity);
          });

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order from ${widget.stationName}',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Items Ordered',
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final itemName = item['item']?.toString() ?? 'Unknown Item';
                    final itemPrice = double.tryParse(item['price']?.toString() ?? '0.0') ?? 0.0;
                    final quantity = int.tryParse(item['item_quantity']?.toString() ?? '1') ?? 1;

                    return ListTile(
                      title: Text(itemName, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('Quantity: $quantity'),
                      trailing: Text(
                        '\$${(itemPrice * quantity).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                      'Total Paid:',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${totalAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

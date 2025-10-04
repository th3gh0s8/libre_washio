import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Added import
import '../api.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId; // The actual ID from the database for API calls
  final String stationName;
  final String? displayOrderId; // The user-facing sequential ID for display

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.stationName,
    this.displayOrderId,
  });

  @override
  OrderDetailsScreenState createState() => OrderDetailsScreenState();
}

class OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Future<List<Map<String, dynamic>>> _orderDetailsFuture;

  @override
  void initState() {
    super.initState();
    // The API call correctly uses the actual (database) orderId for fetching data
    final int orderIdInt = int.tryParse(widget.orderId) ?? 0;
    _orderDetailsFuture = ApiService.getOrderDetails(orderIdInt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _orderDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return _buildErrorState(theme, snapshot.error);
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(theme);
          }

          final items = snapshot.data!;
          final double totalAmount = items.fold(0.0, (sum, item) {
            final price = double.tryParse(item['price']?.toString() ?? '0.0') ?? 0.0;
            final quantity = int.tryParse(item['item_quantity']?.toString() ?? '1') ?? 1;
            return sum + (price * quantity);
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                const SizedBox(height: 24),
                Text(
                  'Order Summary',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildItemsCard(theme, items, totalAmount),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    // Use the displayOrderId for the UI if it was passed, otherwise fall back to the actual ID.
    final String idToShow = widget.displayOrderId ?? widget.orderId;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(13),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary.withAlpha(26),
            child: Icon(Icons.storefront, color: theme.colorScheme.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.stationName,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2, // Added for station name potentially
                ),
                const SizedBox(height: 4),
                Text(
                  'Order ID: #$idToShow',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(ThemeData theme, List<Map<String, dynamic>> items, double totalAmount) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$'); // Added

    return Card(
      elevation: 2.0,
      shadowColor: theme.shadowColor.withAlpha(26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final itemName = item['item']?.toString() ?? 'Unknown Item';
              final itemPrice = double.tryParse(item['price']?.toString() ?? '0.0') ?? 0.0;
              final quantity = int.tryParse(item['item_quantity']?.toString() ?? '1') ?? 1;
              final formattedItemTotal = currencyFormatter.format(itemPrice * quantity); // Format here

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  itemName, 
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 2, // Allow more lines for item name
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('Quantity: $quantity'),
                trailing: Text(
                  formattedItemTotal, // Use formatted value
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Paid', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  currencyFormatter.format(totalAmount), // Format here
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'Load Failed',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              "We couldn't fetch the details for this order. Please check your connection and try again.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'No Details Found',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no items associated with this order number.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

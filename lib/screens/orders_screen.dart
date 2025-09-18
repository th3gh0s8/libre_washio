import 'package:flutter/material.dart';
import '../api.dart';
import './order_details_screen.dart';

// A stylish badge to display order status
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    Color textColor;
    IconData iconData;
    String displayText;

    switch (status.toLowerCase()) {
      case 'completed':
        badgeColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green.shade800;
        iconData = Icons.check_circle_outline;
        displayText = 'Completed';
        break;
      case 'in_progress':
        badgeColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue.shade800;
        iconData = Icons.hourglass_top_outlined;
        displayText = 'In Progress';
        break;
      case 'cancelled':
        badgeColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red.shade800;
        iconData = Icons.cancel_outlined;
        displayText = 'Cancelled';
        break;
      default:
        badgeColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange.shade800;
        iconData = Icons.pending_outlined;
        displayText = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: textColor, size: 14),
          const SizedBox(width: 6),
          Text(
            displayText,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class OrdersScreen extends StatefulWidget {
  final int userId;

  const OrdersScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = ApiService.getUserOrders(widget.userId);
  }

  void _refreshOrders() {
    setState(() {
      _ordersFuture = ApiService.getUserOrders(widget.userId);
    });
  }

  // Updated to pass the display ID to the details screen
  void _navigateToDetails(String actualOrderId, String stationName, String displayOrderId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(
          orderId: actualOrderId, // The real ID for API calls
          stationName: stationName,
          displayOrderId: displayOrderId, // The user-facing ID
        ),
      ),
    ).then((_) => _refreshOrders());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrders,
            tooltip: 'Refresh Orders',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return _buildErrorWidget(theme);
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyStateWidget(theme);
          }

          final orders = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final actualOrderId = order['order_id']?.toString() ?? 'N/A';
              final stationName = order['station_name']?.toString() ?? 'Unknown Station';
              final orderDate = order['order_date']?.toString() ?? 'Unknown Date';
              final totalPrice = double.tryParse(order['total_price']?.toString() ?? '0.0') ?? 0.0;
              final orderStatus = order['order_status']?.toString() ?? 'pending';
              final displayOrderId = (orders.length - index).toString();

              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                elevation: 2.0,
                shadowColor: theme.shadowColor.withOpacity(0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16.0),
                  // Pass all necessary IDs and names
                  onTap: () => _navigateToDetails(actualOrderId, stationName, displayOrderId),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                stationName,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '\$${totalPrice.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ID: #$displayOrderId • $orderDate',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            StatusBadge(status: orderStatus),
                            Row(
                              children: [
                                Text('View Details', style: theme.textTheme.bodySmall),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios, size: 12, color: theme.colorScheme.onSurfaceVariant),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 80, color: theme.colorScheme.error.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text('Failed to Load Orders', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t fetch your order history. Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text('No Order History', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              'Your completed orders will be displayed here. Start by placing an order from the Services tab!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

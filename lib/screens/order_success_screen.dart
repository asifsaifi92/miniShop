import 'package:flutter/material.dart';
import '../models/order.dart';

/// Shown after a successful checkout. Displays the order ID, item count,
/// total, and delivery address. No back navigation — the user returns home
/// via the "Continue Shopping" button, which pops to the first route.
class OrderSuccessScreen extends StatelessWidget {
  final Order order;

  const OrderSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Order Placed!',
                style:
                    TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Use only the first non-empty word of the name to avoid
              // showing "Thank you, John  Doe!" if there are extra spaces.
              Text(
                'Thank you, ${order.name.trim().split(' ').where((w) => w.isNotEmpty).firstOrNull ?? order.name}!',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              _buildInfoCard(),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  // popUntil(isFirst) pops back to HomeScreen regardless of
                  // how many screens are on the stack.
                  onPressed: () => Navigator.popUntil(
                      context, (route) => route.isFirst),
                  child: const Text('Continue Shopping'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Order ID', order.id),
            const Divider(height: 16),
            _row('Items', '${order.items.fold(0, (s, i) => s + i.quantity)}'),
            const Divider(height: 16),
            _row('Total', '\$${order.total.toStringAsFixed(2)}'),
            const Divider(height: 16),
            _row('Deliver to', order.address),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 13)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

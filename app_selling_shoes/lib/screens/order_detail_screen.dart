import 'package:app_selling_shoes/files/tracking_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  OrderDetailScreen({required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chi tiết Đơn hàng #${order['id']}')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mã đơn hàng: ${order['id']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Trạng thái: ${order['status']}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Ngày đặt hàng: ${order['date']}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Tổng tiền: \$${order['totalAmount']?.toStringAsFixed(2) ?? '0.00'}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            if (order['status'] == 'Đang giao')
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TrackingScreen(orderId: order['id'])),
                    );
                  },
                  child: Text('Theo dõi đơn hàng'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
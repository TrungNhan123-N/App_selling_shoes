import 'package:app_selling_shoes/files/tracking_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  OrderDetailScreen({required this.order});

  @override
  Widget build(BuildContext context) {
    final items = order['items'] as List<dynamic>? ?? [];
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
            SizedBox(height: 8),
            Text('Phương thức thanh toán: ${order['paymentMethod']}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Địa chỉ giao hàng: ${order['address']}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            Text('Sản phẩm:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index] as Map<String, dynamic>;
                  return ListTile(
                    title: Text(item['name']),
                    subtitle: Text('Số lượng: ${item['quantity']} - Giá: \$${item['price']}'),
                  );
                },
              ),
            ),
            if (order['status'] == 'Đang giao')
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/tracking', arguments: order['id']); // Sử dụng route với arguments
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
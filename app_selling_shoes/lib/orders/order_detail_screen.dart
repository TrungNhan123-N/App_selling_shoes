import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  OrderDetailScreen({required Map<Object?, Object?> order})
      : order = Map<String, dynamic>.from(order); // Chuyển đổi dữ liệu đúng kiểu

  @override
  Widget build(BuildContext context) {
    final items = (order['items'] as List<dynamic>? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(); // Chuyển đổi từng phần tử của danh sách sản phẩm

    final formattedDate = order['date'] != null
        ? DateFormat('dd/MM/yyyy').format(
        DateTime.fromMillisecondsSinceEpoch(order['date'] as int))
        : 'Không xác định';

    final formattedTotal = NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
        .format(order['totalPrice'] ?? 0);

    return Scaffold(
      appBar: AppBar(title: Text('Chi tiết Đơn hàng #${order['id']}')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mã đơn hàng: ${order['id']}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Trạng thái: ${order['status']}',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Ngày đặt hàng: $formattedDate',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Tổng tiền: $formattedTotal', style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            Text('Sản phẩm:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: item['image_url'] != null
                          ? Image.network(
                        item['image_url'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                          : Icon(Icons.image, size: 50, color: Colors.grey),
                      title: Text(item['name']),
                      subtitle: Text(
                          'Số lượng: ${item['quantity']} - Giá: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(item['price'])}'),
                    ),
                  );
                },
              ),
            ),
            if (order['status'] == 'Chờ giao hàng')
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/tracking',
                        arguments: order['id']);
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

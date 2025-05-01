import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  OrderDetailScreen({required this.order});

  @override
  Widget build(BuildContext context) {
    final items = (order['items'] is List<dynamic>
        ? order['items'] as List<dynamic>
        : []).map((item) => Map<String, dynamic>.from(item as Map? ?? {})).toList();

    final formattedDate = order['date'] is Timestamp
        ? DateFormat('dd/MM/yyyy HH:mm').format((order['date'] as Timestamp).toDate())
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
                      leading: item['image_url'] != null && item['image_url'].toString().isNotEmpty
                          ? Image.network(
                        item['image_url'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: 50),
                      )
                          : Icon(Icons.image, size: 50, color: Colors.grey),
                      title: Text(item['name'] ?? 'Không có tên'),
                      subtitle: Text(
                          'Số lượng: ${item['quantity'] ?? 0} - Giá: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(item['price'] ?? 0)}'),
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
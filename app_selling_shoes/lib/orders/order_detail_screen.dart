import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import thêm package intl để format dữ liệu

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  OrderDetailScreen({required this.order});

  @override
  Widget build(BuildContext context) {
    final items = order['items'] as List<dynamic>? ?? [];
    final formattedDate = order['date'] is Timestamp
        ? DateFormat('dd/MM/yyyy').format(order['date'].toDate())
        : (order['date'] != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(order['date']))
        : 'Không xác định');
    final formattedTotal = NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
        .format(order['totalAmount'] ?? 0);

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
            Text('Ngày đặt hàng: $formattedDate', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Tổng tiền: $formattedTotal', style: TextStyle(fontSize: 16)),
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
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: item['imageUrl'] != null
                          ? Image.network(
                        item['imageUrl'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                          : Icon(Icons.image, size: 50, color: Colors.grey),
                      title: Text(item['name']),
                      subtitle: Text('Số lượng: ${item['quantity']} - Giá: \$${item['price']}'),
                    ),
                  );
                },
              ),
            ),
            if (order['status'] == 'Đang giao')
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/tracking', arguments: order['id']);
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

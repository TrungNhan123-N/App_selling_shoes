// admin_order_management_screen.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminOrderManagementScreen extends StatefulWidget {
  @override
  _AdminOrderManagementScreenState createState() => _AdminOrderManagementScreenState();
}

class _AdminOrderManagementScreenState extends State<AdminOrderManagementScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref().child('orders');

  // Danh sách trạng thái đơn hàng
  final List<String> _statusOptions = [
    'Chờ xác nhận',
    'Chờ lấy hàng',
    'Chờ giao hàng',
    'Đánh giá',
    'Hoàn thành',
    'Đã hủy'
  ];

  // Cập nhật trạng thái đơn hàng
  void _updateOrderStatus(String orderId, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Cập nhật trạng thái"),
        content: DropdownButtonFormField<String>(
          value: currentStatus,
          items: _statusOptions.map((status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Text(status),
            );
          }).toList(),
          onChanged: (newStatus) async {
            if (newStatus != null) {
              await _database.child(orderId).update({
                'status': newStatus,
                'updatedAt': ServerValue.timestamp,
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Đã cập nhật trạng thái thành $newStatus")),
              );
            }
          },
          decoration: InputDecoration(labelText: "Chọn trạng thái mới"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy"),
          ),
        ],
      ),
    );
  }

  // Xóa đơn hàng
  void _deleteOrder(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Xác nhận xóa"),
        content: Text("Bạn có chắc muốn xóa đơn hàng này?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _database.child(orderId).remove();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Đã xóa đơn hàng")),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Xóa"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quản lý trạng thái đơn hàng"),
        backgroundColor: Colors.blueGrey,
      ),
      body: StreamBuilder(
        stream: _database.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(child: Text("Không có đơn hàng nào"));
          }

          Map<dynamic, dynamic> orders = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          List<Map<String, dynamic>> orderList = [];
          orders.forEach((key, value) {
            orderList.add(Map<String, dynamic>.from(value)..['id'] = key);
          });

          // Sắp xếp theo ngày đặt hàng (mới nhất trước)
          orderList.sort((a, b) => (b['date'] ?? 0).compareTo(a['date'] ?? 0));

          return ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: orderList.length,
            itemBuilder: (context, index) {
              final order = orderList[index];
              final formattedDate = order['date'] != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(
                  DateTime.fromMillisecondsSinceEpoch(order['date'] as int))
                  : 'Không xác định';
              final formattedTotal = NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                  .format(order['totalPrice'] ?? 0);

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Đơn hàng #${order['id'].substring(0, 8)}...",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            order['status'],
                            style: TextStyle(
                              color: _getStatusColor(order['status']),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text("Khách hàng: ${order['userId'].substring(0, 8)}..."),
                      Text("Ngày đặt: $formattedDate"),
                      Text("Tổng tiền: $formattedTotal"),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _updateOrderStatus(order['id'], order['status']),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteOrder(order['id']),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Lấy màu sắc dựa trên trạng thái
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Chờ xác nhận':
        return Colors.orange;
      case 'Chờ lấy hàng':
        return Colors.blue;
      case 'Chờ giao hàng':
        return Colors.purple;
      case 'Đánh giá':
        return Colors.yellow[800]!;
      case 'Hoàn thành':
        return Colors.green;
      case 'Đã hủy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
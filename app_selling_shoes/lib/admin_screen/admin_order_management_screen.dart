import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminOrderManagementScreen extends StatefulWidget {
  @override
  _AdminOrderManagementScreenState createState() => _AdminOrderManagementScreenState();
}

class _AdminOrderManagementScreenState extends State<AdminOrderManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
  }

  void _checkAdminRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot snapshot = await _firestore.collection('users').doc(user.uid).get();
      if (snapshot.exists) {
        Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>;
        if (userData['role'] != 'admin') {
          Navigator.pushReplacementNamed(context, '/home');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Bạn không có quyền truy cập!")),
          );
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  final List<String> _statusOptions = [
    'Chờ xác nhận',
    'Chờ lấy hàng',
    'Chờ giao hàng',
    'Đánh giá',
    'Hoàn thành',
    'Đã hủy'
  ];

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
              await _firestore.collection('orders').doc(orderId).update({
                'status': newStatus,
                'updatedAt': FieldValue.serverTimestamp(),
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
              await _firestore.collection('orders').doc(orderId).delete();
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('orders').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Không có đơn hàng nào"));
          }

          List<DocumentSnapshot> orders = snapshot.data!.docs;

          // Sắp xếp với xử lý trường hợp date không tồn tại
          orders.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            Timestamp? aTimestamp = aData.containsKey('date') && aData['date'] is Timestamp
                ? aData['date'] as Timestamp
                : null;
            Timestamp? bTimestamp = bData.containsKey('date') && bData['date'] is Timestamp
                ? bData['date'] as Timestamp
                : null;
            return (bTimestamp?.millisecondsSinceEpoch ?? 0)
                .compareTo(aTimestamp?.millisecondsSinceEpoch ?? 0);
          });

          return ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final orderData = order.data() as Map<String, dynamic>;
              final formattedDate = orderData.containsKey('date') && orderData['date'] is Timestamp
                  ? DateFormat('dd/MM/yyyy HH:mm').format((orderData['date'] as Timestamp).toDate())
                  : 'Không xác định';
              final formattedTotal = NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                  .format(orderData['totalPrice'] ?? 0);

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
                            "Đơn hàng #${order.id.substring(0, 8)}...",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            orderData['status'] ?? 'Không xác định',
                            style: TextStyle(
                              color: _getStatusColor(orderData['status'] ?? ''),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text("Khách hàng: ${orderData['userId']?.substring(0, 8) ?? 'N/A'}..."),
                      Text("Ngày đặt: $formattedDate"),
                      Text("Tổng tiền: $formattedTotal"),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _updateOrderStatus(order.id, orderData['status'] ?? 'Chờ xác nhận'),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteOrder(order.id),
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
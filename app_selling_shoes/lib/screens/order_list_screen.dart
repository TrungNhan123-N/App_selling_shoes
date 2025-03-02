import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'order_detail_screen.dart';

class OrderListScreen extends StatelessWidget {
  final List<Map<String, dynamic>> orders = [
    {'id': '001', 'status': 'Chờ xác nhận', 'date': '2025-02-28', 'icon': Icons.article},
    {'id': '002', 'status': 'Chờ lấy hàng', 'date': '2025-02-27', 'icon': Icons.inventory},
    {'id': '003', 'status': 'Chờ giao hàng', 'date': '2025-02-26', 'icon': Icons.local_shipping},
    {'id': '004', 'status': 'Đánh giá', 'date': '2025-02-25', 'icon': Icons.star},
  ];

  final String userName = "Nguyễn Trung Nhan";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text('Danh sách Đơn hàng'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              // Xử lý giỏ hàng
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileScreen()),
                    );
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: AssetImage('assets/avatar.png'),
                      ),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Thành viên', style: TextStyle(color: Colors.orange)),
                          ),
                          SizedBox(height: 4),
                          Text('0 Người theo dõi   12 Đang theo dõi', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Đơn mua", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () {
                    // Điều hướng đến lịch sử mua hàng
                  },
                  child: Row(
                    children: [
                      Text("Xem lịch sử mua hàng", style: TextStyle(color: Colors.blue)),
                      Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: orders.map((order) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailScreen(order: order),
                    ),
                  );
                },
                child: Column(
                  children: [
                    Icon(order['icon'], size: 32, color: Colors.black54),
                    SizedBox(height: 4),
                    Text(order['status'], style: TextStyle(fontSize: 14)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

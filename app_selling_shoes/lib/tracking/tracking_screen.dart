import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TrackingScreen extends StatelessWidget {
  final String orderId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TrackingScreen({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Theo dõi đơn hàng #$orderId')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('orders').doc(orderId).snapshots(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) return Center(child: Text("Không có thông tin theo dõi"));

          final statuses = ['Chờ xác nhận', 'Chờ lấy hàng', 'Chờ giao hàng', 'Đang giao', 'Hoàn thành'];
          final currentStatus = data['status'] ?? 'Chờ xác nhận';

          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trạng thái đơn hàng:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: statuses.length,
                    separatorBuilder: (context, index) => Divider(),
                    itemBuilder: (context, index) {
                      final isCompleted = statuses[index] == currentStatus;
                      return ListTile(
                        leading: Icon(
                          isCompleted ? Icons.check_circle : Icons.local_shipping,
                          color: isCompleted ? Colors.green : Colors.blue,
                        ),
                        title: Text(statuses[index], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
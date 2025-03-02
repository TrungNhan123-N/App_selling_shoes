import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TrackingScreen extends StatelessWidget {
  final String orderId;
  TrackingScreen({required this.orderId});

  final List<String> statuses = [
    "Đơn hàng đã được xác nhận",
    "Đang chuẩn bị hàng",
    "Đang giao hàng",
    "Đã giao thành công"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Theo dõi đơn hàng #$orderId')),
      body: Padding(
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
                  return ListTile(
                    leading: Icon(
                      index == statuses.length - 1
                          ? Icons.check_circle
                          : Icons.local_shipping,
                      color: index == statuses.length - 1 ? Colors.green : Colors.blue,
                    ),
                    title: Text(statuses[index],
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

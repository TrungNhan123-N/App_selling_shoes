import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TrackingScreen extends StatelessWidget {
  final String orderId;
  final DatabaseReference _trackingRef;

  TrackingScreen({required this.orderId}) : _trackingRef = FirebaseDatabase.instance.ref('tracking/$orderId');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Theo dõi đơn hàng #$orderId')),
      body: StreamBuilder(
        stream: _trackingRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final data = snapshot.data!.snapshot.value as Map?;
          if (data == null) return Center(child: Text("Không có thông tin theo dõi"));

          final statuses = List<String>.from(data['statuses'] ?? []);
          final currentStatus = data['currentStatus'] ?? statuses.last;

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
// user_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserListScreen extends StatelessWidget {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Danh sách người dùng")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firebaseFirestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final users = snapshot.data!.docs;
          return ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text(user['name'] ?? 'Không có tên'),
                  subtitle: Text(user['email'] ?? 'Không có email'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
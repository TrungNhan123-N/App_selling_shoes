import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminUserManagementScreen extends StatelessWidget {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  void _deleteUser(String userId) async {
    await _firebaseFirestore.collection('users').doc(userId).delete();
  }

  void _editUser(BuildContext context, String userId, Map<String, dynamic> userData) {
    TextEditingController nameController = TextEditingController(text: userData['name']);
    TextEditingController emailController = TextEditingController(text: userData['email']);
    TextEditingController roleController = TextEditingController(text: userData['role']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Chỉnh sửa người dùng"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: "Tên")),
              TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
              TextField(controller: roleController, decoration: InputDecoration(labelText: "Vai trò")),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Hủy")
            ),
            TextButton(
                onPressed: () async {
                  await _firebaseFirestore.collection('users').doc(userId).update({
                    'name': nameController.text,
                    'email': emailController.text,
                    'role': roleController.text,
                  });
                  Navigator.pop(context);
                },
                child: const Text("Lưu")
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quản lý người dùng (Admin)")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firebaseFirestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Không có người dùng nào."));
          }

          final users = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final user = userDoc.data() as Map<String, dynamic>;
              final userId = userDoc.id;
              final name = user['name'] ?? 'Không có tên';
              final email = user['email'] ?? 'Không có email';
              final role = user['role'] ?? 'Chưa xác định';
              final age = user['age'] != null ? user['age'].toString() : 'Không rõ';

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                elevation: 4,
                child: ListTile(
                  leading: const Icon(Icons.admin_panel_settings, size: 40, color: Colors.red),
                  title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Email: $email"),
                      Text("Vai trò: $role"),
                      Text("Tuổi: $age"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editUser(context, userId, user),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteUser(userId),
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
}
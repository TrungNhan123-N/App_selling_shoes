import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../files/saved_addresses_screen.dart';
import '../screens/order_list_screen.dart'; // Thêm import để sử dụng OrderListScreen

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          userData = doc.data() as Map<String, dynamic>;
        });
      }
    }
  }

  void _showEditDialog({
    required String field,
    required String initialValue,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final TextEditingController controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chỉnh sửa $field'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          keyboardType: keyboardType,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              User? user = _auth.currentUser;
              if (user != null) {
                try {
                  if (field == 'Email') {
                    await user.updateEmail(controller.text.trim());
                    await _firestore.collection('users').doc(user.uid).update({
                      'email': controller.text.trim(),
                    });
                  } else if (field == 'Tên') {
                    await _firestore.collection('users').doc(user.uid).update({
                      'name': controller.text.trim(),
                    });
                  } else if (field == 'Số điện thoại') {
                    await _firestore.collection('users').doc(user.uid).update({
                      'phoneNumber': controller.text.trim(),
                    });
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã cập nhật $field')),
                  );
                  _loadUserData();
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(child: Text('Vui lòng đăng nhập để xem hồ sơ.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text('Hồ sơ Cá nhân'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildProfileItem(
            icon: Icons.person,
            title: 'Tên',
            value: userData?['name'] ?? 'Nguyễn Trung Nhân',
            onTap: () => _showEditDialog(
              field: 'Tên',
              initialValue: userData?['name'] ?? 'Nguyễn Trung Nhân',
              label: 'Nhập tên mới',
            ),
          ),
          Divider(),
          _buildProfileItem(
            icon: Icons.phone,
            title: 'Số điện thoại',
            value: userData?['phoneNumber'] ?? '****96',
            onTap: () => _showEditDialog(
              field: 'Số điện thoại',
              initialValue: userData?['phoneNumber'] ?? '****96',
              label: 'Nhập số điện thoại mới',
              keyboardType: TextInputType.phone,
            ),
          ),
          Divider(),
          _buildProfileItem(
            icon: Icons.email,
            title: 'Email',
            value: userData?['email'] ?? 'n****@gmail.com',
            onTap: () => _showEditDialog(
              field: 'Email',
              initialValue: userData?['email'] ?? 'n****@gmail.com',
              label: 'Nhập email mới',
              keyboardType: TextInputType.emailAddress,
            ),
            isEmail: true,
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.location_on, color: Colors.blue),
            title: Text('Xem địa chỉ đã lưu'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SavedAddressesScreen()),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.list_alt, color: Colors.blue),
            title: Text('Xem đơn hàng'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => OrderListScreen()));
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Đăng xuất'),
            onTap: () async {
              await _auth.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    bool isEmail = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value, style: TextStyle(color: Colors.grey)),
      onTap: onTap,
    );
  }
}
import 'package:bcrypt/bcrypt.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'order_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? userData;
  String? verificationCode;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot snapshot = await _firestore.collection('users').doc(user.uid).get();
      if (snapshot.exists) {
        setState(() {
          userData = snapshot.data() as Map<String, dynamic>;
        });
      }
    }
  }

  Future<void> _sendVerificationEmail(String newEmail) async {
    verificationCode = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('email_verifications').doc(user.uid).set({
        'code': verificationCode,
        'newEmail': newEmail,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mã xác minh đã được gửi đến $newEmail. Vui lòng kiểm tra email!')),
      );
    }
  }

  Future<void> _showVerificationDialog(String newEmail) async {
    final TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác minh Email'),
        content: TextField(
          controller: codeController,
          decoration: InputDecoration(labelText: 'Nhập mã xác minh'),
          keyboardType: TextInputType.number,
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
                DocumentSnapshot doc = await _firestore.collection('email_verifications').doc(user.uid).get();
                if (doc.exists) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  if (data['code'] == codeController.text.trim()) {
                    try {
                      await user.updateEmail(newEmail);
                      await _firestore.collection('users').doc(user.uid).update({
                        'email': newEmail,
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã cập nhật Email')),
                      );
                      _loadUserData();
                      await _firestore.collection('email_verifications').doc(user.uid).delete();
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Mã xác minh không đúng!')),
                    );
                  }
                }
              }
            },
            child: Text('Xác minh'),
          ),
        ],
      ),
    );
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
                    String newEmail = controller.text.trim();
                    await _sendVerificationEmail(newEmail);
                    await _showVerificationDialog(newEmail);
                  } else if (field == 'Tên') {
                    await _firestore.collection('users').doc(user.uid).update({
                      'name': controller.text.trim(),
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã cập nhật $field')),
                    );
                    _loadUserData();
                    Navigator.pop(context);
                  } else if (field == 'Địa chỉ') {
                    await _firestore.collection('users').doc(user.uid).update({
                      'address': controller.text.trim(),
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã cập nhật $field')),
                    );
                    _loadUserData();
                    Navigator.pop(context);
                  } else if (field == 'Tuổi') {
                    await _firestore.collection('users').doc(user.uid).update({
                      'age': int.tryParse(controller.text.trim()) ?? 0,
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã cập nhật $field')),
                    );
                    _loadUserData();
                    Navigator.pop(context);
                  } else if (field == 'Giới tính') {
                    await _firestore.collection('users').doc(user.uid).update({
                      'gender': controller.text.trim(),
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã cập nhật $field')),
                    );
                    _loadUserData();
                    Navigator.pop(context);
                  }
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

    String formattedDate = 'Không xác định';

    if (userData?['created_at'] != null) {
      var createdAt = userData!['created_at'];

      if (createdAt is Timestamp) {
        formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toDate());
      } else if (createdAt is int) {
        formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(createdAt));
      } else if (createdAt is double) {
        formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(createdAt.toInt()));
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
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
            value: userData?['name'] ?? 'Không có tên',
            onTap: () => _showEditDialog(
              field: 'Tên',
              initialValue: userData?['name'] ?? 'Không có tên',
              label: 'Nhập tên mới',
            ),
          ),
          Divider(),
          _buildProfileItem(
            icon: Icons.email,
            title: 'Email',
            value: userData?['email'] ?? 'Không có email',
            onTap: () => _showEditDialog(
              field: 'Email',
              initialValue: userData?['email'] ?? 'Không có email',
              label: 'Nhập email mới',
              keyboardType: TextInputType.emailAddress,
            ),
            isEmail: true,
          ),
          // profile_screen.dart
          _buildProfileItem(
            icon: Icons.lock,
            title: 'Mật khẩu (Hash)',
            value: userData?['password'] ?? 'Không có dữ liệu',
            onTap: () async {
              TextEditingController newPasswordController = TextEditingController();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Đổi mật khẩu'),
                  content: TextField(
                    controller: newPasswordController,
                    decoration: InputDecoration(labelText: 'Mật khẩu mới'),
                    obscureText: true,
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text('Hủy')),
                    ElevatedButton(
                      onPressed: () async {
                        User? user = _auth.currentUser;
                        if (user != null) {
                          try {
                            await user.updatePassword(newPasswordController.text.trim());
                            String hashedPassword = BCrypt.hashpw(newPasswordController.text.trim(), BCrypt.gensalt());
                            await _firestore.collection('users').doc(user.uid).update({'password': hashedPassword});
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã đổi mật khẩu')));
                            Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                          }
                        }
                      },
                      child: Text('Lưu'),
                    ),
                  ],
                ),
              );
            },
          ),
          Divider(),
          _buildProfileItem(
            icon: Icons.location_on,
            title: 'Địa chỉ',
            value: userData?['address'] ?? 'Không có địa chỉ',
            onTap: () => _showEditDialog(
              field: 'Địa chỉ',
              initialValue: userData?['address'] ?? 'Không có địa chỉ',
              label: 'Nhập địa chỉ mới',
            ),
          ),
          Divider(),
          _buildProfileItem(
            icon: Icons.calendar_today,
            title: 'Ngày tạo',
            value: formattedDate,
            onTap: () {},
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
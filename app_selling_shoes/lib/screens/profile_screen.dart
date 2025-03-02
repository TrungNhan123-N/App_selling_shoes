import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' as foundation; // Import để kiểm tra web
import '../files/saved_addresses_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Map<String, dynamic>? userData;
  File? _imageFile;

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

  Future<void> _pickImage() async {
    if (foundation.kIsWeb) {
      // Xử lý cho web (thêm logic nếu cần, ví dụ: sử dụng input HTML)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chức năng chọn ảnh chưa hỗ trợ trên web')),
      );
      return;
    }

    // Chỉ cho phép trên mobile (Android/iOS)
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    User? user = _auth.currentUser;
    if (user != null && _imageFile != null) {
      try {
        // Tải ảnh lên Firebase Storage
        String fileName = 'avatars/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        UploadTask uploadTask = _storage.ref(fileName).putFile(_imageFile!);
        TaskSnapshot snapshot = await uploadTask;
        String downloadURL = await snapshot.ref.getDownloadURL();

        // Lưu URL ảnh vào Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'avatarUrl': downloadURL,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã cập nhật avatar')),
        );
        _loadUserData(); // Cập nhật lại dữ liệu để hiển thị ảnh mới
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
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
                  _loadUserData(); // Tải lại dữ liệu để cập nhật giao diện
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

    String? avatarUrl = userData?['avatarUrl'];
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
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.purple[100], // Màu nền tím nhạt giống hình
                      child: avatarUrl != null
                          ? ClipOval(
                        child: Image.network(
                          avatarUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.person, size: 40, color: Colors.grey);
                          },
                        ),
                      )
                          : Icon(Icons.person, size: 40, color: Colors.grey),
                    ),
                    Positioned(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.edit, color: Colors.orange, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 16),
                Text(
                  userData?['name'] ?? 'Nguyễn Trung Nhân',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
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
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Đăng xuất'),
                  onTap: () async {
                    await _auth.signOut();
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  },
                ),
              ],
            ),
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
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: TextStyle(color: Colors.grey),
          ),
          Text(
            isEmail ? 'Xác minh ngay' : 'Thay đổi ngay',
            style: TextStyle(color: Colors.orange),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
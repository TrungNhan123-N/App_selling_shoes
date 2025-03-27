import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'user_list_screen.dart';
import 'product_management_screen.dart';
import 'admin_order_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController stockController = TextEditingController();

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
  void _addProduct() async {
    if (nameController.text.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng điền ít nhất tên và giá sản phẩm")),
      );
      return;
    }

    // Kiểm tra XSS
    RegExp htmlTagRegExp = RegExp(r'<[^>]+>');
    if (htmlTagRegExp.hasMatch(nameController.text) || htmlTagRegExp.hasMatch(descriptionController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tên và mô tả không được chứa mã HTML")),
      );
      return;
    }

    // Kiểm tra giá và số lượng tồn kho
    double? price = double.tryParse(priceController.text.trim());
    int? stock = int.tryParse(stockController.text.trim());
    if (price == null || price <= 0 || stock == null || stock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Giá phải lớn hơn 0 và số lượng tồn kho không âm")),
      );
      return;
    }

    // Kiểm tra URL hình ảnh
    String imageUrl = imageUrlController.text.trim();
    if (!imageUrl.startsWith('https://') && imageUrl.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("URL hình ảnh phải bắt đầu bằng https://")),
      );
      return;
    }

    try {
      DocumentReference docRef = await _firestore.collection('products').add({
        'name': nameController.text.trim(),
        'price': price,
        'image_url': imageUrl,
        'description': descriptionController.text.trim(),
        'category_id': categoryController.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
        'stock': stock,
      });
      print("Đã thêm sản phẩm với ID: ${docRef.id}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã thêm sản phẩm thành công")),
      );
    } catch (e) {
      print("Lỗi khi thêm sản phẩm: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi thêm sản phẩm: $e")),
      );
      return;
    }

    nameController.clear();
    priceController.clear();
    imageUrlController.clear();
    descriptionController.clear();
    categoryController.clear();
    stockController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard"),
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Thêm sản phẩm mới",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Tên sản phẩm",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: priceController,
              decoration: InputDecoration(
                labelText: "Giá (USD)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            TextField(
              controller: imageUrlController,
              decoration: InputDecoration(
                labelText: "URL hình ảnh",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: "Mô tả",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: categoryController,
              decoration: InputDecoration(
                labelText: "Danh mục",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: stockController,
              decoration: InputDecoration(
                labelText: "Số lượng tồn kho",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
              ),
              child: Text("Thêm sản phẩm", style: TextStyle(color: Colors.white)),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductManagementScreen()),
                );
              },
              child: Text("Quản lý sản phẩm"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminUserManagementScreen()),
                );
              },
              child: Text("Xem danh sách người dùng"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminOrderManagementScreen()),
                );
              },
              child: Text("Quản lý trạng thái đơn hàng"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Đăng xuất"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
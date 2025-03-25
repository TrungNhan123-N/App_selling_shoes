// admin_dash_board_screen.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'user_list_screen.dart';
import 'product_management_screen.dart';
import 'admin_order_management_screen.dart'; // Thêm import mới

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class AuthStatus {
  static bool isAdmin = false;
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref().child('products');
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController stockController = TextEditingController(); // Thêm controller cho stock

  void _addProduct() async {
    if (nameController.text.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng điền ít nhất tên và giá sản phẩm")),
      );
      return;
    }

    String key = _database.push().key!;
    await _database.child(key).set({
      'id': key,
      'name': nameController.text.trim(),
      'price': double.tryParse(priceController.text.trim()) ?? 0.0,
      'image_url': imageUrlController.text.trim(),
      'description': descriptionController.text.trim(),
      'category_id': categoryController.text.trim(),
      'created_at': ServerValue.timestamp,
      'stock': int.tryParse(stockController.text.trim()) ?? 0, // Lấy giá trị stock từ TextField
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Đã thêm sản phẩm thành công")),
    );

    nameController.clear();
    priceController.clear();
    imageUrlController.clear();
    descriptionController.clear();
    categoryController.clear();
    stockController.clear(); // Xóa giá trị stock
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
                  MaterialPageRoute(builder: (_) => UserListScreen()),
                );
              },
              child: Text("Xem danh sách người dùng"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminOrderManagementScreen()), // Cập nhật điều hướng
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
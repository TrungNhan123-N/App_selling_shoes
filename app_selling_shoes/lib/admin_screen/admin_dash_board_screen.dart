import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:app_selling_shoes/admin_screen/user_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController stockController = TextEditingController();

  File? _selectedImage; // Dùng cho di động
  Uint8List? _selectedImageBytes; // Dùng cho web
  String? _selectedImageExtension; // Lưu định dạng file để tạo Base64
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedExtensions = ['png', 'jpg', 'jpeg', 'gif'];

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

  // Chọn ảnh bằng file_picker
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        withData: true, // Đảm bảo lấy dữ liệu bytes trên web
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;

        // Kiểm tra kích thước file
        if (file.size > maxFileSize) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Ảnh quá lớn (tối đa 5MB)")),
          );
          return;
        }

        // Kiểm tra định dạng file
        String extension = file.extension?.toLowerCase() ?? '';
        if (!allowedExtensions.contains(extension)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Định dạng ảnh không hợp lệ")),
          );
          return;
        }

        setState(() {
          _selectedImageExtension = extension;
          if (kIsWeb) {
            // Trên web, sử dụng bytes từ file
            _selectedImageBytes = file.bytes;
            _selectedImage = null; // Không dùng File trên web
          } else {
            // Trên di động, sử dụng File
            _selectedImage = File(file.path!);
            _selectedImageBytes = null; // Không dùng bytes trên di động
          }
        });
      }
    } catch (e) {
      print("Lỗi khi chọn ảnh: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi chọn ảnh: $e")),
      );
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

    String? imageUrl;
    if (kIsWeb && _selectedImageBytes != null) {
      // Trên web, sử dụng _selectedImageBytes
      imageUrl = "data:image/$_selectedImageExtension;base64,${base64Encode(_selectedImageBytes!)}";
      // Không băm Base64 nữa
    } else if (!kIsWeb && _selectedImage != null) {
      // Trên di động, sử dụng _selectedImage
      final bytes = await _selectedImage!.readAsBytes();
      imageUrl = "data:image/${_selectedImage!.path.split('.').last};base64,${base64Encode(bytes)}";
      // Không băm Base64 nữa
    } else {
      imageUrl = ''; // Nếu không chọn ảnh, để trống
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

    // Xóa dữ liệu sau khi thêm
    nameController.clear();
    priceController.clear();
    descriptionController.clear();
    categoryController.clear();
    stockController.clear();
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
      _selectedImageExtension = null;
    });
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
            ElevatedButton(
              onPressed: _pickImage,
              child: Text("Chọn ảnh"),
            ),
            if (kIsWeb && _selectedImageBytes != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Image.memory(
                  _selectedImageBytes!,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              ),
            if (!kIsWeb && _selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Image.file(
                  _selectedImage!,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
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
                  MaterialPageRoute(builder: (_) =>  AdminUserManagementScreen()),
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
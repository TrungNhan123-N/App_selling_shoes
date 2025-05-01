import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'authentications/login_screen.dart';

class CategoryScreen extends StatelessWidget {
  final String category;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CategoryScreen({required this.category});

  @override
  Widget build(BuildContext context) {
    // Kiểm tra trạng thái đăng nhập
    User? user = _auth.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      });
      return Scaffold(
        body: Center(child: Text("Đang chuyển hướng đến đăng nhập...")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('products')
            .where('category_id', isEqualTo: category)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            if (snapshot.error.toString().contains('permission-denied')) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Bạn không có quyền truy cập dữ liệu này."),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => LoginScreen()),
                        );
                      },
                      child: Text("Đăng nhập lại"),
                    ),
                  ],
                ),
              );
            }
            return Center(child: Text("Đã xảy ra lỗi: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Không có sản phẩm trong danh mục này"));
          }

          List<Map<String, dynamic>> productList = [];
          try {
            productList = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'key': doc.id,
                'name': data['name'] != null ? data['name'].toString() : 'Không có tên',
                'price': data['price']?.toDouble() ?? 0.0,
                'image_url': data['image_url'] != null ? data['image_url'].toString() : null,
                'description': data['description'] != null ? data['description'].toString() : null,
                'category_id': data['category_id'] != null ? data['category_id'].toString() : null,
                'created_at': data['created_at'],
                'stock': data['stock'] as int?,
              };
            }).toList();
          } catch (e) {
            return Center(child: Text("Lỗi xử lý dữ liệu: $e"));
          }

          return ListView.builder(
            itemCount: productList.length,
            itemBuilder: (context, index) {
              final product = productList[index];
              return ListTile(
                leading: product['image_url'] != null
                    ? Image.network(
                  product['image_url'] as String,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.image_not_supported);
                  },
                )
                    : Icon(Icons.category),
                title: Text(product['name'] as String),
                subtitle: Text('\$${product['price'].toStringAsFixed(2)}'),
                onTap: () {
                  Navigator.pushNamed(context, '/product_detail', arguments: product);
                },
              );
            },
          );
        },
      ),
    );
  }
}
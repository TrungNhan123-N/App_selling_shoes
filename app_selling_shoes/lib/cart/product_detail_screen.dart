import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({required this.product, Key? key}) : super(key: key);

  Future<void> addToCart(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng đăng nhập để thêm vào giỏ hàng")),
      );
      return;
    }

    final cartRef = FirebaseFirestore.instance.collection('carts');
    final productId = product['id'].toString();

    // In productId để kiểm tra
    print("Product ID being added: $productId");

    // Kiểm tra xem sản phẩm đã có trong giỏ hàng chưa
    final cartQuery = await cartRef
        .where('user_id', isEqualTo: user.uid)
        .where('product_id', isEqualTo: product['id'])
        .get();

    // In kết quả truy vấn để kiểm tra
    print("Cart query result: ${cartQuery.docs.length} items found");
    if (cartQuery.docs.isNotEmpty) {
      print("Existing cart item: ${cartQuery.docs.first.data()}");
    }

    try {
      if (cartQuery.docs.isNotEmpty) {
        // Sản phẩm đã có trong giỏ hàng, tăng số lượng
        final cartItem = cartQuery.docs.first;
        int currentQuantity = int.tryParse(cartItem['quantity'].toString()) ?? 1;
        int stock = int.tryParse(product['stock'].toString()) ?? 0;
        if (currentQuantity + 1 > stock) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Số lượng vượt quá tồn kho")),
          );
          return;
        }
        await cartItem.reference.update({'quantity': currentQuantity + 1});
        print("Updated quantity for product $productId to ${currentQuantity + 1}");
      } else {
        // Sản phẩm chưa có, thêm mới
        int stock = int.tryParse(product['stock'].toString()) ?? 0;
        if (stock < 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Sản phẩm đã hết hàng")),
          );
          return;
        }
        await cartRef.add({
          'user_id': user.uid,
          'product_id': productId,
          'name': product['name'],
          'price': product['price'],
          'image_url': product['image_url'],
          'quantity': 1,
          'created_at': DateTime.now().millisecondsSinceEpoch / 1000, // Định dạng giây, khớp với web
        });
        print("Added new product $productId to cart");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã thêm vào giỏ hàng")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi thêm vào giỏ hàng: $e")),
      );
      print("Error adding to cart: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product['name'] ?? 'Không có tên')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: product['image_url'] != null &&
                      product['image_url'].toString().startsWith('data:image/')
                  ? Image.memory(
                      base64Decode(product['image_url'].toString().split(',').last),
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.image_not_supported, size: 200),
                    )
                  : product['image_url'] != null
                      ? Image.network(
                          product['image_url'],
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.image_not_supported, size: 200),
                        )
                      : Icon(Icons.image_not_supported, size: 200),
            ),
            SizedBox(height: 20),
            Text(
              product['name'] ?? 'Không có tên',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "\$${product['price']}",
              style: TextStyle(fontSize: 18, color: Colors.red),
            ),
            SizedBox(height: 10),
            Text(
              product['description'] ?? 'Không có mô tả',
              style: TextStyle(fontSize: 16),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => addToCart(context),
                  child: Text("Thêm vào giỏ hàng"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/checkout', arguments: product);
                  },
                  child: Text("Mua ngay"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
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

    final cartRef = FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(product['key']);

    try {
      DocumentSnapshot cartSnapshot = await cartRef.get();
      if (cartSnapshot.exists) {
        int currentQuantity = (cartSnapshot.data() as Map<String, dynamic>)['quantity'];
        if (currentQuantity + 1 > product['stock']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Số lượng vượt quá tồn kho")),
          );
          return;
        }
        await cartRef.update({
          'quantity': FieldValue.increment(1),
        });
      } else {
        if (product['stock'] < 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Sản phẩm đã hết hàng")),
          );
          return;
        }
        await cartRef.set({
          'productId': product['key'],
          'name': product['name'],
          'image_url': product['image_url'],
          'price': product['price'],
          'quantity': 1,
          'user_id': user.uid,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã thêm vào giỏ hàng")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi thêm vào giỏ hàng: $e")),
      );
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
              child: product['image_url'] != null
                  ? Image.network(
                product['image_url'],
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: 200),
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
                  onPressed: () => addToCart(context), // Truyền context vào hàm
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
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
    final cartQuery = await cartRef
        .where('user_id', isEqualTo: user.uid)
        .where('product_id', isEqualTo: product['id'])
        .get();

    try {
      if (cartQuery.docs.isNotEmpty) {
        final cartItem = cartQuery.docs.first;
        int currentQuantity = cartItem['quantity'];
        if (currentQuantity + 1 > product['stock']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Số lượng vượt quá tồn kho")),
          );
          return;
        }
        await cartItem.reference.update({'quantity': FieldValue.increment(1)});
      } else {
        if (product['stock'] < 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Sản phẩm đã hết hàng")),
          );
          return;
        }
        await cartRef.add({
          'user_id': user.uid,
          'product_id': product['id'],
          'name': product['name'],
          'price': product['price'],
          'image_url': product['image_url'],
          'quantity': 1,
          'created_at': DateTime.now().millisecondsSinceEpoch,
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
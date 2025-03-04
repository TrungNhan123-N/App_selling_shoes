import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({required this.product, Key? key}) : super(key: key);

  Future<void> addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartItemRef = FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(product['id']);

    final cartItemDoc = await cartItemRef.get();

    if (cartItemDoc.exists) {
      cartItemRef.update({
        'quantity': FieldValue.increment(1),
      });
    } else {
      await cartItemRef.set({
        'productId': product['id'],
        'name': product['name'],
        'image_url': product['image_url'],
        'price': product['price'],
        'quantity': 1,
        'user_id': user.uid,
        'created_at': FieldValue.serverTimestamp(),
      });
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
                  onPressed: () async {
                    await addToCart();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Đã thêm vào giỏ hàng")),
                    );
                  },
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

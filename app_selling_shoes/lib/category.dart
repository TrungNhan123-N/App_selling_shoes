import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CategoryScreen extends StatelessWidget {
  final String category;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CategoryScreen({required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('products').where('category_id', isEqualTo: category).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Không có sản phẩm trong danh mục này"));
          }

          final products = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: product['image_url'] != null
                    ? Image.network(product['image_url'], width: 50, height: 50, fit: BoxFit.cover)
                    : Icon(Icons.category),
                title: Text(product['name'] ?? 'Không có tên'),
                subtitle: Text('\$${product['price']?.toStringAsFixed(2) ?? '0.00'}'),
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


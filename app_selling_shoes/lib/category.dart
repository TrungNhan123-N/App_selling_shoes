// lib/category.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class CategoryScreen extends StatelessWidget {
  final String category;
  final DatabaseReference _database = FirebaseDatabase.instance.ref().child('products');

  CategoryScreen({required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: StreamBuilder(
        stream: _database.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(child: Text("Không có sản phẩm trong danh mục này"));
          }

          Map<dynamic, dynamic> products = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          List<Map<String, dynamic>> productList = [];
          products.forEach((key, value) {
            productList.add(Map<String, dynamic>.from(value)..['key'] = key);
          });

          final filteredProducts = productList.where((product) => product['category_id'] == category).toList();

          return filteredProducts.isEmpty
              ? Center(child: Text("Không có sản phẩm trong danh mục này"))
              : ListView.builder(
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
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
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CategoryScreen extends StatelessWidget {
  final String category;
  final DatabaseReference _productsRef = FirebaseDatabase.instance.ref('products');

  CategoryScreen({required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: StreamBuilder(
        stream: _productsRef.orderByChild('category').equalTo(category).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final data = snapshot.data!.snapshot.value as Map?;
          if (data == null) return Center(child: Text("Không có sản phẩm trong danh mục này"));
          final products = data.entries.map((e) => Map<String, dynamic>.from(e.value)).toList();

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: Icon(Icons.category),
                title: Text(product['name']),
                subtitle: Text(product['description']),
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
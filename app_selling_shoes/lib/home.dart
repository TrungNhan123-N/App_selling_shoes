import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'category.dart';

class HomeScreen extends StatelessWidget {
  final DatabaseReference _productsRef = FirebaseDatabase.instance.ref('products');
  final List<String> categories = ["Sneakers", "Formal", "Casual", "Boots", "Sandals"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shoe Store'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm (có thể thêm logic tìm kiếm sau)
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search for shoes...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          // Danh mục
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryScreen(category: categories[index])));
                },
                child: Container(
                  margin: EdgeInsets.all(8),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text(categories[index], style: TextStyle(color: Colors.white))),
                ),
              ),
            ),
          ),
          // Banner
          Container(
            margin: EdgeInsets.all(10),
            height: 150,
            color: Colors.orangeAccent,
            child: Center(child: Text("Promotional Banner", style: TextStyle(fontSize: 20, color: Colors.white))),
          ),
          // Sản phẩm nổi bật từ Realtime Database
          Expanded(
            child: StreamBuilder(
              stream: _productsRef.orderByChild('featured').equalTo(true).limitToFirst(10).onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final data = snapshot.data!.snapshot.value as Map?;
                if (data == null) return Center(child: Text("Không có sản phẩm"));
                final products = data.entries.map((e) => Map<String, dynamic>.from(e.value)).toList();

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      leading: Icon(Icons.shopping_bag),
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
          ),
        ],
      ),
    );
  }
}
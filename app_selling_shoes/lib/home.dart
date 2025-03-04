import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'category.dart';
import 'main_screen.dart';

class HomeScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> categories = ["Sneakers", "Formal", "Casual", "Boots", "Sandals"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shoe Store'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              final mainScreenState = MainScreen.globalKey.currentState;
              // mainScreenState?._onItemTapped(1); // Chuyển sang tab Cart
            },
          ),
        ],
      ),
      body: Column(
        children: [
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
          Container(
            margin: EdgeInsets.all(10),
            height: 150,
            color: Colors.orangeAccent,
            child: Center(child: Text("Promotional Banner", style: TextStyle(fontSize: 20, color: Colors.white))),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('products').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("Không có sản phẩm"));
                }

                final products = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      leading: product['image_url'] != null
                          ? Image.network(product['image_url'], width: 50, height: 50, fit: BoxFit.cover)
                          : Icon(Icons.shopping_bag),
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
          ),
        ],
      ),
    );
  }
}
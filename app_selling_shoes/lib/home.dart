import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'category.dart';
import 'main_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> categories = ["Sneakers", "Formal", "Casual", "Boots", "Sandals"];

  String _searchQuery = ''; // Từ khóa tìm kiếm

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
          // Thanh tìm kiếm
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase(); // Cập nhật từ khóa tìm kiếm
                });
              },
              decoration: InputDecoration(
                hintText: "Search for shoes...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          // Danh mục sản phẩm
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CategoryScreen(category: categories[index])),
                  );
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
          // Banner khuyến mãi
          Container(
            margin: EdgeInsets.all(10),
            height: 150,
            color: Colors.orangeAccent,
            child: Center(
              child: Text("Promotional Banner", style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
          ),
          // Danh sách sản phẩm từ Firestore (có tìm kiếm)
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

                // Lọc sản phẩm theo từ khóa tìm kiếm
                final products = snapshot.data!.docs
                    .map((doc) => doc.data() as Map<String, dynamic>)
                    .where((product) =>
                        product['name'].toString().toLowerCase().contains(_searchQuery))
                    .toList();

                return products.isEmpty
                    ? Center(child: Text("Không tìm thấy sản phẩm"))
                    : ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ListTile(
                            leading: product['image_url'] != null
                                ? Image.network(
                                    product['image_url'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
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

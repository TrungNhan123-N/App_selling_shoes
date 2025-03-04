import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart'; // Import thư viện carousel_slider
import 'category.dart';
import 'main_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> categories = ["Sneakers", "Formal", "Casual", "Boots", "Sandals"];

  String _searchQuery = '';

  final List<String> promoImages = [
    "https://img.pikbest.com/templates/20240728/banner-sale-banner-introducing-shoe-shop-_10686281.jpg!sw800",
    "https://bizweb.dktcdn.net/100/458/331/files/giay-bong-da-mercurial-vapor-15.jpg?v=1724004904722",
    "https://img.pikbest.com/origin/10/04/45/889pIkbEsTcqs.jpg!w700wp",
  ];

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
          // Banner khuyến mãi tự động chuyển đổi
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: CarouselSlider(
              options: CarouselOptions(
                height: 150,
                autoPlay: true, // Tự động chạy
                autoPlayInterval: Duration(seconds: 3), // Chuyển ảnh sau mỗi 3 giây
                enlargeCenterPage: true,
                viewportFraction: 0.9,
              ),
              items: promoImages.map((imageUrl) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity),
                );
              }).toList(),
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

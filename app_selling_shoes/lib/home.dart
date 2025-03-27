import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'authentications/login_screen.dart';
import 'category.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Thêm FirebaseAuth
  final List<String> categories = ["Sneakers", "Formal", "Casual", "Boots", "Sandals"];

  String _searchQuery = '';

  final List<String> promoImages = [
    "https://img.pikbest.com/templates/20240728/banner-sale-banner-introducing-shoe-shop-_10686281.jpg!sw800",
    "https://bizweb.dktcdn.net/100/458/331/files/giay-bong-da-mercurial-vapor-15.jpg?v=1724004904722",
    "https://img.pikbest.com/origin/10/04/45/889pIkbEsTcqs.jpg!w700wp",
  ];

  @override
  Widget build(BuildContext context) {
    // Kiểm tra trạng thái đăng nhập
    User? user = _auth.currentUser;

    if (user == null) {
      // Nếu chưa đăng nhập, chuyển hướng đến màn hình đăng nhập
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      });
      return Scaffold(
        body: Center(child: Text("Đang chuyển hướng đến đăng nhập...")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Text('Shoe Store', semanticsLabel: 'home_screen'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
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
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: CarouselSlider(
              options: CarouselOptions(
                height: 150,
                autoPlay: true,
                autoPlayInterval: Duration(seconds: 3),
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('products').orderBy('created_at', descending: true).snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  // Xử lý lỗi permission-denied
                  if (snapshot.error.toString().contains('permission-denied')) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Bạn không có quyền truy cập dữ liệu này."),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => LoginScreen()),
                              );
                            },
                            child: Text("Đăng nhập lại"),
                          ),
                        ],
                      ),
                    );
                  }
                  return Center(child: Text("Đã xảy ra lỗi: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("Không có sản phẩm"));
                }

                List<Map<String, dynamic>> productList = [];
                try {
                  productList = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return {
                      'key': doc.id,
                      'name': data['name'] != null ? data['name'].toString() : 'Không có tên',
                      'price': data['price']?.toDouble() ?? 0.0,
                      'image_url': data['image_url'] != null ? data['image_url'].toString() : null,
                      'description': data['description'] != null ? data['description'].toString() : null,
                      'category_id': data['category_id'] != null ? data['category_id'].toString() : null,
                      'created_at': data['created_at'],
                      'stock': data['stock'] as int?,
                    };
                  }).toList();
                } catch (e) {
                  return Center(child: Text("Lỗi xử lý dữ liệu: $e"));
                }

                final filteredProducts = productList
                    .where((product) => product['name'].toString().toLowerCase().contains(_searchQuery))
                    .toList();

                return filteredProducts.isEmpty
                    ? Center(child: Text("Không tìm thấy sản phẩm"))
                    : ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return ListTile(
                      leading: product['image_url'] != null && product['image_url'].isNotEmpty
                          ? Image.network(
                        product['image_url'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.broken_image, size: 50, color: Colors.red);
                        },
                      )
                          : Icon(Icons.image, size: 50, color: Colors.grey),
                      title: Text(product['name'] as String),
                      subtitle: Text('\$${product['price'].toStringAsFixed(2)}'),
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
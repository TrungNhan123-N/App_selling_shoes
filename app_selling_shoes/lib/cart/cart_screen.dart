import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double totalPrice = 0.0;

  Future<void> _updateQuantity(String productId, int quantity) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final cartQuery = await _firestore
        .collection('carts')
        .where('user_id', isEqualTo: user.uid)
        .where('product_id', isEqualTo: productId)
        .get();

    if (cartQuery.docs.isNotEmpty) {
      final docId = cartQuery.docs.first.id;
      final docRef = _firestore.collection('carts').doc(docId);

      if (quantity <= 0) {
        await docRef.delete();
      } else {
        await docRef.update({'quantity': quantity});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Giỏ hàng')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('carts')
            .where('user_id', isEqualTo: _auth.currentUser!.uid)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Giỏ hàng trống.'));
          }

          List<Map<String, dynamic>> cartList = snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return {
              'user_id': data['user_id'],
              'product_id': data['product_id'],
              'name': data['name'],
              'price': data['price'],
              'image_url': data['image_url'],
              'quantity': data['quantity'],
              'created_at': data['created_at'],
            };
          }).toList();

          totalPrice = cartList.fold(0.0, (sum, item) {
            double price = double.tryParse(item['price'].toString()) ?? 0.0;
            int quantity = int.tryParse(item['quantity'].toString()) ?? 1;
            return sum + price * quantity;
          });

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartList.length,
                  itemBuilder: (context, index) {
                    var item = cartList[index];
                    return Card(
                      margin: EdgeInsets.all(10),
                      child: ListTile(
                        leading: item['image_url'] != null &&
                                item['image_url']
                                    .toString()
                                    .startsWith('data:image/')
                            ? Image.memory(
                                base64Decode(item['image_url']
                                    .toString()
                                    .split(',')
                                    .last),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.image_not_supported, size: 50),
                              )
                            : item['image_url'] != null
                                ? Image.network(
                                    item['image_url'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                            Icons.image_not_supported,
                                            size: 50),
                                  )
                                : Icon(Icons.image_not_supported, size: 50),
                        title: Text(item['name']),
                        subtitle: Text("Giá: \$${item['price']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: () => _updateQuantity(
                                  item['product_id'], item['quantity'] - 1),
                            ),
                            Text("${item['quantity']}"),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () => _updateQuantity(
                                  item['product_id'], item['quantity'] + 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tổng tiền:',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("\$${totalPrice.toStringAsFixed(2)}",
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.red,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/checkout');
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: Text("Thanh toán",
                          style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

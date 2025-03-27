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

  Future<void> _updateQuantity(String key, int quantity) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final itemRef = _firestore.collection('carts').doc(user.uid).collection('items').doc(key);

    if (quantity <= 0) {
      await itemRef.delete();
    } else {
      await itemRef.update({'quantity': quantity});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Giỏ hàng')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('carts').doc(_auth.currentUser!.uid).collection('items').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Giỏ hàng trống.'));
          }

          List<Map<String, dynamic>> cartList = snapshot.data!.docs.map((doc) {
            return {
              'key': doc.id,
              ...doc.data() as Map<String, dynamic>,
            };
          }).toList();

          totalPrice = cartList.fold(0.0, (sum, item) {
            return sum + (double.tryParse(item['price'].toString()) ?? 0.0) * item['quantity'];
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
                        leading: Image.network(
                          item['image_url'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: 50),
                        ),
                        title: Text(item['name']),
                        subtitle: Text("Giá: \$${item['price']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: () => _updateQuantity(item['key'], item['quantity'] - 1),
                            ),
                            Text("${item['quantity']}"),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () => _updateQuantity(item['key'], item['quantity'] + 1),
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
                        Text('Tổng tiền:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("\$${totalPrice.toStringAsFixed(2)}", style: TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/checkout');
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: Text("Thanh toán", style: TextStyle(fontSize: 18, color: Colors.white)),
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
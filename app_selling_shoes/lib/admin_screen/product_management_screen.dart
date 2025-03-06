// product_management_screen.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ProductManagementScreen extends StatefulWidget {
  @override
  _ProductManagementScreenState createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref().child('products');
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

  void _addProduct() async {
    if (nameController.text.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng điền đầy đủ thông tin")),
      );
      return;
    }

    String key = _database.push().key!; // Tạo key duy nhất
    await _database.child(key).set({
      'id': key,
      'name': nameController.text.trim(),
      'price': double.parse(priceController.text.trim()),
      'image_url': imageUrlController.text.trim(),
      'description': descriptionController.text.trim(),
      'category_id': categoryController.text.trim(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Đã thêm sản phẩm")),
    );

    _clearFields();
  }

  void _editProduct(String key, Map<String, dynamic> product) {
    nameController.text = product['name'];
    priceController.text = product['price'].toString();
    imageUrlController.text = product['image_url'];
    descriptionController.text = product['description'];
    categoryController.text = product['category_id'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Sửa sản phẩm"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: "Tên")),
              TextField(controller: priceController, decoration: InputDecoration(labelText: "Giá"), keyboardType: TextInputType.number),
              TextField(controller: imageUrlController, decoration: InputDecoration(labelText: "URL hình ảnh")),
              TextField(controller: descriptionController, decoration: InputDecoration(labelText: "Mô tả")),
              TextField(controller: categoryController, decoration: InputDecoration(labelText: "Danh mục")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              await _database.child(key).update({
                'name': nameController.text.trim(),
                'price': double.parse(priceController.text.trim()),
                'image_url': imageUrlController.text.trim(),
                'description': descriptionController.text.trim(),
                'category_id': categoryController.text.trim(),
              });
              Navigator.pop(context);
              _clearFields();
            },
            child: Text("Lưu"),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(String key) async {
    await _database.child(key).remove();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Đã xóa sản phẩm")),
    );
  }

  void _clearFields() {
    nameController.clear();
    priceController.clear();
    imageUrlController.clear();
    descriptionController.clear();
    categoryController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Quản lý sản phẩm")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Tên sản phẩm")),
            TextField(controller: priceController, decoration: InputDecoration(labelText: "Giá"), keyboardType: TextInputType.number),
            TextField(controller: imageUrlController, decoration: InputDecoration(labelText: "URL hình ảnh")),
            TextField(controller: descriptionController, decoration: InputDecoration(labelText: "Mô tả")),
            TextField(controller: categoryController, decoration: InputDecoration(labelText: "Danh mục")),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _addProduct, child: Text("Thêm sản phẩm")),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder(
                stream: _database.onValue,
                builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return Center(child: Text("Không có sản phẩm"));
                  }

                  Map<dynamic, dynamic> products = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  List<Map<String, dynamic>> productList = [];
                  products.forEach((key, value) {
                    productList.add(Map<String, dynamic>.from(value)..['key'] = key);
                  });

                  return ListView.builder(
                    itemCount: productList.length,
                    itemBuilder: (context, index) {
                      final product = productList[index];
                      return ListTile(
                        leading: product['image_url'] != null
                            ? Image.network(product['image_url'], width: 50, height: 50, fit: BoxFit.cover)
                            : Icon(Icons.image),
                        title: Text(product['name']),
                        subtitle: Text("\$${product['price']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _editProduct(product['key'], product),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _deleteProduct(product['key']),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
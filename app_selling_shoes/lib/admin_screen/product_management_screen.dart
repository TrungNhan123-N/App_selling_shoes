import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductManagementScreen extends StatefulWidget {
  @override
  _ProductManagementScreenState createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController stockController = TextEditingController();

  void _editProduct(String key, Map<String, dynamic> product) {
    nameController.text = product['name'];
    priceController.text = product['price'].toString();
    imageUrlController.text = product['image_url'];
    descriptionController.text = product['description'];
    categoryController.text = product['category_id'];
    stockController.text = product['stock']?.toString() ?? '0';

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
              TextField(controller: stockController, decoration: InputDecoration(labelText: "Số lượng tồn kho"), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              try {
                double? price = double.tryParse(priceController.text.trim());
                int? stock = int.tryParse(stockController.text.trim());
                if (price == null || stock == null || price <= 0 || stock < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Giá phải lớn hơn 0 và số lượng không âm")),
                  );
                  return;
                }
                await _firestore.collection('products').doc(key).update({
                  'name': nameController.text.trim(),
                  'price': price,
                  'image_url': imageUrlController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'category_id': categoryController.text.trim(),
                  'stock': stock,
                });
                print("Đã cập nhật sản phẩm với ID: $key");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Đã cập nhật sản phẩm")),
                );
              } catch (e) {
                print("Lỗi khi cập nhật sản phẩm: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Lỗi khi cập nhật: $e")),
                );
              }
              Navigator.pop(context);
              _clearFields();
            },
            child: Text("Lưu"),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(String key) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc muốn xóa sản phẩm này?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('products').doc(key).delete();
                print("Đã xóa sản phẩm với ID: $key");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đã xóa sản phẩm")),
                );
              } catch (e) {
                print("Lỗi khi xóa sản phẩm: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Lỗi khi xóa: $e")),
                );
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }

  void _clearFields() {
    nameController.clear();
    priceController.clear();
    imageUrlController.clear();
    descriptionController.clear();
    categoryController.clear();
    stockController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quản lý sản phẩm"),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('products').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text("Không có sản phẩm"));
            }

            List<Map<String, dynamic>> productList = snapshot.data!.docs.map((doc) {
              return {
                'key': doc.id,
                ...doc.data() as Map<String, dynamic>,
              };
            }).toList();

            return ListView.builder(
              itemCount: productList.length,
              itemBuilder: (context, index) {
                final product = productList[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: product['image_url'] != null && product['image_url'].isNotEmpty
                              ? Image.network(
                            product['image_url'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Log the invalid URL with more details
                              print("Failed to load image for product ID: ${product['key']}, URL: ${product['image_url']}, Error: $error");
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey[600],
                                  size: 30,
                                ),
                              );
                            },
                          )
                              : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.image,
                              color: Colors.grey[600],
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        // Product Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'] ?? 'Không có tên',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                "\$${product['price']?.toStringAsFixed(2) ?? '0.00'}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red[700],
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                "Tồn kho: ${product['stock'] ?? 0}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Action Buttons
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editProduct(product['key'], product),
                              tooltip: 'Chỉnh sửa',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteProduct(product['key']),
                              tooltip: 'Xóa',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product['name'] ?? 'Không có tên')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: product['image_url'] != null
                  ? Image.network(
                product['image_url'],
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: 200),
              )
                  : Icon(Icons.image_not_supported, size: 200),
            ),
            SizedBox(height: 20),
            Text(
              product['name'] ?? 'Không có tên',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "\$${product['price']?.toStringAsFixed(2) ?? '0.00'}",
              style: TextStyle(fontSize: 18, color: Colors.red),
            ),
            SizedBox(height: 10),
            Text(
              product['description'] ?? 'Không có mô tả',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Danh mục: ${product['category_id'] ?? 'Không xác định'}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Kho: ${product['stock'] ?? '0'}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            if (product['created_at'] != null)
              Text(
                'Ngày tạo: ${product['created_at'].toString().substring(0, 10) ?? 'Không xác định'}',
                style: TextStyle(fontSize: 16),
              ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/cart');
                  },
                  child: Text("Thêm vào giỏ hàng"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/checkout', arguments: product);
                  },
                  child: Text("Mua ngay"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
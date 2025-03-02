import 'package:flutter/material.dart';

class CategoryScreen extends StatelessWidget {
  final String category;

  const CategoryScreen({required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.category),
            title: Text("$category - Shoe Model $index"),
            subtitle: Text("Details of shoe model $index"),
          );
        },
      ),
    );
  }
}
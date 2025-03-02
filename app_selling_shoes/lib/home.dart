import 'package:app_selling_shoes/category.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final List<String> categories = ["Sneakers", "Formal", "Casual", "Boots", "Sandals"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shoe Store'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () => Navigator.pushNamed(context, '/orders'),
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
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryScreen(category: categories[index]),
                      ),
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
                );
              },
            ),
          ),
          Container(
            margin: EdgeInsets.all(10),
            height: 150,
            color: Colors.orangeAccent,
            child: Center(child: Text("Promotional Banner", style: TextStyle(fontSize: 20, color: Colors.white))),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.shopping_bag),
                  title: Text("New Shoe Model $index"),
                  subtitle: Text("Description of shoe model $index"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
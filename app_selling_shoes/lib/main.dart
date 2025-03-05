import 'package:app_selling_shoes/authentications/login_screen.dart';
import 'package:app_selling_shoes/firebase_options.dart';
import 'package:app_selling_shoes/tracking/tracking_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'authentications/forgot_password_screen.dart';
import 'authentications/register_screen.dart';
import 'cart/cart_screen.dart';
import 'cart/checkout_screen.dart';
import 'cart/product_detail_screen.dart';
import 'home.dart';
import 'orders/order_list_screen.dart';
import 'orders/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shoe Store App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home:LoginScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/forgot_password': (context) => ForgotPasswordScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(),
        '/orders': (context) => OrderListScreen(),
        '/cart': (context) => CartScreen(),
        '/checkout': (context) => CheckoutScreen(),
        // Sử dụng builder để xử lý arguments cho ProductDetailScreen
        '/product_detail': (context) => _buildProductDetailScreen(context),
        '/tracking': (context) => TrackingScreen(orderId: ''),
      },
    );
  }

  // Helper function to build ProductDetailScreen with arguments
  static Widget _buildProductDetailScreen(BuildContext context) {
    final arguments = ModalRoute.of(context)!.settings.arguments;
    if (arguments is Map<String, dynamic>) {
      return ProductDetailScreen(product: arguments);
    }
    return ProductDetailScreen(product: {}); // Fallback nếu không có arguments
  }
}
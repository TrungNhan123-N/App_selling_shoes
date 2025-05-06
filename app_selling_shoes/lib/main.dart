import 'package:app_selling_shoes/authentications/login_screen.dart';
import 'package:app_selling_shoes/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'authentications/forgot_password_screen.dart';
import 'authentications/register_screen.dart';
import 'cart/cart_screen.dart';
import 'cart/checkout_screen.dart';
import 'cart/product_detail_screen.dart';
import 'home.dart';
import '../profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Khởi tạo Firebase App Check với SafetyNet cho Android và DeviceCheck cho iOS
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.safetyNet, // Sử dụng SafetyNet cho Android
    appleProvider: AppleProvider.deviceCheck,  // Sử dụng DeviceCheck cho iOS
    // Trong môi trường phát triển, bạn có thể sử dụng debugProvider như sau:
    // androidProvider: AndroidProvider.debug,
    // appleProvider: AppleProvider.debug,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shoe Store App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white, // Đặt màu nền thành trắng
      ),
      home: LoginScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/forgot_password': (context) => ForgotPasswordScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(),
        '/cart': (context) => CartScreen(),
        '/checkout': (context) => CheckoutScreen(),
        '/product_detail': (context) => _buildProductDetailScreen(context),
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
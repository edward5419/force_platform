import 'package:flutter/material.dart';
import 'package:force_platform/controllers/data_repository.dart';
import 'package:force_platform/pages/home_page.dart';
import 'package:force_platform/pages/record_page.dart';
import 'package:force_platform/pages/saved_records_page.dart';
import 'package:get/get.dart';
import 'controllers/bluetooth_controller.dart';
import 'pages/measure_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(DataRepository());
  Get.put(BluetoothController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        theme: ThemeData(
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            scaffoldBackgroundColor: const Color(0xFFF4F4F4)),
        initialRoute: "/",
        getPages: [
          GetPage(name: "/", page: () => HomePage()),
          GetPage(name: "/measure_page", page: () => MeasurePage()),
          GetPage(name: "/saved_records_page", page: () => SavedRecordsPage()),
          GetPage(name: "/record_page", page: () => RecordPage())
        ],
        home: HomePage());
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:telephony/telephony.dart';

import 'message_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);

  if (await Telephony.instance.requestPhoneAndSmsPermissions == false) {
    Telephony.instance.requestPhoneAndSmsPermissions;
  }

  // Get.put(SmsController()).onInit();
  var channel = const MethodChannel('com.dovahkin.sms_guard');
  await channel.invokeMethod('bert').then((value) => print("value: $value"));

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        debugShowCheckedModeBanner: false, home: MessageList());
  }
}

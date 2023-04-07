// ignore_for_file: must_be_immutable, use_build_context_synchronously

import 'dart:developer';

import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sms_advanced/sms_advanced.dart';

import '../cubit/sms_cubit.dart';

class SendingMessageBox extends StatelessWidget {
  SendingMessageBox({
    super.key,
    required this.textController,
    required this.address,
  });

  TextEditingController textController;

  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        color: Color.fromARGB(255, 240, 240, 240),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            Expanded(
              child: AutoSizeTextField(
                // onChanged: (value) {
                //   setState(() {});
                // },
                textAlign: TextAlign.left,
                style: const TextStyle(fontSize: 17),
                maxLines: null,
                controller: textController,
                decoration: const InputDecoration(
                  hintTextDirection: TextDirection.ltr,
                  hintText: "Metin mesajı",
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.white),
                  shape: MaterialStateProperty.all(const CircleBorder())),
              color: Colors.grey,
              onPressed: () async {
                log("address: $address");
                log("text: ${textController.text}");
                SmsSender sender = SmsSender();
                sender.sendSms(SmsMessage(address, textController.text));
                var data = {"address": address, "body": textController.text};
                var channel = const MethodChannel('com.dovahkin.sms_guard');
                await channel
                    .invokeMethod('check', data)
                    .then((value) => print("value: $value"));

                textController.clear();
                BlocProvider.of<SmsCubit>(context).onNewMessage(null);
                BlocProvider.of<SmsCubit>(context)
                    .filterMessageForAdress(address);
                BlocProvider.of<SmsCubit>(context).state.text = "";
              },
              icon: Icon(Icons.send,
                  size: 30,
                  color:
                      textController.text.isEmpty ? Colors.grey : Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore_for_file: use_build_context_synchronously

import 'dart:developer';

import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sms_advanced/sms_advanced.dart';

import '../cubit/sms_cubit.dart';
import 'chat_messages_view.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  TextEditingController textEditingController = TextEditingController();
  TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title:
            const Text("Mesaj Gönder", style: TextStyle(color: Colors.black)),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: BlocConsumer<SmsCubit, SmsState>(
        listener: (context, state) {},
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  onChanged: (value) {
                    BlocProvider.of<SmsCubit>(context)
                        .prinnt(textEditingController.text);

                    context
                        .read<SmsCubit>()
                        .resultContactWithTextEditingController(
                            textEditingController.text);
                  },
                  controller: textEditingController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.person),
                    hintText: "Alıcı",
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.01,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: state.sendResult.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                        onTap: () {
                          state.name = state.sendResult[index].displayName;
                          state.text =
                              state.sendResult[index].phones.first.number;

                          log(state.name!);

                          textEditingController.text =
                              state.sendResult[index].displayName == ""
                                  ? state.sendResult[index].phones.first.number
                                  : state.sendResult[index].displayName;
                          textEditingController.selection =
                              TextSelection.fromPosition(TextPosition(
                                  offset: textEditingController.text.length));
                          context
                              .read<SmsCubit>()
                              .resultContactWithTextEditingController("");
                        },
                        title: state.sendResult[index].displayName == ""
                            ? Text(state.sendResult[index].phones.first.number)
                            : Text(state.sendResult[index].displayName));
                  },
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.02,
              ),
              BlocConsumer<SmsCubit, SmsState>(
                listener: (context, state) {},
                builder: (context, state) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
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
                                  backgroundColor:
                                      MaterialStateProperty.all(Colors.white),
                                  shape: MaterialStateProperty.all(
                                      const CircleBorder())),
                              color: Colors.grey,
                              onPressed: () async {
                                state.text = state.text!
                                    .trim()
                                    .replaceAll(" ", "")
                                    .replaceAll("-", "")
                                    .replaceAll("(", "")
                                    .replaceAll(")", "");
                                if (state.text!.startsWith("0")) {
                                  state.text =
                                      state.text!.replaceFirst("0", "+90");
                                }
                                if (state.text!.startsWith("90")) {
                                  state.text =
                                      state.text!.replaceFirst("90", "+90");
                                }
                                if (state.text!.startsWith("5")) {
                                  state.text =
                                      state.text!.replaceFirst("5", "+905");
                                }
                                log("address: ${state.text}");
                                log("text: ${textController.text}");
                                SmsSender sender = SmsSender();
                                await sender.sendSms(SmsMessage(
                                    state.text, textController.text));

                                var data = {
                                  "address": state.text,
                                  "body": textController.text
                                };
                                var channel = const MethodChannel(
                                    'com.dovahkin.sms_guard');
                                await channel
                                    .invokeMethod('check', data)
                                    .then((value) => print("value: $value"));

                                textController.clear();
                                BlocProvider.of<SmsCubit>(context)
                                    .onNewMessage(null);
                                BlocProvider.of<SmsCubit>(context)
                                    .filterMessageForAdress(state.text);

                                log("navigate");
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => MessageScreen(
                                            name: state.name!,
                                            address: state.text!)));

                                BlocProvider.of<SmsCubit>(context).state.text =
                                    "";
                                BlocProvider.of<SmsCubit>(context)
                                    .state
                                    .controller!
                                    .clear();
                              },
                              icon: Icon(Icons.send,
                                  size: 30,
                                  color: textController.text.isEmpty
                                      ? Colors.grey
                                      : Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

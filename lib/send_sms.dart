// ignore_for_file: unnecessary_null_comparison, use_build_context_synchronously, non_constant_identifier_names

import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sms_advanced/sms_advanced.dart';

import 'chat_screen.dart';
import 'controller.dart';

class SendSms extends StatefulWidget {
  const SendSms({super.key});

  @override
  State<SendSms> createState() => _SendSmsState();
}

class _SendSmsState extends State<SendSms> {
  var number = "";
  var textController = TextEditingController();
  var controller = Get.put(SmsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 0, // Burada AppBar'ın ışık teması ayarlanıyor
        backgroundColor: Colors.white,
      ),
      body: Center(
          child: Column(
        children: [
          const SizedBox(
            height: 20,
          ),
          Expanded(
            child: FutureBuilder(
                future: ContactsService.getContacts(),
                builder: (context, snapshot) {
                  return Autocomplete<Contact>(
                    displayStringForOption: (Contact option) =>
                        option.displayName!,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<Contact>.empty();
                      }
                      return snapshot.data!.where((Contact option) {
                        return option.displayName!
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (Contact selection) {
                      print("onSelected: ${selection.displayName}");
                      number = selection.phones!.first.value!.toString();
                      number = number.replaceAll(" ", "");
                      if (number[0] == "0") {
                        number = number.replaceFirst("0", "+90");
                      }
                      if (number[0] == "5") {
                        number = number.replaceFirst("5", "+905");
                      }
                    },
                    fieldViewBuilder: (BuildContext context,
                        TextEditingController fieldTextEditingController,
                        FocusNode fieldFocusNode,
                        VoidCallback onFieldSubmitted) {
                      return TextField(
                        controller: fieldTextEditingController,
                        focusNode: fieldFocusNode,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person),
                          suffixIcon: IconButton(
                              onPressed: () {
                                fieldTextEditingController.clear();
                                number = "";
                              },
                              icon: const Icon(Icons.close)),
                          labelText: 'Alıcı:',
                          border: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                        ),
                        onSubmitted: (String value) {
                          print("onSubmitted: $value");
                          onFieldSubmitted();
                        },
                      );
                    },
                    optionsViewBuilder: (BuildContext context,
                        AutocompleteOnSelected<Contact> onSelected,
                        Iterable<Contact> options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          child: SizedBox(
                            height: 200.0,
                            child: ListView(
                              padding: const EdgeInsets.all(8.0),
                              children: options.map((Contact option) {
                                return GestureDetector(
                                  onTap: () {
                                    print("onTap: ${option.displayName}");
                                    onSelected(option);
                                  },
                                  child: ListTile(
                                    title: Text(option.displayName!),
                                    // subtitle:
                                    //     option.phones!.first.value.toString() ==
                                    //             null
                                    //         ? const Text('')
                                    //         : Text(option.phones!.first.value
                                    //             .toString()),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
          ),
          bottom_message_and_icon(context),
        ],
      )),
    );
  }

  bottom_message_and_icon(context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          message_box(),
          const SizedBox(
            width: 10,
          ),
          icon_box(context),
        ],
      ),
    );
  }

  icon_box(context) {
    return IconButton(
      style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.white),
          shape: MaterialStateProperty.all(const CircleBorder())),
      color: Colors.grey,
      onPressed: textController.text.isEmpty
          ? null
          : () async {
              if (number != "") {
                SmsSender sender = SmsSender();
                sender.sendSms(SmsMessage(number, textController.text));
                var data = {"address": number, "body": textController.text};
                var channel = const MethodChannel('com.dovahkin.sms_guard');
                await channel
                    .invokeMethod('check', data)
                    .then((value) => print("value: $value"));
                controller.getThread();
                controller.getAllMessages();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Messages(
                      address: number,
                      name: number,
                    ),
                  ),
                );

                textController.clear();
              } else {}
            },
      icon: Icon(Icons.send,
          size: 30,
          color: textController.text.isEmpty && number == ""
              ? Colors.grey
              : Colors.blue),
    );
  }

  Expanded message_box() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          color: Colors.grey[200],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: AutoSizeTextField(
            onChanged: (value) {
              setState(() {});
            },
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
      ),
    );
  }
}

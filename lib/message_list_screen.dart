// ignore_for_file: invalid_use_of_protected_member

import 'package:intl/intl.dart';
import 'package:sms_guard/search_sms.dart';
import 'package:sms_guard/send_sms.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controller.dart';
import 'junk_list_screen.dart';
import 'chat_screen.dart';

class MessageList extends StatefulWidget {
  const MessageList({super.key});

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> with WidgetsBindingObserver {
  var controller = Get.put(SmsController());

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // getMessages();
      if (controller.oninit.value == false) {
        controller.getThread();
        controller.getAllMessages();
      }
      print("resume");
    }

    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orangeAccent,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SendSms(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      backgroundColor: Colors.white,
      appBar: appbar(context),
      body: Obx(() => Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  mesajlarText(),
                  textfield(context),
                ],
              ),
              controller.isLoading.value
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Colors.white, backgroundColor: Colors.grey),
                    )
                  : controller.list.isEmpty
                      ? const Center(
                          child: Text("Mesaj bulunamadı"),
                        )
                      : listview(),
            ],
          )),
    );
  }

  Padding textfield(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.grey[200],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.transparent,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(30),
                ),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchSmS(),
                ),
              );
            },
            child: TextField(
              autofocus: false,
              enabled: false,

              style: const TextStyle(color: Colors.black),

              // ignore: prefer_const_constructors
              decoration: InputDecoration(
                hintText: "${controller.allsms.value.length} mesaj",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          )),
    );
  }

  Padding mesajlarText() {
    return const Padding(
      padding: EdgeInsets.only(left: 18.0),
      child: Text(
        "Mesajlar",
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  listview() {
    return Obx(() => Expanded(
          child: ListView.builder(
            itemCount: controller.list.length,
            itemBuilder: (BuildContext context, int index) {
              return InkWell(
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Messages(
                        name: controller.list[index].contact!.fullName
                                    .toString() ==
                                "null"
                            ? controller.list[index].address.toString()
                            : controller.list[index].contact!.fullName
                                .toString(),
                        address: controller.list[index].address,
                      ),
                    ),
                  ).then((value) {
                    // getMessages();
                    setState(() {});
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 25.0,
                  ),
                  child: ListTile(
                    leading: leadingg(index),
                    trailing: trailing(index),
                    title: title(index),
                    subtitle: subtitle(index),
                  ),
                ),
              );
            },
          ),
        ));
  }

  leadingg(int index) {
    return CircleAvatar(
        backgroundColor: Colors.grey[300],
        child: controller.list[index].contact!.fullName.toString() == "null"
            // ignore: prefer_const_constructors
            ? Icon(
                Icons.person,
                color: Colors.white,
              )
            : Text(
                controller.list[index].contact!.fullName.toString().substring(
                    0,
                    controller.list[index].contact!.fullName
                                .toString()
                                .split(" ")
                                .length ==
                            1
                        ? 1
                        : 2),
                style: const TextStyle(color: Colors.white),
              ));
  }

  Text trailing(int index) {
    var message = controller.list[index].messages.first.date.toString();
    DateTime messageDate = DateTime.parse(message);
    DateTime now = DateTime.now();

    String formattedMessage;

    if (messageDate.year == now.year &&
        messageDate.month == now.month &&
        messageDate.day == now.day) {
      // Bugün gönderilmiş bir mesaj
      formattedMessage =
          '${messageDate.hour.toString().padLeft(2, '0')}:${messageDate.minute.toString().padLeft(2, '0')}';
    } else if (messageDate.year == now.year &&
        messageDate.month == now.month &&
        messageDate.day == now.day - 1) {
      // Dün gönderilmiş bir mesaj
      formattedMessage =
          'Dün ${messageDate.hour.toString().padLeft(2, '0')}:${messageDate.minute.toString().padLeft(2, '0')}';
    } else if (messageDate.year == now.year) {
      // Aynı yıl içindeki önceki günlerde gönderilmiş bir mesaj
      String monthName = DateFormat.MMMM('tr_TR').format(messageDate);
      formattedMessage = '${messageDate.day} $monthName ';
    } else {
      // Farklı yıllarda gönderilmiş bir mesaj
      formattedMessage =
          '${messageDate.year}-${messageDate.month.toString().padLeft(2, '0')}-${messageDate.day.toString().padLeft(2, '0')} ${messageDate.hour.toString().padLeft(2, '0')}:${messageDate.minute.toString().padLeft(2, '0')}';
    }

    return Text(
      formattedMessage,
      style: const TextStyle(color: Colors.grey),
    );
  }

  Text subtitle(int index) {
    return Text(controller.list[index].messages.first.body
                .toString()
                .split(" ")
                .length >
            8
        // ignore: prefer_interpolation_to_compose_strings
        ? controller.list[index].messages.first.body
                .toString()
                .split(" ")
                .sublist(0, 8)
                .join(" ") +
            "..."
        : controller.list[index].messages.first.body.toString());
  }

  AppBar appbar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 60,
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const JunkScreen(),
                ),
              );
            },
            icon: const Icon(Icons.block),
            label: const Text("Spam"),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red, // Buton metin rengi
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    20), // Buton köşelerinin yuvarlatılması
              ),
            ),
          ),
        ),
      ],
    );
  }

  Text title(int index) {
    return Text(
      controller.list[index].contact!.fullName.toString() == "null"
          ? controller.list[index].address.toString()
          : controller.list[index].contact!.fullName.toString(),
      style: const TextStyle(fontWeight: FontWeight.w500),
    );
  }
}

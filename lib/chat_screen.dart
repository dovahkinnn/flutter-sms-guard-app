// ignore_for_file: prefer_typing_uninitialized_variables, non_constant_identifier_names

import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:get/get.dart';
import 'package:sms_advanced/sms_advanced.dart';
import 'package:url_launcher/url_launcher.dart';

import 'controller.dart';

class Messages extends StatefulWidget {
  final address;
  final name;

  const Messages({super.key, required this.address, required this.name});

  @override
  State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  var textController = TextEditingController();
  var controller = Get.put(SmsController());
  final widgetKey = GlobalKey(debugLabel: 'chat_buble_listview');
  @override
  void initState() {
    controller.listenincomingmessage.stream.listen((event) {
      if (event == true) {
        print("event: $event");
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0, // Burada AppBar'ın ışık teması ayarlanıyor
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.white,
        title: Text(widget.name ?? widget.address,
            style: const TextStyle(color: Colors.black)),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Center(
        child: FutureBuilder<List<SmsMessage>>(
            future: SmsQuery().querySms(
                address: widget.address,
                kinds: [SmsQueryKind.Inbox, SmsQueryKind.Sent]),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              return Column(
                children: [
                  chat_buble_listview(snapshot),
                  bottom_message_and_icon(),
                  const SizedBox(
                    height: 10,
                  )
                ],
              );
            }),
      ),
    );
  }

  bottom_message_and_icon() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          message_box(),
          const SizedBox(
            width: 10,
          ),
          icon_box(),
        ],
      ),
    );
  }

  icon_box() {
    return IconButton(
      style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.white),
          shape: MaterialStateProperty.all(const CircleBorder())),
      color: Colors.grey,
      onPressed: () async {
        SmsSender sender = SmsSender();
        sender.sendSms(SmsMessage(widget.address, textController.text));
        var data = {"address": widget.address, "body": textController.text};
        var channel = const MethodChannel('com.dovahkin.sms_guard');
        await channel
            .invokeMethod('check', data)
            .then((value) => print("value: $value"));
        setState(() {});
        controller.onInit();
        textController.clear();
      },
      icon: Icon(Icons.send,
          size: 30,
          color: textController.text.isEmpty ? Colors.grey : Colors.green),
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

  Expanded chat_buble_listview(AsyncSnapshot<List<SmsMessage>> snapshot) {
    var position = Offset.zero;
    return Expanded(
      child: ListView.builder(
          reverse: true,
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onLongPressStart: (LongPressStartDetails details) {
                position = details.globalPosition;
              },
              onLongPress: () {
                final screenSize = MediaQuery.of(context).size;

                showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(
                      position.dx, position.dy, screenSize.width, 0),
                  items: <PopupMenuEntry>[
                    const PopupMenuItem(
                      value: 'copy',
                      child: Text('Kopyala'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Sil'),
                    ),
                  ],
                ).then((value) async {
                  if (value == 'copy') {
                    // Kopyala seçeneğine tıklandığında işlenecek kodlar burada olacak

                    Clipboard.setData(
                        ClipboardData(text: snapshot.data![index].body));
                  } else if (value == 'delete') {
                    // Sil seçeneğine tıklandığında işlenecek kodlar burada olacak

                    await SmsRemover()
                        .removeSmsById(snapshot.data![index].id!,
                            snapshot.data![index].threadId!)
                        .then((value) => print("value: $value"));
                    Get.put(SmsController()).onInit();

                    setState(() {});
                  }
                });
              },
              child: ChatBubble(
                elevation: 0,
                clipper: ChatBubbleClipper5(

                    // Check the source code for this class
                    type: snapshot.data![index].kind.toString() ==
                            "SmsMessageKind.Sent"
                        ? BubbleType.sendBubble
                        : BubbleType.receiverBubble),
                alignment: snapshot.data![index].kind.toString() ==
                        "SmsMessageKind.Sent"
                    ? Alignment.topRight
                    : Alignment.topLeft,
                margin: const EdgeInsets.all(10),
                backGroundColor: snapshot.data![index].kind.toString() ==
                        "SmsMessageKind.Sent"
                    ? Colors.green
                    : Colors.grey[100],
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Linkify(
                      style: const TextStyle(fontSize: 16),
                      onOpen: (link) {
                        launchUrl(Uri.parse(link.url));
                      },
                      text: snapshot.data![index].body!,
                    ),
                  ),
                ),
              ),
            );
          }),
    );
  }
}

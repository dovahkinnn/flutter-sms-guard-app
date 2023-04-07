import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:sms_advanced/sms_advanced.dart';

import 'package:url_launcher/url_launcher.dart';

import '../cubit/sms_cubit.dart';
import '../widgets/bottom_send_messages.dart';

class MessageScreen extends StatelessWidget {
  final String name;
  final String address;
  final TextEditingController textController = TextEditingController();

  MessageScreen({Key? key, required this.name, required this.address})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SmsCubit, SmsState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _appbar(context),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: state.filtingMessages.length,
                  itemBuilder: (BuildContext context, int index) {
                    var message = state.filtingMessages[index];
                    return _chatBuble(message, context);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SendingMessageBox(
                  textController: textController,
                  address: address,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  AppBar _appbar(BuildContext context) {
    return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: name.startsWith(RegExp(r'[0-9]'))
            ? Text(
                name,
              )
            : ListTile(
                title: Text(
                  name,
                ),
                subtitle: Text(
                  address,
                ),
              ));
  }

  _chatBuble(SmsMessage message, BuildContext context) {
    var position = Offset.zero;
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

            Clipboard.setData(ClipboardData(text: message.body!));
          } else if (value == 'delete') {
            // Sil seçeneğine tıklandığında işlenecek kodlar burada olacak

            await SmsRemover()
                .removeSmsById(message.id!, message.threadId!)
                .then((value) => print("value: $value"));
            if (context.mounted) {
              BlocProvider.of<SmsCubit>(context).onNewMessage(null);
            }
          }
        });
      },
      child: ChatBubble(
        elevation: 0,
        alignment: message.kind.toString() == "SmsMessageKind.Sent"
            ? Alignment.topRight
            : Alignment.topLeft,
        margin: const EdgeInsets.all(10),
        backGroundColor: message.kind.toString() == "SmsMessageKind.Sent"
            ? const Color.fromARGB(255, 50, 191, 113)
            : Colors.grey[100],
        clipper: ChatBubbleClipper5(

            // Check the source code for this class
            type: message.kind.toString() == "SmsMessageKind.Sent"
                ? BubbleType.sendBubble
                : BubbleType.receiverBubble),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.6,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Linkify(
              style: TextStyle(
                  fontSize: 16,
                  color: message.kind.toString() == "SmsMessageKind.Sent"
                      ? Colors.white
                      : Colors.black),
              onOpen: (link) {
                launchUrl(Uri.parse(link.url));
              },
              text: message.body!,
            ),
          ),
        ),
      ),
    );
  }
}

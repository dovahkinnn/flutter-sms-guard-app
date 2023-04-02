import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sms_advanced/sms_advanced.dart';
import 'package:telephony/telephony.dart' hide SmsMessage;

class SmsController extends GetxController {
  SmsQuery query = SmsQuery();
  var list = <SmsThread>[].obs;
  var allsms = <SmsMessage>[].obs;
  var searchController = TextEditingController().obs;
  var words = "".obs;
  var emptylist = [].obs;
  var isLoading = true.obs;
  var listenincomingmessage = false.obs;
  var oninit = false.obs;
  getThread() async {
    var threads = await query.getAllThreads.whenComplete(() {
      isLoading.value = false;
      print("allthreads");
    });
    list.value = threads;
    oninit.value = false;
  }

  getAllMessages() async {
    var sms = await query.getAllSms.whenComplete(() => print("alsms"));
    allsms.value = sms;
  }

  listen() {
    print("telephony");
    var telephony = Telephony.instance;
    telephony.listenIncomingSms(
      listenInBackground: false,
      onNewMessage: (message) async {
        print(message.date);
        Get.put(SmsController()).onInit();
        listenincomingmessage.value = true;
        await Future.delayed(const Duration(seconds: 1));
        listenincomingmessage.value = false;
      },
    );
  }

  @override
  void onInit() {
    oninit.value = true;
    getThread();
    getAllMessages();
    emptylist.bindStream(words.stream.map((event) {
      if (event.isEmpty) {
        return [];
      } else {
        return allsms.where((element) {
          try {
            var name = "";
            for (var liste in list) {
              if (liste.address == element.address) {
                if (liste.contact!.fullName != null) {
                  name = liste.contact!.fullName!;
                } else {
                  name = liste.address!;
                }
              }
            }
            return element.body!.toLowerCase().contains(event.toLowerCase()) ||
                element.address!.toLowerCase().contains(event.toLowerCase()) ||
                name.toLowerCase().contains(event.toLowerCase());
          } catch (e) {
            return false;
          }
        }).toList();
      }
    }));
    listen();

    super.onInit();
  }
}

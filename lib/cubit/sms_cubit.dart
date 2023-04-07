import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:flutter/material.dart';

import 'package:sms_advanced/sms_advanced.dart';
import 'package:sms_guard/model/my_message_model.dart';

import 'package:sqflite/sqflite.dart';
import 'package:telephony/telephony.dart' hide SmsMessage;

import '../../model/search_sms_model.dart';
import '../../model/spam_model.dart';

part 'sms_state.dart';

class SmsCubit extends Cubit<SmsState> {
  SmsCubit() : super(SmsState()) {
    Telephony.instance.listenIncomingSms(onNewMessage: onNewMessage, listenInBackground: false);

    onInit();
  }

  void onInit() async {
    SmsQuery query = SmsQuery();
    var messages = await query.getAllSms;
    List<Contact> contactList = await FastContacts.getAllContacts();
    emit(state.copyWith(isLoading: true, messages: messages));
    getSpam();
    getMessages();

    emit(state.copyWith(isLoading: false, contactList: contactList));
  }

  void prinnt(text) {
    emit(state.copyWith(text: text));
  }

  void resultContactWithTextEditingController(text) async {
    List<Contact> result = [];
    if (text == "") {
      emit(state.copyWith(sendResult: []));
    } else {
      for (var item in state.contactList) {
        if (item.displayName.toLowerCase().contains(text.toLowerCase())) {
          if (item.phones.isNotEmpty) {
            result.add(item);
          } else {
            print("telefon yok");
          }
        }
      }
    }

    emit(state.copyWith(sendResult: result));
  }

  void onNewMessage(message) async {
    getMessages();
    getSpam();

    filterMessageForAdress(state.address!);

    emit(state.copyWith(isLoading: false));
  }

  Future<void> filterMessageForAdress(address) async {
    emit(state.copyWith(address: address));
    List<SmsMessage> filtingMessages = [];
    SmsQuery query = SmsQuery();
    await query.querySms(address: address, kinds: [SmsQueryKind.Inbox, SmsQueryKind.Sent]).then((value) {
      filtingMessages = value;
      filtingMessages.sort((b, a) => b.date!.compareTo(a.date!));
      emit(state.copyWith(filtingMessages: filtingMessages.reversed.toList()));
    });
  }

  void getMessages() async {
    var fonksiyonBaslangic = DateTime.now();
    var messages = await SmsQuery().getAllSms;
    List<MyMessage> list = [];
    messages.sort((b, a) => b.date!.compareTo(a.date!));
    try {
      for (var i = 0; i < messages.length; i++) {
        if (list.isEmpty) {
          list.add(MyMessage(
              name: messages[i].address,
              lastMessage: messages[i].body,
              address: messages[i].address,
              date: messages[i].date,
              threadId: messages[i].threadId));
        }
        if (list.any((element1) => element1.threadId == messages[i].threadId)) {
          var index = list.indexOf(list.firstWhere((element1) => element1.threadId == messages[i].threadId));
          list[index].lastMessage = messages[i].body;
          list[index].date = messages[i].date;
        } else {
          list.add(MyMessage(
              name: messages[i].address,
              lastMessage: messages[i].body,
              address: messages[i].address,
              date: messages[i].date,
              threadId: messages[i].threadId));
        }
      }
    } catch (e) {
      print("hata: $e");
    }
    await FastContacts.getAllContacts().then((value) {
      if (value.isNotEmpty) {
        for (var element in value) {
          if (element.phones.isNotEmpty) {
            var phone = element.phones.first.number.toString().replaceAll(" ", "").replaceAll("-", "");
            for (var item in list) {
              if (item.address!.contains(phone)) {
                item.name = element.displayName;
              }
            }
          }
        }

        list.sort((a, b) => b.date!.compareTo(a.date!));
        emit(state.copyWith(myMessages: list, messages: messages));

        print("fonksiyon bitiş: ${DateTime.now().difference(fonksiyonBaslangic).inMilliseconds}");
      } else {
        log("contact yok");
      }
    }).catchError((e) {
      log("hata: $e");
    });
  }

  void onSearch(String search) {
    List<SearchSmsMessageModel> searchResult = [];
    if (search.isNotEmpty) {
      for (var element in state.messages) {
        for (var item in state.myMessages) {
          if (item.address == element.address) {
            if (item.name != null) {
              if (item.name!.toLowerCase().contains(search) ||
                  item.address!.toLowerCase().contains(search) ||
                  element.body!.toLowerCase().contains(search)) {
                searchResult.add(SearchSmsMessageModel(name: item.name, address: item.address, body: element.body, date: element.date));
              }
            } else {
              if (item.address!.toLowerCase().contains(search) || element.body!.toLowerCase().contains(search)) {
                searchResult.add(SearchSmsMessageModel(name: item.address, address: item.address, body: element.body, date: element.date));
              }
            }
          }
        }
      }
    }

    emit(state.copyWith(search: search, searchResult: searchResult));
  }

  void onClearSearch() {
    emit(state.copyWith(search: null, searchResult: []));
  }

  Future<void> getSpam() async {
    print("getSpam");
    final Database db = await openDatabase('SpamSMS');
    await db.query('Messages').then((value) {
      if (value.isNotEmpty) {
        emit(state.copyWith(spam: value.map((e) => Spam.fromJson(e)).toList().reversed.toList()));
      } else {
        emit(state.copyWith(spam: []));
      }
    });
  }

  void deleteSpam(Spam spam, context) async {
    showDialog(
        context: context,
        builder: (context) {
          return _alert(context, spam);
        });
  }

  _alert(BuildContext context, Spam spam) {
    return AlertDialog(
      title: const Text('Uyarı'),
      content: const Text('Bu mesajı silmek istediğinize emin misiniz?'),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('İptal')),
        TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final Database db = await openDatabase('SpamSMS');
              await db.delete('Messages', where: 'id = ?', whereArgs: [spam.id]);
              getSpam();
            },
            child: const Text('Sil')),
      ],
    );
  }
}

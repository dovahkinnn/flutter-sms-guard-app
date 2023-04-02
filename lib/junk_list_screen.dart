// ignore_for_file: unnecessary_null_comparison

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:telephony/telephony.dart';

class JunkScreen extends StatefulWidget {
  const JunkScreen({super.key});

  @override
  State<JunkScreen> createState() => _JunkScreenState();
}

class _JunkScreenState extends State<JunkScreen> {
  var junk = [];

  Future<void> startDataStreaming() async {
    final Database db = await openDatabase('SpamSMS');
    junk = await db.query('Messages');
    setState(() {
      junk = junk;
    });
  }

  @override
  void initState() {
    startDataStreaming();
    var telephony = Telephony.instance;
    telephony.listenIncomingSms(
      listenInBackground: false,
      onNewMessage: (message) async {
        print("junk");

        setState(() {
          startDataStreaming();
        });
      },
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 0, // Burada AppBar'ın ışık teması ayarlanıyor
        backgroundColor: Colors.white,
        title: const Text('Spam ', style: TextStyle(color: Colors.black)),
      ),
      body: Center(
        child: ListView.builder(
          itemCount: junk.isEmpty ? 0 : junk.length,
          itemBuilder: (BuildContext context, int index) {
            if (junk.isEmpty) {
              return const Center(
                child: Text('No Junk'),
              );
            }
            return Card(
              child: ListTile(
                subtitle: Text(junk[index]['message'],
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w500)),
                title: Text(junk[index]['address'],
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w500)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Delete'),
                          content: const Text('Are you sure?'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text('Delete'),
                              onPressed: () async {
                                final Database db =
                                    await openDatabase('SpamSMS');
                                await db.delete('Messages',
                                    where: 'id = ?',
                                    whereArgs: [junk[index]['id']]);
                                Navigator.of(context).pop();
                                setState(() {
                                  startDataStreaming();
                                });
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

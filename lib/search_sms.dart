import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'chat_screen.dart';
import 'controller.dart';

class SearchSmS extends StatefulWidget {
  const SearchSmS({super.key});

  @override
  State<SearchSmS> createState() => _SearchSmSState();
}

class _SearchSmSState extends State<SearchSmS> {
  var controller = Get.put(SmsController());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            body: Obx(
      () => Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.grey[200],
              ),
              child: textfield(),
            ),
          ),
          listview(),
        ],
      ),
    )));
  }

  TextField textfield() {
    return TextField(
      onChanged: (value) {
        controller.words.value = value;
        print(controller.words.value);
      },
      autofocus: true,
      style: const TextStyle(color: Colors.black),

      controller: controller.searchController.value,
      // ignore: prefer_const_constructors
      decoration: InputDecoration(
        suffixIcon: IconButton(
          onPressed: () {
            controller.searchController.value.clear();
            controller.words.value = "";
          },
          icon: const Icon(Icons.clear),
        ),
        hintText: "Ara",
        hintTextDirection: TextDirection.ltr,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        border: const OutlineInputBorder(
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  listview() {
    Map<String, List<String>> groupedData = {};

    for (var item in controller.emptylist) {
      if (groupedData.containsKey(item.address)) {
        groupedData[item.address]!.add(item.body!);
      } else {
        if (item.address != null) {
          groupedData[item.address!] = [item.body!];
        } else {
          groupedData[""] = [item.body!];
        }
      }
    }

    List<String> addresses = groupedData.keys.toList();
    return Expanded(
      child: groupedlistview(addresses, groupedData),
    );
  }

  groupedlistview(
      List<String> addresses, Map<String, List<String>> groupedData) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: addresses.length,
      itemBuilder: (BuildContext context, int index) {
        return inkwell(addresses, index, context, groupedData);
        // return inkwell(index, context);
      },
    );
  }

  InkWell inkwell(List<String> addresses, int index, BuildContext context,
      Map<String, List<String>> groupedData) {
    return InkWell(
      onTap: () {
        var name = "";
        for (var element in controller.list) {
          if (element.address == addresses[index]) {
            if (element.contact!.fullName == null) {
              name = element.address!;
            } else {
              name = element.contact!.fullName!;
            }
          }
        }
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Messages(
                      name: name,
                      address: addresses[index],
                    )));
        print(name);
        print(addresses[index]);
      },
      child: ListTile(
        title: title(index, addresses[index]),
        subtitle: subtitle(groupedData, addresses, index),
      ),
    );
  }

  subtitle(Map<String, List<String>> groupedData, List<String> addresses,
      int index) {
    return Text(
      groupedData[addresses[index]]!.last,
      // ignore: prefer_const_constructors
      style: TextStyle(
          fontWeight: FontWeight.normal, fontSize: 14, color: Colors.black),
    );
  }

  title(int index, String address) {
    var text = "";
    for (var element in controller.list) {
      if (element.address == address) {
        if (element.contact!.fullName == null) {
          print("null");
          text = element.address!;
        } else {
          print("not null");
          text = element.contact!.fullName!;
        }
      }
    }
    return Text(
      text,
      // ignore: prefer_const_constructors
      style: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
    );
  }
}

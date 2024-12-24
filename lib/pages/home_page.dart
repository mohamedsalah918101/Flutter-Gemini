import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  final ChatUser currentUser = ChatUser(
    id: "0",
    firstName: "User",
  );
  final ChatUser geminiUser = ChatUser(
      id: "1",
      firstName: "Gemini",
      profileImage:
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcThr7qrIazsvZwJuw-uZCtLzIjaAyVW_ZrlEQ&s");
  List<ChatMessage> messages = [];
  final Gemini gemini = Gemini.instance;
  final List<ChatUser> typingUsers = <ChatUser>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Flutter Gemini"),
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return DashChat(
        currentUser: currentUser,
        typingUsers: typingUsers,
        onSend: _sendMessage,
        messages: messages,
        inputOptions:  InputOptions(
            alwaysShowSend: true,
            trailing: [
              IconButton(
                  onPressed: _sendMediaMessage,
                  icon: const Icon(Icons.image)
              )
            ]
        ),
    );
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
      typingUsers.add(geminiUser);
    });
    try {
      String question = chatMessage.text;
      List<Uint8List>? images;
      if(chatMessage.medias?.isNotEmpty ?? false) {
        images = [File(chatMessage.medias!.first.url).readAsBytesSync()];
      }

      gemini.streamGenerateContent(question, images: images).listen((event) {
        ChatMessage? lastMessage = messages.firstOrNull;
        if (lastMessage != null && lastMessage.user == geminiUser) {
          lastMessage = messages.removeAt(0);
          String response = event.content?.parts?.fold("", (previous, current) => "$previous ${current.text}") ?? "";
          lastMessage.text += response;
          setState(() {
            messages = [lastMessage!, ...messages];
          });
        } else {
          String response = event.content?.parts?.fold("", (previous, current) => "$previous ${current.text}") ?? "";
          ChatMessage message = ChatMessage(
              user: geminiUser,
              createdAt: DateTime.now(),
              text: response
          );
          setState(() {
            messages = [message, ...messages];
          });
        }
      }).onDone(() {
        setState(() {
          typingUsers.remove(geminiUser);
        });
      });
    } catch (e) {
      print(e);
      setState(() {
        typingUsers.remove(geminiUser);
      });
    }
  }

  void _sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if(file != null){
      ChatMessage chatMessage = ChatMessage(
          user: currentUser,
          createdAt: DateTime.now(),
          text: "Describe this Picture",
          medias: [
            ChatMedia(
                url: file.path,
                fileName: "",
                type: MediaType.image
            )
          ],
      );
      _sendMessage(chatMessage);
    }
  }
}

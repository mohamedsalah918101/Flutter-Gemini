import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:http/http.dart' as http;

import '../consts.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  final String API_KEY = apiKey;

  final ChatUser _currentUser =
      ChatUser(id: "1", firstName: "Mohamed", lastName: "Salah");

  final ChatUser _gptChatUser =
      ChatUser(id: "2", firstName: "Chat", lastName: "GPT");

  final List<ChatMessage> _messages = <ChatMessage>[];
  final List<ChatUser> _typingUsers = <ChatUser>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 166, 126, 1),
        title: const Text(
          'ChatGPT',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: DashChat(
          currentUser: _currentUser,
          typingUsers: _typingUsers,
          messageOptions: const MessageOptions(
              currentUserContainerColor: Colors.black,
              containerColor: Color.fromRGBO(0, 166, 126, 1),
              textColor: Colors.white),
          inputOptions: const InputOptions(alwaysShowSend: true),
          onSend: (ChatMessage m) {
            getChatResponse(m);
          },
          messages: _messages),
    );
  }

  Future<void> getChatResponse(ChatMessage m) async {
    setState(() {
      _messages.insert(0, m);
      _typingUsers.add(_gptChatUser);
    });

    try {
      List<Map<String, dynamic>> messagesHistory = _messages.reversed.map((m) {
        return {
          'role': m.user == _currentUser ? 'user' : 'assistant',
          'content': m.text,
        };
      }).toList();

      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      int retryCount = 0;
      bool successfulRequest = false;

      while (retryCount < 5 && !successfulRequest) {
        final response = await http.post(url,
            headers: {
              "Content-Type": 'application/json',
              "Authorization": "Bearer $API_KEY"
            },
            body: jsonEncode({
              "model": "gpt-4o-mini",
              "messages": messagesHistory,
              "temperature": 0.7
            }));

        if (response.statusCode == 200) {
          final responseMessage = jsonDecode(response.body)['choices'][0]
          ['message']['content'].trim();
          setState(() {
            _messages.insert(
              0,
              ChatMessage(
                user: _gptChatUser,
                createdAt: DateTime.now(),
                text: responseMessage,
              ),
            );
          });
          successfulRequest = true;
        } else if (response.statusCode == 429) {
          retryCount++;
          await Future.delayed(Duration(seconds: 2 * retryCount));
        } else {
          setState(() {
            _messages.insert(
              0,
              ChatMessage(
                user: _gptChatUser,
                createdAt: DateTime.now(),
                text: "Error: ${response.statusCode}",
              ),
            );
          });
          break;
        }
      }

      if (!successfulRequest) {
        setState(() {
          _messages.insert(
            0,
            ChatMessage(
              user: _gptChatUser,
              createdAt: DateTime.now(),
              text: "Request failed after multiple attempts.",
            ),
          );
        });
      }
    } catch (error) {
      print("Failed to get response: $error");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get response.')));
    } finally {
      setState(() {
        _typingUsers.remove(_gptChatUser);
      });
    }
  }

}

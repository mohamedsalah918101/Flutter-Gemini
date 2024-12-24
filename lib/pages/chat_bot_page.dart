import 'dart:convert';

import 'package:chatgpt/consts.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final String API_KEY = apiKey;
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];

  Future<void> _sendMessage() async {
    final UserMessage = _controller.text;
    if (UserMessage.isNotEmpty) {
      setState(() {
        _messages.add(("you: UserMessage"));
      });
      _controller.clear();
    }
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final response = await http.post(url,
        headers: {
          "Content-Type": 'application/json',
          "Authorization": "Bearer $API_KEY"
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": [
            {"role": "user", "content": UserMessage}
          ],
          "temperature": 0.7
        }));
    if (response.statusCode == 200) {
      final responseMessage = jsonDecode(response.body)['choices']['0']
              ['message']['content']
          .trim();
      setState(() {
        _messages.add("Bot: $responseMessage");
      });
    } else {
      setState(() {
        _messages.add("Bot: Error");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat Bot"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
              child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(_messages[index]),
                    );
                  },
              )
          ),
          Row(
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Type your message here',
                ),
              ),
              IconButton(
                  onPressed: _sendMessage,
                  icon: Icon(Icons.send),
              )
            ],
          )
        ],
      ),
    );
  }
}

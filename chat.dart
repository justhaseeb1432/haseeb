
import 'dart:convert';

import 'package:ai_chat_pro/chat_message.dart';
import 'package:ai_chat_pro/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class ChatScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final String userName;
  final String userEmail;

  const ChatScreen({
    super.key,
    required this.onLogout,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  // 🔑 ENTER YOUR OPENROUTER API KEY HERE (Get free at https://openrouter.ai/keys)
  static const String _apiKey = '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';

  // Nemotron API Endpoint via OpenRouter
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  // Nemotron Model - FREE TIER
  static const String _model = 'nvidia/nemotron-3-super-120b-a12b:free';

  @override
  void initState() {
    super.initState();
    _addBotMessage("Hello! I'm Nemotron, NVIDIA's 120B parameter AI assistant. How can I help you today?");
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _callNemotronAPI(text);
      setState(() {
        _isTyping = false;
        _addBotMessage(response);
      });
    } catch (e) {
      setState(() {
        _isTyping = false;
        _addBotMessage("❌ Error: $e");
      });
    }
  }

  Future<String> _callNemotronAPI(String prompt) async {
    if (_apiKey == 'sk-or-v1-your-openrouter-key-here' ||
        _apiKey.isEmpty ||
        !_apiKey.startsWith('sk-or')) {
      return "⚠️ Please add your OpenRouter API key.\\n\\nGet one FREE at:\\nhttps://openrouter.ai/keys\\n\\nThen paste it in the code (line ~430).";
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://aichatpro.app',
          'X-Title': 'Nemotron AI',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      ).timeout(const Duration(seconds: 60));

      print('🔍 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        final error = jsonDecode(response.body);
        return "❌ API Error ${response.statusCode}: ${error['error']?['message'] ?? 'Unknown error'}";
      }
    } on FormatException {
      return "❌ Failed to parse response";
    } on Exception catch (e) {
      return "❌ Network error: $e";
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          userName: widget.userName,
          userEmail: widget.userEmail,
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
              ),
            ),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF76B900), Color(0xFF5A8F00)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nemotron AI',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            'Powered by NVIDIA (120B)',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person, color: Colors.white70),
          onPressed: _openProfile,
          tooltip: 'Profile',
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white70),
          onPressed: widget.onLogout,
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? const LinearGradient(colors: [Color(0xFF76B900), Color(0xFF5A8F00)])
                    : null,
                color: message.isUser ? null : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: message.isUser ? const Radius.circular(4) : null,
                  bottomLeft: !message.isUser ? const Radius.circular(4) : null,
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.white.withOpacity(0.9),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF76B900),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Nemotron is thinking...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Ask Nemotron...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF76B900), Color(0xFF5A8F00)]),
                borderRadius: BorderRadius.all(Radius.circular(25)),
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () async {
                  await _sendMessage();
                  await uploadUsersToDb(_messageController, _messageController);
                  uploadBotToDb(_messageController);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

Future<void> uploadBotToDb( replyController) async{
  try{
    final data = await FirebaseFirestore.instance.collection("users").add({
      "reply":replyController.text.trim(),
      "time":DateTime.now().minute,
    });
  }catch(e){
    print(e);
  }

}

Future<void> uploadUsersToDb(emailController, messageController,) async {

  try{
    final data = await FirebaseFirestore.instance.collection("users").add({
      "email":emailController.text.trim(),
      "message":messageController.text.trim(),
      "time":DateTime.now().minute,
    });
  }catch(e){
    print(e);
  }


}

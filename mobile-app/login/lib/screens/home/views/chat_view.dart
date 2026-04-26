import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';

class ChatView extends StatefulWidget {
  final Map<String, String> trans;
  final bool isDarkMode;
  final ApiService apiService;

  const ChatView({
    super.key,
    required this.trans,
    required this.isDarkMode,
    required this.apiService,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _isLoading = true;
    });
    
    _messageController.clear();

    final response = await widget.apiService.sendChatMessage(text);
    
    setState(() {
      _isLoading = false;
      if (response['reply'] != null) {
        _messages.add({'sender': 'bot', 'text': response['reply']});
      } else {
        _messages.add({'sender': 'bot', 'text': response['error'] ?? "Failed to connect."});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.greenAccent.shade700],
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.trans['ai_assistant'] ?? "AI Assistant", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(widget.trans['ask_anything'] ?? "Ask me anything about farming!", style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: _messages.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length && _isLoading) {
                return const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final msg = _messages[index];
              final isUser = msg['sender'] == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(15),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: isUser 
                        ? Colors.greenAccent.shade700 
                        : (widget.isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 0),
                      bottomRight: Radius.circular(isUser ? 0 : 20),
                    ),
                  ),
                  child: Text(
                    msg['text'] ?? '',
                    style: TextStyle(
                      color: isUser ? Colors.white : (widget.isDarkMode ? Colors.white : Colors.black87),
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: widget.isDarkMode ? Colors.black54 : Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              )
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: widget.trans['type_message'] ?? "Type a message...",
                      hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white54 : Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: widget.isDarkMode ? Colors.white10 : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.greenAccent.shade700,
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

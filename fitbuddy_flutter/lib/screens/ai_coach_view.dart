import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';

class AICoachView extends StatefulWidget {
  const AICoachView({super.key});

  @override
  State<AICoachView> createState() => _AICoachViewState();
}

class _AICoachViewState extends State<AICoachView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final aiService = context.read<AIService>();
      if (aiService.messages.isEmpty) {
        aiService.addMessage(
          'Hi! I\'m your Peregrine AI coach. I can help you with workout plans, nutrition advice, and fitness goals. What would you like to know?',
          isUser: false,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Chat Messages
            Expanded(
              child: Consumer<AIService>(
                builder: (context, aiService, child) {
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: aiService.messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == aiService.messages.length && _isTyping) {
                        return _buildTypingIndicator();
                      }
                      final message = aiService.messages[index];
                      return _buildMessageBubble(message);
                    },
                  );
                },
              ),
            ),
            
            // Quick Actions
            _buildQuickActions(),
            
            // Message Input
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue, Colors.purple],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51), // 0.2 * 255 = 51
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Coach',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Your personal fitness assistant',
                  style: TextStyle(
                    color: Colors.white.withAlpha(204), // 0.8 * 255 = 204
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showSettingsDialog(),
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.blue,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25), // 0.1 * 255 = 25
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  if (message.suggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: message.suggestions.map((suggestion) {
                        return InkWell(
                          onTap: () => _sendMessage(suggestion),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isUser 
                                  ? Colors.white.withAlpha(51)
                                  : Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isUser 
                                    ? Colors.white.withAlpha(76)
                                    : Colors.blue[200]!,
                              ),
                            ),
                            child: Text(
                              suggestion,
                              style: TextStyle(
                                color: isUser ? Colors.white : Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.blue,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.blue,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25), // 0.1 * 255 = 25
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600 + (index * 200)),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _onCreateWorkout,
            icon: const Icon(Icons.fitness_center),
            label: const Text('Create Workout'),
          ),
          ElevatedButton.icon(
            onPressed: _onGetNutrition,
            icon: const Icon(Icons.restaurant),
            label: const Text('Nutrition'),
          ),
          ElevatedButton.icon(
            onPressed: _onAnalyzeFood,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Analyze Food'),
          ),
        ],
      ),
    );
  }

  void _onCreateWorkout() async {
    final aiService = context.read<AIService>();
    setState(() => _isTyping = true);
    aiService.addMessage('Create a personalized workout for me.', isUser: true);
    final response = await aiService.getWorkoutRecommendation(
      fitnessLevel: 'intermediate',
      goals: ['strength', 'endurance'],
      availableTime: 45,
      equipment: 'Bodyweight',
    );
    aiService.addMessage(response ?? 'Sorry, I could not generate a workout.', isUser: false);
    setState(() => _isTyping = false);
    _scrollToBottom();
  }

  void _onGetNutrition() async {
    final aiService = context.read<AIService>();
    setState(() => _isTyping = true);
    aiService.addMessage('Give me personalized nutrition advice.', isUser: true);
    final response = await aiService.getNutritionAdvice(
      currentWeight: 70,
      targetWeight: 65,
      activityLevel: 'active',
      dietaryRestrictions: [],
    );
    aiService.addMessage(response ?? 'Sorry, I could not generate nutrition advice.', isUser: false);
    setState(() => _isTyping = false);
    _scrollToBottom();
  }

  void _onAnalyzeFood() async {
    final result = await Navigator.pushNamed(context, '/food-camera');
    if (result is String) {
      final aiService = context.read<AIService>();
      setState(() => _isTyping = true);
      aiService.addMessage('Analyze this food image.', isUser: true);
      final response = await aiService.analyzeFoodImage(result);
      aiService.addMessage(response ?? 'Sorry, I could not analyze the food image.', isUser: false);
      setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.blue, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25), // 0.1 * 255 = 25
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Ask your AI coach...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (text) => _sendMessage(text),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => _sendMessage(_messageController.text),
              icon: const Icon(
                Icons.send,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final aiService = context.read<AIService>();
    aiService.addMessage(text, isUser: true);
    _messageController.clear();
    setState(() => _isTyping = true);
    _scrollToBottom();

    await aiService.sendAgenticMessage(text);
    setState(() => _isTyping = false);
    _scrollToBottom();
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Coach Settings'),
        content: const Text('AI coach settings coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class AIResponse {
  final String text;
  final List<String> suggestions;

  AIResponse({
    required this.text,
    this.suggestions = const [],
  });
} 
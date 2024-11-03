// Import necessary Flutter and custom packages
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:space_gpt/bloc/chat_bloc.dart';
import 'package:space_gpt/model/chat_messgae_model.dart';
import 'package:space_gpt/screens/profile_selector_screen.dart';
import 'package:flutter/services.dart';

// In home_page.dart - Update ImageCacheManager
class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  final Map<String, ImageProvider> _imageCache = {};
  bool _initialized = false;

  Future<void> precacheAllImages(BuildContext context) async {
    if (_initialized) return;

    // Increase image cache size significantly
    PaintingBinding.instance.imageCache.maximumSize = 500;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 200 << 20; // 200 MB
    
    final imagesToCache = [
      ...ProfileSelectorScreen.userProfiles.map((p) => p.imagePath),
      ...ProfileSelectorScreen.modelProfiles.map((p) => p.imagePath),
      'assets/space_bg.jpg',
      'assets/user_avatar.jpg',
      'assets/bot_avatar.jpg',
    ];

    // Load all images simultaneously with high priority
    await Future.wait(
      imagesToCache.map((path) async {
        if (!_imageCache.containsKey(path)) {
          final provider = AssetImage(path);
          await precacheImage(provider, context, size: const Size(500, 500));
          _imageCache[path] = provider;
        }
      }),
      eagerError: true
    );

    _initialized = true;
  }
}

// StatefulWidget for the home page that maintains state
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// State class for HomePage
class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController textEditingController = TextEditingController();
  final ChatBloc chatBloc = ChatBloc();
  bool _showScrollButton = false;
  String _userProfileImage = "assets/user_avatar.jpg";
  String _modelProfileImage = "assets/bot_avatar.jpg";
  bool _isSearching = false;
  String _searchQuery = '';
  final List<ChatMessageModel> _filteredMessages = [];
  final ImageCacheManager _imageCacheManager = ImageCacheManager();
  final List<MessageGroup> _messageGroups = [];
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _precacheInitialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precacheInitialized) {
      _precacheImages();
      _precacheInitialized = true;
    }
  }

  // Add this helper method to check if we're at bottom
  bool _isAtBottom() {
    if (!_scrollController.hasClients) return true;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll - 100);
  }

  // Modify _initScrollController
  void _initScrollController() {
    _scrollController.addListener(() {
      if (!mounted) return;
      final shouldShowButton = !_isAtBottom();
      if (_showScrollButton != shouldShowButton) {
        setState(() => _showScrollButton = shouldShowButton);
      }
    });
  }

  // Update _scrollToBottom to handle button state
  void _scrollToBottom() {
    if (!mounted) return;
    // Use addPostFrameCallback to avoid build during frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        ).then((_) {
          // Update button state after scrolling
          if (mounted) {
            setState(() => _showScrollButton = !_isAtBottom());
          }
        });
      }
    });
  }

  Future<void> _precacheImages() async {
    if (!mounted) return;
    
    // Increase cache size
    PaintingBinding.instance.imageCache.maximumSize = 500;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 200 << 20; // 200 MB

    final assetImages = [
      _userProfileImage,
      _modelProfileImage,
      'assets/space_bg.jpg',
      ...ProfileSelectorScreen.userProfiles.map((p) => p.imagePath),
      ...ProfileSelectorScreen.modelProfiles.map((p) => p.imagePath),
    ];

    // Load all images simultaneously
    await Future.wait(
      assetImages.map((path) async {
        final provider = AssetImage(path);
        await precacheImage(
          provider, 
          context,
          size: const Size(500, 500)
        );
      }),
      eagerError: true
    );
  }

  // Update _clearChat to properly handle scroll button
  void _clearChat() {
    setState(() {
      chatBloc.messages.clear();
      chatBloc.emit(ChatSuccessState(messages: const []));
      _showScrollButton = false;
    });
    
    // Ensure scroll position is reset
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    textEditingController.dispose();
    super.dispose();
  }

  void _openProfileSelector(bool isUserProfile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileSelectorScreen(
          isUserProfile: isUserProfile,
          onProfileSelected: (profile) {
            setState(() {
              if (isUserProfile) {
                _userProfileImage = profile.imagePath;
              } else {
                _modelProfileImage = profile.imagePath;
              }
            });
          },
        ),
      ),
    );
  }

  // Method to handle sending messages
  void _sendMessage() {
    if (!mounted || textEditingController.text.isEmpty) return;
    
    final message = textEditingController.text;
    textEditingController.clear();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        chatBloc.add(ChatgenerateNewTextMessageEvent(inputMessage: message));
        _scrollToBottom();
      }
    });
  }

  // Add timestamp formatter function in HomePage:
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year, 
      timestamp.month, 
      timestamp.day
    );

    if (messageDate == today) {
      return "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
    } else {
      return "${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
    }
  }

  // Add this comprehensive reset method
  void _resetEverything() {
    if (!mounted) return;
    
    setState(() {
      // Clear messages
      chatBloc.messages.clear();
      chatBloc.emit(ChatSuccessState(messages: const []));
      
      // Clear text input
      textEditingController.clear();
      
      // Reset search state if implemented
      _isSearching = false;
      _searchQuery = '';
      _filteredMessages.clear();
      
      // Reset scroll button state
      _showScrollButton = false;
    });

    // Reset scroll position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  // Add methods
  void _updateMessageGroups(List<ChatMessageModel> messages) {
    _messageGroups.clear();
    
    if (messages.isEmpty) return;

    DateTime currentDate = DateTime(
      messages[0].timestamp.year,
      messages[0].timestamp.month,
      messages[0].timestamp.day,
    );
    
    List<ChatMessageModel> currentGroup = [];

    for (var message in messages) {
      final messageDate = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day,
      );

      if (messageDate == currentDate) {
        currentGroup.add(message);
      } else {
        _messageGroups.add(MessageGroup(currentDate, List.from(currentGroup)));
        currentDate = messageDate;
        currentGroup = [message];
      }
    }

    if (currentGroup.isNotEmpty) {
      _messageGroups.add(MessageGroup(currentDate, currentGroup));
    }
  }

  // Add typing indicator
  void _handleTyping() {
    if (_typingTimer?.isActive ?? false) _typingTimer!.cancel();
    
    setState(() => _isTyping = true);
    
    _typingTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isTyping = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Allow content to extend behind system UI
      extendBody: true,
      extendBodyBehindAppBar: true,
      
      // BlocConsumer to handle state changes and UI updates
      body: BlocConsumer<ChatBloc, ChatState>(
        bloc: chatBloc,
        listener: (context, state) {
          // Update loading state based on chatBloc.generating
          setState(() => _isLoading = chatBloc.generating);
        },
        builder: (context, state) {
          // Handle different chat states
          switch (state.runtimeType){
            case ChatSuccessState:
              // Extract messages from current state
              List<ChatMessageModel> messages = (state as ChatSuccessState).messages;
              return Container(
                // Full screen container with background image
                width: double.maxFinite,
                height: double.maxFinite,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    opacity: 0.7,
                    image: AssetImage("assets/space_bg.jpg"), 
                    fit: BoxFit.cover),
                ),
                child: Column(
                  children: [
                    // Header section with title and search icon
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      height: 100,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Space GPT",
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white
                            )
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 28),
                            onPressed: _resetEverything,
                          )
                        ]
                      ),
                    ),
                    
                    // Chat messages list
                    Expanded(
                      child: Stack(
                        children: [
                          RefreshIndicator(
                            color: Colors.pink.shade900,
                            onRefresh: () async {
                              setState(() {
                                chatBloc.messages.clear();
                                chatBloc.emit(ChatSuccessState(messages: const []));
                                _showScrollButton = false;
                              });
                              // Reset scroll position
                              if (_scrollController.hasClients) {
                                _scrollController.jumpTo(0);
                              }
                            },
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: messages.length,
                              padding: const EdgeInsets.all(16),
                              itemBuilder: (context, index) {
                                // Message bubble with dynamic alignment
                                return Align(
                                  alignment: messages[index].role == "user" 
                                      ? Alignment.centerRight  // User messages on right
                                      : Alignment.centerLeft,  // Bot messages on left
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      mainAxisAlignment: messages[index].role == "user" 
                                          ? MainAxisAlignment.end 
                                          : MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        if (messages[index].role != "user") 
                                          Padding(
                                            padding: const EdgeInsets.only(right: 8.0),
                                            child: GestureDetector(
                                              onTap: () => _openProfileSelector(false), // or false for model
                                              child: CircleAvatar(
                                                radius: 20,
                                                backgroundImage: AssetImage(_modelProfileImage), // or _modelProfileImage
                                              ),
                                            ),
                                          ),
                                        Column(
                                          crossAxisAlignment: messages[index].role == "user"
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                          children: [
                                            GestureDetector(
                                              onLongPress: () {
                                                Clipboard.setData(ClipboardData(
                                                  text: messages[index].parts.first.text
                                                ));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: const Text('Message copied'),
                                                    behavior: SnackBarBehavior.floating,
                                                    backgroundColor: Colors.pink.shade900,
                                                  ),
                                                );
                                              },
                                              child: RepaintBoundary(
                                                child: Container(
                                                  constraints: BoxConstraints(
                                                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(16),
                                                    color: messages[index].role == "user"
                                                        ? Colors.pink.shade900.withOpacity(0.8)
                                                        : Colors.purple.withOpacity(0.7),
                                                  ),
                                                  padding: const EdgeInsets.all(12),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      FormattedText(
                                                        text: messages[index].parts.first.text,
                                                        baseStyle: const TextStyle(
                                                          fontFamily: "Space Mono",
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          height: 1.4,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                                              child: Text(
                                                _formatTimestamp(messages[index].timestamp),
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 12,
                                                  fontFamily: "Space Mono",
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (messages[index].role == "user")
                                          Padding(
                                            padding: const EdgeInsets.only(left: 8.0),
                                            child: GestureDetector(
                                              onTap: () => _openProfileSelector(true), // or false for model
                                              child: CircleAvatar(
                                                radius: 20,
                                                backgroundImage: AssetImage(_userProfileImage), // or _modelProfileImage
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            ),
                          ),
                          if (_showScrollButton)
                            Positioned(
                              bottom: 100, // Position above text input
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black26,
                                  ),
                                  child: FloatingActionButton(
                                    mini: true,
                                    backgroundColor: Colors.pink.shade900.withOpacity(0.7),
                                    onPressed: _scrollToBottom,
                                    child: Icon(Icons.arrow_downward, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    
                    // Input section at bottom
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
                      child: Row(
                        children: [
                          // Text input field
                          Expanded(
                            child: TextField(
                              controller: textEditingController,
                              style: const TextStyle(color: Colors.black),
                              cursorColor: Theme.of(context).primaryColor,
                              onSubmitted: (_) => _sendMessage(), // Handle Enter key
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                fillColor: Colors.white,
                                filled: true,
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(100),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor))),
                            )),
                          // Spacing between input and send button
                          const SizedBox(width: 12),
                          _buildSendButton(), // Use new send button widget
                        ],
                      ),
                    )
                  ],
                ),
              );

            // Default empty state
            default:
              return const SizedBox();
          }
        },
      ),
    );
  }

  // Update _buildLoadingIndicator to only show animation
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  // Create new send button widget
  Widget _buildSendButton() {
    return InkWell(
      onTap: _isLoading ? null : () {
        if (textEditingController.text.isNotEmpty) {
          String message = textEditingController.text;
          textEditingController.clear();
          chatBloc.add(ChatgenerateNewTextMessageEvent(inputMessage: message));
          _scrollToBottom();
        }
      },
      child: CircleAvatar(
        radius: 30,
        backgroundColor: Colors.pink.shade900,
        child: _isLoading 
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.send, color: Colors.white),
      ),
    );
  }
}

// Add message grouping by date
class MessageGroup {
  final DateTime date;
  final List<ChatMessageModel> messages;

  MessageGroup(this.date, this.messages);
}

// home_page.dart - Update message display
// Add this widget for formatted text
class FormattedText extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;

  const FormattedText({
    required this.text,
    required this.baseStyle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    List<InlineSpan> spans = [];
    List<String> parts = text.split(RegExp(r'⟨[bi/nl]⟩'));
    bool isBold = false;
    bool isItalic = false;
    bool isNewLine = false;

    for (int i = 0; i < parts.length; i++) {
      String part = parts[i];
      
      if (part.isEmpty) continue;

      TextStyle style = baseStyle;
      if (isBold) style = style.copyWith(fontWeight: FontWeight.bold);
      if (isItalic) style = style.copyWith(fontStyle: FontStyle.italic);
      
      if (isNewLine && part.trim().isNotEmpty) {
        spans.add(TextSpan(text: '\n', style: style));
      }

      spans.add(TextSpan(text: part, style: style));

      if (i < parts.length - 1) {
        String tag = text.substring(
          text.indexOf('⟨', text.indexOf(parts[i])) + 1,
          text.indexOf('⟩', text.indexOf(parts[i]))
        );
        
        switch (tag) {
          case 'b': isBold = true;
          case '/b': isBold = false;
          case 'i': isItalic = true;
          case '/i': isItalic = false;
          case 'nl': isNewLine = true;
          default: isNewLine = false;
        }
      }
    }

    return RichText(text: TextSpan(children: spans));
  }
}

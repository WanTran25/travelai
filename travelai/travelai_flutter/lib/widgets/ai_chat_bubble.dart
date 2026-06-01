import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/place.dart';
import '../providers/travel_provider.dart';
import '../theme/app_theme.dart';
import 'place_card.dart';

class _ChatMessage {
  final bool isUser;
  final String text;
  final List<Place>? places;
  final bool isLoading;

  _ChatMessage({
    required this.isUser,
    required this.text,
    this.places,
    this.isLoading = false,
  });
}

class AiChatBubble extends StatefulWidget {
  final void Function(int placeId) onNavigateToDetail;

  const AiChatBubble({super.key, required this.onNavigateToDetail});

  @override
  State<AiChatBubble> createState() => _AiChatBubbleState();
}

class _AiChatBubbleState extends State<AiChatBubble>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  List<_ChatMessage> _messages = [];
  String? _lastLocation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
    _messages.add(_ChatMessage(
      isUser: false,
      text: 'Xin chào! Tôi là trợ lý AI TravelAI.\n\nHãy cho tôi biết sở thích du lịch của bạn, tôi sẽ gợi ý những địa điểm phù hợp nhất!',
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
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

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();

    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: text));
      _messages.add(_ChatMessage(isUser: false, text: '', isLoading: true));
    });
    _scrollToBottom();

    final provider = context.read<TravelProvider>();
    final detectedLocation = await provider.searchAI(text,
        contextLocation: _lastLocation);

    if (mounted) {
      if (detectedLocation != null) {
        _lastLocation = detectedLocation;
      }

      final aiSuggestions = provider.aiSuggestions;
      final allPlaces = provider.allPlaces;
      final showingSpots = aiSuggestions.isNotEmpty
          ? allPlaces.where((p) => aiSuggestions.containsKey(p.id)).toList()
          : <Place>[];

      setState(() {
        _messages.removeWhere((m) => m.isLoading);
        if (showingSpots.isNotEmpty) {
          _messages.add(_ChatMessage(
            isUser: false,
            text: 'Gợi ý cho bạn ${showingSpots.length} địa điểm phù hợp:',
            places: showingSpots,
          ));
        } else {
          _messages.add(_ChatMessage(
            isUser: false,
            text: 'Rất tiếc, không có địa điểm phù hợp với yêu cầu của bạn.',
          ));
        }
      });
      _scrollToBottom();
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add(_ChatMessage(
        isUser: false,
        text: 'Xin chào! Tôi là trợ lý AI TravelAI.\n\nHãy cho tôi biết sở thích du lịch của bạn, tôi sẽ gợi ý những địa điểm phù hợp nhất!',
      ));
    });
    context.read<TravelProvider>().clearAiSuggestions();
    _lastLocation = null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TravelProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ScaleTransition(
      scale: _scaleAnim,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background(context),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _messages.length == 1
                      ? _buildWelcome(provider)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) {
                            return _buildMessageBubble(_messages[i]);
                          },
                        ),
                ),
                _buildInputBar(bottomInset),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider(context)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentOrange, Color(0xFFFF6B35)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trợ lý AI TravelAI',
                    style: TextStyle(
                        color: AppColors.primaryText(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text('Gemini đề xuất địa điểm cho bạn',
                    style: TextStyle(
                        color: AppColors.secondaryText(context), fontSize: 11)),
              ],
            ),
          ),
          if (_messages.length > 1)
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryText(context).withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: _clearChat,
                icon: Icon(Icons.delete_outline,
                    color: AppColors.secondaryText(context), size: 20),
                tooltip: 'Xóa đoạn chat',
              ),
            ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryText(context).withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close,
                  color: AppColors.secondaryText(context), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome(TravelProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.travel_explore,
                color: AppColors.accentOrange, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            'Bạn muốn đi đâu hôm nay?',
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy nhập tin nhắn bên dưới, tôi sẽ gợi ý địa điểm cho bạn!',
            style: TextStyle(
              color: AppColors.secondaryText(context),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildCategoryChips(provider),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    if (msg.isLoading) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accentOrange,
                ),
              ),
              const SizedBox(width: 12),
              Text('Gemini đang phân tích...',
                  style: TextStyle(
                      color: AppColors.secondaryText(context), fontSize: 13)),
            ],
          ),
        ),
      );
    }

    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: AppColors.accentOrange,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(msg.text,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentOrange, Color(0xFFFF6B35)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Text(msg.text,
                        style: TextStyle(
                            color: AppColors.primaryText(context),
                            fontSize: 14)),
                  ),
                  if (msg.places != null && msg.places!.isNotEmpty)
                    ...msg.places!.map((place) => Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: PlaceCard(
                            place: place,
                            aiReason: null,
                            isFavorite:
                                context.watch<TravelProvider>().favoritesList.contains(place.id),
                            onFavoriteToggle: () => context
                                .read<TravelProvider>()
                                .toggleFavorite(place.id),
                            onCardClick: () {
                              Navigator.pop(context);
                              widget.onNavigateToDetail(place.id);
                            },
                          ),
                        )),
                  const SizedBox(height: 4),
                  Text(
                    '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                        color: AppColors.secondaryText(context), fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(double bottomInset) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        border:
            Border(top: BorderSide(color: AppColors.divider(context), width: 0.5)),
      ),
      padding: EdgeInsets.only(
        left: 12, right: 8, top: 8, bottom: 8 + bottomInset,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              style:
                  TextStyle(color: AppColors.primaryText(context), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Nhập sở thích của bạn...',
                hintStyle: TextStyle(color: AppColors.secondaryText(context)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.background(context),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.accentOrange,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(TravelProvider provider) {
    final categories = provider.categories;
    final currentCategoryId = provider.selectedCategoryId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hoặc khám phá theo danh mục',
            style: TextStyle(
                color: AppColors.secondaryText(context),
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Tất cả'),
              selected: currentCategoryId == null,
              onSelected: (_) => provider.selectedCategoryId = null,
              selectedColor: AppColors.accentOrange,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color:
                    currentCategoryId == null ? Colors.white : Colors.grey,
                fontSize: 12,
              ),
            ),
            ...categories.map((c) {
              final isSelected = currentCategoryId == c.id;
              return FilterChip(
                label: Text(c.name, style: const TextStyle(fontSize: 12)),
                selected: isSelected,
                onSelected: (_) => provider.selectedCategoryId = c.id,
                avatar: Icon(_getCategoryIcon(c.icon), size: 14),
                selectedColor: AppColors.accentOrange,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}

IconData _getCategoryIcon(String iconName) {
  switch (iconName) {
    case 'restaurant':
      return Icons.restaurant;
    case 'landmark':
      return Icons.location_on;
    case 'gamepad':
      return Icons.videogame_asset;
    case 'hotel':
      return Icons.hotel;
    case 'shopping_bag':
      return Icons.shopping_bag;
    default:
      return Icons.explore;
  }
}

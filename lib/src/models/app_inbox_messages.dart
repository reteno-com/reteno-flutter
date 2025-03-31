class AppInboxMessages {
  final List<AppInboxMessage> messages;
  final int totalPages;

  AppInboxMessages({required this.messages, required this.totalPages});
}

class AppInboxMessage {
  final String id;
  final String title;
  final String createdDate;
  final bool isNewMessage;
  final String? content;
  final String? imageUrl;
  final String? linkUrl;
  final String? category;
  final Map<String?, Object?>? customData;

  AppInboxMessage({
    required this.id,
    required this.title,
    required this.createdDate,
    required this.isNewMessage,
    this.content,
    this.imageUrl,
    this.linkUrl,
    this.category,
    this.customData,
  });

  @override
  String toString() {
    return 'AppInboxMessage(id: $id, title: $title, isNewMessage: $isNewMessage, createdDate: $createdDate, content: $content, imageUrl: $imageUrl, linkUrl: $linkUrl, category: $category)';
  }

  AppInboxMessage copyWith({
    String? id,
    String? title,
    String? createdDate,
    bool? isNewMessage,
    String? content,
    String? imageUrl,
    String? linkUrl,
    String? category,
    Map<String?, Object?>? customData,
  }) {
    return AppInboxMessage(
      id: id ?? this.id,
      title: title ?? this.title,
      createdDate: createdDate ?? this.createdDate,
      isNewMessage: isNewMessage ?? this.isNewMessage,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      linkUrl: linkUrl ?? this.linkUrl,
      category: category ?? this.category,
      customData: customData,
    );
  }
}

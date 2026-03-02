class RetenoInAppCustomData {
  RetenoInAppCustomData({
    this.url,
    required this.source,
    required this.inAppId,
    required this.data,
  });

  final String? url;
  final String source;
  final String inAppId;
  final Map<String, String> data;

  @override
  String toString() {
    return 'RetenoInAppCustomData{url: $url, source: $source, inAppId: $inAppId, data: $data}';
  }
}

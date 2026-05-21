class Utils {
  String extractEmail(String fromHeader) {
    final  emailRegex = RegExp('<(.*?)>');
    final match = emailRegex.firstMatch(fromHeader);

    if (match != null && match.groupCount >= 1) {
      return match.group(1) ?? fromHeader;
    }
    return fromHeader.trim();
  }
}


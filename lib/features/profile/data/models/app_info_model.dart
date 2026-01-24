class AppInfoContent {
  final String title;
  final String? imageUrl;
  final List<AppInfoSection> sections;

  const AppInfoContent({
    required this.title,
    this.imageUrl,
    this.sections = const [],
  });

  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;
  bool get hasSections => sections.any((section) => section.hasContent);

  factory AppInfoContent.fromResponse(
    dynamic response, {
    required String fallbackTitle,
  }) {
    final normalized = _normalizeResponse(response);
    String title = fallbackTitle;
    String? imageUrl;
    final sections = <AppInfoSection>[];

    void addSection(AppInfoSection section) {
      if (section.hasContent) {
        sections.add(section);
      }
    }

    if (normalized is Map) {
      final map = _stringKeyedMap(normalized);
      final resolvedTitle = _asString(
          map['title'] ?? map['heading'] ?? map['name'] ?? map['label']);
      if (resolvedTitle != null && resolvedTitle.trim().isNotEmpty) {
        title = resolvedTitle.trim();
      }

      imageUrl = _asString(
        map['imageUrl'] ??
            map['image'] ??
            map['bannerUrl'] ??
            map['banner'] ??
            map['coverImage'] ??
            map['heroImage'],
      );

      final primaryList = map['sections'] ??
          map['items'] ??
          map['paragraphs'] ??
          map['contents'];
      if (primaryList is List) {
        for (final item in primaryList) {
          addSection(AppInfoSection.fromDynamic(item));
        }
      }

      final contentCandidates = <dynamic>[
        map['description'],
        map['content'],
        map['body'],
        map['text'],
        map['details'],
        map['value'],
      ];

      for (final candidate in contentCandidates) {
        if (candidate == null) continue;
        addSection(AppInfoSection.fromDynamic(candidate));
      }

      for (final key in const [
        'data',
        'result',
        'payload',
        'info',
        'appInfo',
        'attributes'
      ]) {
        if (map.containsKey(key) && map[key] != null) {
          addSection(AppInfoSection.fromDynamic(map[key]));
        }
      }
    } else if (normalized is List) {
      for (final item in normalized) {
        addSection(AppInfoSection.fromDynamic(item));
      }
    } else if (normalized != null) {
      addSection(AppInfoSection.fromDynamic(normalized));
    }

    final dedupedSections = _dedupeSections(sections);

    return AppInfoContent(
      title: title.isNotEmpty ? title : fallbackTitle,
      imageUrl: imageUrl?.trim().isNotEmpty == true ? imageUrl!.trim() : null,
      sections: dedupedSections,
    );
  }
}

class AppInfoSection {
  final String? title;
  final List<String> paragraphs;

  const AppInfoSection({
    this.title,
    this.paragraphs = const [],
  });

  bool get hasTitle => title != null && title!.trim().isNotEmpty;
  bool get hasContent => paragraphs.any((p) => p.trim().isNotEmpty);

  factory AppInfoSection.fromDynamic(dynamic raw) {
    if (raw is AppInfoSection) return raw;

    if (raw is Map) {
      final map = _stringKeyedMap(raw);
      final resolvedTitle = _asString(
        map['title'] ??
            map['heading'] ??
            map['label'] ??
            map['name'] ??
            map['question'],
      );

      final paragraphs = <String>[];

      final listCandidates = [
        map['paragraphs'],
        map['contents'],
        map['items'],
        map['list'],
        map['values'],
      ];

      for (final candidate in listCandidates) {
        paragraphs.addAll(_coerceParagraphs(candidate));
      }

      final textCandidates = [
        map['description'],
        map['content'],
        map['body'],
        map['text'],
        map['details'],
        map['answer'],
        map['value'],
      ];

      for (final candidate in textCandidates) {
        paragraphs.addAll(_coerceParagraphs(candidate));
      }

      final cleaned = _dedupeParagraphs(paragraphs);

      return AppInfoSection(
        title: resolvedTitle?.trim().isNotEmpty == true
            ? resolvedTitle!.trim()
            : null,
        paragraphs: cleaned,
      );
    }

    if (raw is List) {
      final paragraphs = _coerceParagraphs(raw);
      return AppInfoSection(paragraphs: _dedupeParagraphs(paragraphs));
    }

    if (raw is String) {
      return AppInfoSection(paragraphs: _splitToParagraphs(raw));
    }

    final text = _asString(raw);
    if (text != null && text.trim().isNotEmpty) {
      return AppInfoSection(paragraphs: _splitToParagraphs(text));
    }

    return const AppInfoSection(paragraphs: []);
  }
}

class AppFaqItem {
  final String question;
  final String answer;

  const AppFaqItem({
    required this.question,
    required this.answer,
  });

  bool get hasQuestion => question.trim().isNotEmpty;
  bool get hasAnswer => answer.trim().isNotEmpty;

  factory AppFaqItem.fromDynamic(dynamic raw) {
    if (raw is AppFaqItem) return raw;

    if (raw is Map) {
      final map = _stringKeyedMap(raw);
      final question = _cleanAppInfoText(
        _asString(
            map['question'] ?? map['title'] ?? map['heading'] ?? map['label']),
      );

      String answer = '';
      final answerCandidates = [
        map['answer'],
        map['content'],
        map['description'],
        map['body'],
        map['text'],
        map['details'],
        map['response'],
        map['value'],
      ];

      for (final candidate in answerCandidates) {
        final paragraphs = _coerceParagraphs(candidate);
        if (paragraphs.isNotEmpty) {
          answer = paragraphs.join('\n\n');
          break;
        }
      }

      return AppFaqItem(
        question: question.isNotEmpty ? question : 'Frequently Asked Question',
        answer: answer,
      );
    }

    if (raw is List) {
      final items = _coerceParagraphs(raw);
      final question = items.isNotEmpty ? items.first : '';
      final answer = items.length > 1 ? items.sublist(1).join('\n\n') : '';
      return AppFaqItem(
        question: question.isNotEmpty ? question : 'Frequently Asked Question',
        answer: answer,
      );
    }

    final text = _cleanAppInfoText(_asString(raw));
    return AppFaqItem(
      question: text.isNotEmpty ? text : 'Frequently Asked Question',
      answer: '',
    );
  }

  static List<AppFaqItem> listFromResponse(dynamic response) {
    final normalized = _normalizeResponse(response);
    final items = <AppFaqItem>[];

    void add(dynamic candidate) {
      final faq = AppFaqItem.fromDynamic(candidate);
      if (faq.hasQuestion || faq.hasAnswer) {
        items.add(faq);
      }
    }

    if (normalized is List) {
      for (final item in normalized) {
        add(item);
      }
    } else if (normalized is Map) {
      final map = _stringKeyedMap(normalized);
      bool foundList = false;
      for (final key in const [
        'faqs',
        'items',
        'data',
        'list',
        'questions',
        'results'
      ]) {
        final value = map[key];
        if (value is List) {
          for (final item in value) {
            add(item);
          }
          foundList = true;
          break;
        }
      }
      if (!foundList) {
        add(map);
      }
    } else if (normalized != null) {
      add(normalized);
    }

    return items;
  }
}

List<AppInfoSection> _dedupeSections(List<AppInfoSection> sections) {
  final seen = <String>{};
  final result = <AppInfoSection>[];
  for (final section in sections) {
    if (!section.hasContent) continue;
    final key =
        '${(section.title ?? '').trim()}::${section.paragraphs.join('||')}';
    if (seen.add(key)) {
      result.add(section);
    }
  }
  return result;
}

Map<String, dynamic> _stringKeyedMap(Map input) {
  final result = <String, dynamic>{};
  input.forEach((key, value) {
    result[key.toString()] = value;
  });
  return result;
}

String? _asString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return value.toString();
}

List<String> _coerceParagraphs(dynamic value) {
  if (value == null) return const [];
  if (value is String) return _splitToParagraphs(value);
  if (value is List) {
    final result = <String>[];
    for (final item in value) {
      result.addAll(_coerceParagraphs(item));
    }
    return result;
  }
  if (value is Map) {
    final map = _stringKeyedMap(value);
    final result = <String>[];
    for (final key in const [
      'content',
      'description',
      'body',
      'text',
      'value',
      'answer',
      'details'
    ]) {
      if (map.containsKey(key)) {
        result.addAll(_coerceParagraphs(map[key]));
      }
    }
    if (result.isNotEmpty) {
      return result;
    }
    for (final entry in map.entries) {
      result.addAll(_coerceParagraphs(entry.value));
    }
    return result;
  }
  final text = _asString(value);
  if (text == null) return const [];
  return _splitToParagraphs(text);
}

List<String> _splitToParagraphs(String input) {
  final cleaned = _cleanAppInfoText(input);
  if (cleaned.isEmpty) return const [];
  final parts = cleaned.split(RegExp(r'\n{2,}'));
  final result = <String>[];
  for (final part in parts) {
    final trimmed = part.trim();
    if (trimmed.isNotEmpty) {
      result.add(trimmed);
    }
  }
  if (result.isEmpty && cleaned.isNotEmpty) {
    result.add(cleaned);
  }
  return result;
}

List<String> _dedupeParagraphs(List<String> paragraphs) {
  final seen = <String>{};
  final result = <String>[];
  for (final paragraph in paragraphs) {
    final trimmed = paragraph.trim();
    if (trimmed.isEmpty) continue;
    if (seen.add(trimmed)) {
      result.add(trimmed);
    }
  }
  return result;
}

String _cleanAppInfoText(String? input) {
  if (input == null) return '';
  var text = input;
  text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  text = text.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n');
  text = text.replaceAll(RegExp(r'<[^>]+>'), '');
  text = text.replaceAll('&nbsp;', ' ');
  text = text.replaceAll('&amp;', '&');
  text = text.replaceAll('&lt;', '<');
  text = text.replaceAll('&gt;', '>');
  text = text.replaceAll('&quot;', '"');
  text = text.replaceAll('&#39;', "'");
  text = text.replaceAll('\r', '');
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  text = text.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
  return text.trim();
}

dynamic _normalizeResponse(dynamic raw) {
  dynamic current = raw;
  final visited = <int>{};

  while (current is Map) {
    final map = current as Map;
    final id = identityHashCode(map);
    if (!visited.add(id)) {
      break;
    }
    dynamic next;
    for (final key in const [
      'data',
      'result',
      'payload',
      'info',
      'appInfo',
      'attributes'
    ]) {
      if (map.containsKey(key) && map[key] != null) {
        next = map[key];
        break;
      }
    }
    if (next == null || identical(next, current)) {
      break;
    }
    current = next;
  }

  return current;
}

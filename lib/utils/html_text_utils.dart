/// Fixes two common line-wrap glitches in WordPress content:
///
/// 1. Replaces hyphens that sit directly between two letters/digits (e.g.
///    the "-" in "Ar-Rahman") with a non-breaking hyphen (U+2011), so the
///    word can't be split across two lines.
/// 2. Glues an em dash/en dash (—/–) to the word immediately before and
///    after it using a non-breaking space (U+00A0), so a bullet like
///    "— Ar-Rahman" never has the dash stranded on its own line.
///
/// Neither changes how the text looks - only where line breaks are allowed.
///
/// Only touches text between HTML tags - it never rewrites the markup
/// itself, so hyphenated class names (e.g. "has-large-font-size") used by
/// the page's Html `style` selectors are left intact.
String preventHyphenLineBreaks(String html) {
  final tagPattern = RegExp(r'<[^>]+>');
  final buffer = StringBuffer();
  int lastEnd = 0;

  for (final match in tagPattern.allMatches(html)) {
    buffer.write(_protectDashes(html.substring(lastEnd, match.start)));
    buffer.write(match.group(0));
    lastEnd = match.end;
  }
  buffer.write(_protectDashes(html.substring(lastEnd)));

  return buffer.toString();
}

const String _nonBreakingHyphen = '‑';
const String _nonBreakingSpace = ' ';

String _protectDashes(String text) {
  var result = text.replaceAllMapped(
    RegExp(r'(\w)-(\w)'),
    (m) => '${m[1]}$_nonBreakingHyphen${m[2]}',
  );

  // Keep an em dash / en dash glued to the word right after it...
  result = result.replaceAllMapped(
    RegExp(r'([—–])[ \t]+'),
    (m) => '${m[1]}$_nonBreakingSpace',
  );
  // ...and to the word right before it.
  result = result.replaceAllMapped(
    RegExp(r'[ \t]+([—–])'),
    (m) => '$_nonBreakingSpace${m[1]}',
  );

  return result;
}

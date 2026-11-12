import 'dart:convert';

import 'package:hiddify/utils/validators.dart';

typedef ProfileLink = ({String url, String name});

// TODO: test and improve
abstract class LinkParser {
  static String generateSubShareLink(String url, [String? name]) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    // replace keeps port and userinfo, which the Uri constructor drops
    return uri.replace(fragment: name).toString();
  }

  // protocols schemas
  static const protocols = ['ios8vpn', 'hiddify', 'v2ray', 'v2rayn', 'v2rayng', 'clash', 'clashmeta', 'sing-box'];

  /// Returns the one-time pairing token from an IOS8 VPN pairing deep link.
  /// The token is not treated as a profile URL and must never be logged.
  static String? pairingToken(String link) {
    final uri = Uri.tryParse(link.trim());
    if (uri == null || uri.scheme != 'ios8vpn' || uri.host != 'pair') return null;
    final token = uri.queryParameters['token'];
    return token == null || token.isEmpty ? null : token;
  }

  static ProfileLink? parse(String link) {
    return simple(link) ?? deep(link);
  }

  static ProfileLink? simple(String link) {
    if (!isUrl(link)) return null;
    final uri = Uri.parse(link.trim());
    return (url: uri.toString(), name: uri.queryParameters['name'] ?? '');
  }

  static ProfileLink? deep(String link) {
    final uri = Uri.tryParse(link.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;
    final queryParams = uri.queryParameters;
    switch (uri.scheme) {
      case 'hiddify':
        if (queryParams.containsKey('url')) {
          // Doc form: hiddify://install-config?url=<uri>#<name> — the name lives
          // in the fragment. Prefer an explicit `name=` param, else the fragment.
          final name = (queryParams['name']?.isNotEmpty ?? false) ? queryParams['name']! : uri.fragment;
          return (url: queryParams['url']!, name: name);
        } else {
          return (url: uri.path.substring(1) + (uri.hasQuery ? "?${uri.query}" : ""), name: uri.fragment);
        }
      case 'v2ray' || 'v2rayn' || 'v2rayng' || 'clash' || 'clashmeta' || 'sing-box':
        return queryParams.containsKey('url') ? (url: queryParams['url']!, name: queryParams['name'] ?? '') : null;
      default:
        return null;
    }
  }
}

String safeDecodeBase64(String str) {
  try {
    return utf8.decode(base64Decode(str));
  } catch (e) {
    return str;
  }
}

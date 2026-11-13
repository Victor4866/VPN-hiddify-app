import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/http_client/dio_http_client.dart';
import 'package:hiddify/features/app_update/data/app_update_repository.dart';

class _Client implements DioHttpClient {
  _Client(this.releases, {this.status = 200});
  final List<dynamic> releases;
  final int status;
  String? requestedUrl;

  @override
  Future<Response<T>> get<T>(String url, {
    CancelToken? cancelToken,
    String? userAgent,
    ({String username, String password})? credentials,
    bool proxyOnly = false,
    ResponseType? responseType,
  }) async {
    requestedUrl = url;
    return Response<T>(requestOptions: RequestOptions(path: url), statusCode: status, data: releases as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _release(String repo, String version) => {
  'tag_name': 'v$version', 'draft': false,
  'html_url': 'https://github.com/$repo/releases/tag/v$version',
  'published_at': '2026-11-13T00:00:00Z', 'assets': <dynamic>[],
};

void main() {
  test('an empty IOS8 feed is a successful check with no published update', () async {
    final client = _Client([]);
    final result = await AppUpdateRepositoryImpl(httpClient: client).getLatestVersion().run();
    expect(client.requestedUrl, 'https://api.github.com/repos/Victor4866/VPN-hiddify-app/releases');
    result.match((failure) => fail('empty feed is not an HTTP failure'), (release) => expect(release, isNull));
  });

  test('an upstream Hiddify version is never an IOS8 upgrade', () async {
    final client = _Client([
      _release('hiddify/hiddify-app', '5.9.0'),
      _release('Victor4866/VPN-hiddify-app', '1.0.1'),
    ]);
    final result = await AppUpdateRepositoryImpl(httpClient: client).getLatestVersion().run();
    result.match((failure) => fail('owned release should be found'), (release) {
      expect(release?.version, '1.0.1');
      expect(release?.url, contains('Victor4866/VPN-hiddify-app/'));
    });
  });

  test('a feed containing only upstream releases offers no update', () async {
    final client = _Client([_release('hiddify/hiddify-app', '5.9.0')]);
    final result = await AppUpdateRepositoryImpl(httpClient: client).getLatestVersion().run();
    result.match((failure) => fail('no owned release is not an HTTP failure'), (release) => expect(release, isNull));
  });

  test('HTTP failure remains visible rather than being treated as no update', () async {
    final result = await AppUpdateRepositoryImpl(httpClient: _Client([], status: 503)).getLatestVersion().run();
    expect(result.isLeft(), isTrue);
  });
}

import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/http_client/dio_http_client.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/core/utils/exception_handler.dart';
import 'package:hiddify/features/app_update/data/github_release_parser.dart';
import 'package:hiddify/features/app_update/model/app_update_failure.dart';
import 'package:hiddify/features/app_update/model/remote_version_entity.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:version/version.dart';

abstract interface class AppUpdateRepository {
  TaskEither<AppUpdateFailure, RemoteVersionEntity?> getLatestVersion({
    bool includePreReleases = false,
    Release release = Release.general,
  });
}

class AppUpdateRepositoryImpl with ExceptionHandler, InfraLogger implements AppUpdateRepository {
  AppUpdateRepositoryImpl({required this.httpClient});

  final DioHttpClient httpClient;

  @override
  TaskEither<AppUpdateFailure, RemoteVersionEntity?> getLatestVersion({
    bool includePreReleases = false,
    Release release = Release.general,
  }) {
    return exceptionHandler(() async {
      if (!release.allowCustomUpdateChecker) {
        throw Exception("custom update checkers are not supported");
      }
      final response = await httpClient.get<List>(Constants.githubReleasesApiUrl);
      if (response.statusCode != 200 || response.data == null) {
        loggy.warning("failed to fetch latest version info");
        return left(const AppUpdateFailure.unexpected());
      }

      final releases = [
        for (final json in response.data!)
          if (GithubReleaseParser.parse((json as Map).cast<String, dynamic>()) case final parsed?)
            if ((includePreReleases || !parsed.preRelease) && _isOwnRelease(parsed)) parsed,
      ];
      if (releases.isEmpty) return right(null);
      // the newest by version, not by the order GitHub lists them in
      final latest = releases.reduce((a, b) => _version(b) > _version(a) ? b : a);
      return right(latest);
    }, AppUpdateFailure.unexpected);
  }

  static bool _isOwnRelease(RemoteVersionEntity release) {
    final uri = Uri.tryParse(release.url);
    final root = Uri.parse(Constants.githubUrl);
    return uri != null && uri.scheme == 'https' && uri.host == 'github.com' &&
        uri.path.toLowerCase().startsWith('${root.path.toLowerCase()}/releases/');
  }

  static Version _version(RemoteVersionEntity release) => Version.parse(release.version);
}

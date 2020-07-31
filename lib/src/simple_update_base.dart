import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

enum Platform { Android, IOS, Fuchsia, Linux, Windows, MacOS }

typedef Downloader = Stream<Event> Function(PackageInfo info, Version version);

class SimpleUpdate {
  String _apiPrefix;
  int _appId;
  String _appKey;
  http.Client _client;
  Version _version;
  PackageInfo _info;

  static final Map<String, SimpleUpdate> _cache = {};


  /// Get singleton instance by [key]
  ///
  /// ```dart
  /// var updater = SimpleUpdater();
  /// ```
  ///
  /// The default value of [apiPrefix] is *https://avenge.cn/api*, you can set your own server to publish apps.
  /// ```dart
  /// var updater = SimpleUpdate(apiPrefix: 'your own server');
  /// ```
  ///
  /// When request the latest version, it should send these parameters to remote server:
  /// >> https://avenge.cn/api/latest?app_id=[_appId]&app_key=[_appKey]&platform=0
  ///
  /// platform 0:android 1:ios 2:fuchsia 3:linux 4:windows 5:macOS
  ///
  ///
  /// Then, the remote server will send back a json:
  /// ```json
  /// {
  ///   "code": 0,
  ///   "message": "success",
  ///   "data": {
  ///    "id": 123,
  ///    "app_id": 456,
  ///    "platform": 0,
  ///    "name": "1.0.1",
  ///    "number": 24,
  ///    "src": "https://avenge.cn/storage/apps/2020-07/app_name_1.0.1+24.apk",
  ///    "sha256": "sha256 of file",
  ///    "created_at": "2020-07-29 12:15:46"
  ///   }
  /// }
  /// ```
  /// If *code* is 0, it means success.
  ///
  /// If something went wrong, it would be:
  /// ```json
  /// {
  ///   "code": -1,
  ///   "message": "something wrong ..."
  /// }
  /// ```
  factory SimpleUpdate(
      {String key = 'default',
        int appId,
        String appKey,
        String user,
        String flag,
        String apiPrefix = 'https://avenge.cn/api'}) {
    if (_cache.containsKey(key)) {
      _cache[key]
        .._appId = appId
        .._appKey = appKey
        .._apiPrefix = apiPrefix;
      return _cache[key];
    }
    _cache[key] = SimpleUpdate._internal(
        appId: appId,
        appKey: appKey,
        user: user,
        flag: flag,
        apiPrefix: apiPrefix);
    return _cache[key];
  }

  SimpleUpdate._internal(
      {int appId, String appKey, String user, String flag, String apiPrefix}) {
    _appId = appId;
    _appKey = appKey;
    _apiPrefix = apiPrefix;
    _client = http.Client();
  }

  /// Get the latest version
  ///
  /// If return null, it means there's no latest version
  Future<Version> getLatest(Platform platform) async {
    var res =
    await _client.get('$_apiPrefix/latest?app_id=$_appId&app_key=$_appKey');

    if (res.statusCode != 200) {
      return null;
    }

    if (res.body == null || res.body.isEmpty) {
      return null;
    }

    var data = jsonDecode(res.body);

    if (data == null) {
      return null;
    }

    return Version.fromJson(data['data']);
  }

  /// Check if the app has new version
  Future<bool> checkUpdate({Platform platform, PackageInfo info}) async {
    var version = await getLatest(platform);

    if (version != null && version.number > int.parse(info.buildNumber)) {
      _version = version;
      _info = info;
      return true;
    }

    return false;
  }

  /// Update to the latest version
  ///
  /// only support Android
  /// return String or Stream<Event>
  Future<dynamic> update({Platform platform, Downloader downloader}) async {
    if (platform == Platform.Android) {
      if (_version == null) {
        var version = await getLatest(platform);
        if (version == null) {
          return 'No latest version';
        }
        _version = version;
      }

      if (_version.src == null || _version.src.isEmpty) {
        return 'No resource';
      }

      try {
        return downloader(_info, _version);
      } catch (e) {
        return 'Failed to make update. Details: $e';
      }
    }
  }
}

/// Version of APP
class Version {
  final int id;
  final int appId;
  final Platform platform;
  final String name;
  final int number;
  final String src;
  final String sha256;
  final DateTime createdAt;

  Version(this.id, this.appId, this.platform, this.name, this.number, this.src,
      this.sha256, this.createdAt);

  Version.fromJson(json)
      : assert(json['created_at'] != null),
        id = json['id'],
        appId = json['app_id'],
        platform = Platform.values[json['platform']],
        name = json['name'],
        number = json['number'],
        src = json['src'],
        sha256 = json['sha256'],
        createdAt = DateTime.parse(json['created_at']);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'app_id': appId,
      'platform': platform,
      'name': name,
      'number': number,
      'src': src,
      'sha256': sha256,
      'created_at': createdAt.toString().substring(0, 19)
    };
  }

  @override
  String toString() {
    return toJson().toString();
  }
}

///Event describing current status
class Event {
  Event({this.status, this.value});

  /// Current status as enum value
  Status status;

  /// Additional status info e.g. percents downloaded or error message (can be null)
  String value;
}

/// Enum values describing states
enum Status {
  /// FILE IS BEING DOWNLOADED
  DOWNLOADING,

  /// INSTALLATION HAS BEEN TRIGGERED
  INSTALLING,

  /// DOWNLOAD IS ALREADY RUNNING
  ALREADY_RUNNING_ERROR,

  /// COULD NOT CONTINUE BECAUSE OF MISSING PERMISSIONS
  PERMISSION_NOT_GRANTED_ERROR,

  /// UNKWNON ERROR. SEE VALUE FOR MORE INFROMATION
  INTERNAL_ERROR,

  /// FILE COULD NOT BE DOWNLOADED. SEE VALUE FOR MORE INFORMATION
  DOWNLOAD_ERROR,

  /// CHECKSUM VERIFICATION FAILED. MOSTLY THIS IS DUE INCORRECT OR CORRUPTED FILE
  /// THIS IS ALSO RETURNED IF PLUGIN WAS UNABLE TO CALCULATE SHA 256 HASH OF DOWNLOADED FILE
  /// SEE VALUE FOR MORE INFORMATION
  CHECKSUM_ERROR
}

class PackageInfo {
  PackageInfo({
    this.appName,
    this.packageName,
    this.version,
    this.buildNumber,
  });


  final String appName;

  final String packageName;

  final String version;

  final String buildNumber;
}

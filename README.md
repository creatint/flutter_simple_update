Language: [English](README.md) | [中文](README_zh-CN.md)

# simple_update
![Pub Version](https://img.shields.io/pub/v/simple_update?style=flat-square)
![Platform](https://img.shields.io/badge/platform-flutter%7Cflutter%20web%7Cdart%20vm-brightgreen)

The simplest way to update app, support all platforms.

By default, the new version would be downloaded from [avenge.cn](https://avenge.cn), which is a simple Version-Management-System, welcome to try ^_^

You can set your own server to publish apps.

## Getting Started

1. Register for free

   [https://avenge.cn/register](https://avenge.cn/register)
2. Create app & create version

   [https://avenge.cn/home/resources/apps/new](https://avenge.cn/home/resources/apps/new)
   
   [https://avenge.cn/home/resources/versions/new](https://avenge.cn/home/resources/versions/new)

3. Install
   ```yaml
   dependencies:
       simple_update: ^2.0.3
   ```
   
   
4. Usage

   This is an example of Android.
   
   ```dart
   import 'package:ota_update/ota_update.dart';
   import 'package:simple_update/simple_update.dart' as simple;
   import 'package:package_info/package_info.dart';
   
   code...
   RaisedButton(
      onPressed: () async {
        var updater = new simple.SimpleUpdate(
            appId: 1,
            appKey: 'g4rehwe8fq4qe9rgh4q123');
        var info = await PackageInfo.fromPlatform();
        var res = await updater.checkUpdate(
            platform: simple.Platform.Android,
            info: simple.Info(
                appName: info.appName,
                version: info.version,
                buildNumber: info.buildNumber));
        if (res == true) {
          var re = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('New version'),
              content: Text('Install the new version?'),
              actions: [
                FlatButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel')),
                FlatButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Yes')),
              ],
            ),
          );
          if (re == true) {
            var r = await updater.update(
                platform: simple.Platform.Android,
                downloader: (info, version) {
                  return OtaUpdate()
                      .execute(
                    version.src,
                    destinationFilename:
                        '${info.appName}_${version.name}+${version.number}.apk',
                    sha256checksum: version.sha256,
                  )
                      .transform(StreamTransformer<OtaEvent,
                              simple.Event>.fromHandlers(
                          handleData: (data, sink) {
                    sink.add(simple.Event(
                        status: simple.Status.values[data.status.index],
                        value: data.value));
                  }));
                });
            if (r is Stream<simple.Event>) {
              r.listen((event) {
                switch (event.status) {
                  case simple.Status.DOWNLOADING:
                    print('downloading %${event.value}');
                    break;
                  case simple.Status.INSTALLING:
                    print('installing');
                    break;
                  case simple.Status.ALREADY_RUNNING_ERROR:
                    print('download is already running');
                    break;
                  case simple.Status.PERMISSION_NOT_GRANTED_ERROR:
                    print(
                        'could not continue because of missing permissions');
                    break;
                  case simple.Status.INTERNAL_ERROR:
                  case simple.Status.DOWNLOAD_ERROR:
                  case simple.Status.CHECKSUM_ERROR:
                    print('error ${event.value}');
                }
              });
            }
          }
        } else {
          print('no latest version');
        }
      },
      child: Text('Update'),
   )
   code...
   ```

## Build publish server

  
   The default value of [SimpleUpdate.apiPrefix] is 'https://avenge.cn/api', you can set your own server to publish apps.
   ```dart
   var updater = SimpleUpdate(apiPrefix: 'your own server');
   ```
  
  When request the latest version, it should send these parameters to remote server by GET method:
  > https://avenge.cn/api/latest?app_id=456&app_key=abc123&platform=0

  platform: 0:android 1:ios 2:fuchsia 3:linux 4:windows 5:macOS

  Then, the remote server will send back a json:
  ```json
  {
    "code": 0,
    "message": "success",
    "data": {
     "id": 123,
     "app_id": 456,
     "platform": 0,
     "name": "1.0.1",
     "number": 24,
     "src": "file url",
     "sha256": "sha256 of file",
     "created_at": "2020-07-29 12:15:46"
    }
  }
  ```
   If *code* is 0, it means success.
  
   If something went wrong, it would be:
   ```json
   {
     "code": -1,
     "message": "something wrong ..."
   }
   ```

## All projects
| Plugins                                                      | Status                                                       | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| [simple_log](https://github.com/creatint/flutter_simple_log) | ![Pub Version](https://img.shields.io/pub/v/simple_log?style=flat-square) | The simplest way to upload logs to remote server, support all platforms |
| [simple_update](https://github.com/creatint/flutter_simple_update) | ![Pub Version](https://img.shields.io/pub/v/simple_update?style=flat-square) | The simplest way to update your app, support all platforms |

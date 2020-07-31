Language: [English](README.md) | [中文](README_zh-CN.md)

# simple_update
![Pub Version](https://img.shields.io/pub/v/simple_update?style=flat-square)
![Platform](https://img.shields.io/badge/platform-flutter%7Cflutter%20web%7Cdart%20vm-brightgreen)

最简单的APP更新方式（下载并触发安装），支持所有平台。

默认情况下，会从[avenge.cn](https://avenge.cn)下载最新版本的APP，这是一个简单的APP版本管理系统，欢迎试用^_^

你也可以设置自己的服务器来发布APP新版本。

## 开始

1. 注册账号

   [https://avenge.cn/register](https://avenge.cn/register)
2. 创建应用与版本

   [https://avenge.cn/home/resources/apps/new](https://avenge.cn/home/resources/apps/new)
   
   [https://avenge.cn/home/resources/versions/new](https://avenge.cn/home/resources/versions/new)


3. 安装
   ```yaml
   dependencies:
       simple_update: ^2.0.8
   ```

4. 用法

   这是一个Android的例子
   
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
                buildNumber: int.parse(info.buildNumber)));
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
                          handleData: (event, sink) {
                    sink.add(simple.Event(
                        status: simple.Status.values[event.status.index],
                        value: event.value));
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

## 构建版本发布服务器

  
   [SimpleUpdate.apiPrefix] 的默认值是 'https://avenge.cn/api', 你可以指定自己的服务器来发布APP新版本.
   ```dart
   var updater = SimpleUpdate(apiPrefix: 'your own server');
   ```
  
  当获取新版本时，会向服务器发送一个get请求，携带如下参数
  > https://avenge.cn/api/latest?app_id=456&app_key=abc123&platform=0

  platform参数: 0:android 1:ios 2:fuchsia 3:linux 4:windows 5:macOS

  然后，服务器会返回json
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
  如果 *code* 值是 0 ，意味着提交成功。

  如果发生了错误，将会是：
  ```json
  {
    "code": -1,
    "message": "something wrong ..."
  }
  ```

## 全部项目
| 插件                                                     | 状态                                                       | 描述                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| [simple_log](https://github.com/creatint/flutter_simple_log) | ![Pub Version](https://img.shields.io/pub/v/simple_log?style=flat-square) | 最简单的日志收集方式，支持所有平台 |
| [simple_update](https://github.com/creatint/flutter_simple_update) | ![Pub Version](https://img.shields.io/pub/v/simple_update?style=flat-square) | 最简单的应用更新方式，支持所有平台 |

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import 'package:simple_update/simple_update.dart' as simple;
import 'package:package_info/package_info.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  simple.SimpleUpdate updater;
  bool downloading = false;

  @override
  void initState() {
    super.initState();
    updater = simple.SimpleUpdate(
        appId: 1,
        appKey: 'g4rehwe8fq4qe9rgh4q',
        apiPrefix: 'http://avenge.app/api');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SimpleUpdate'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RaisedButton(
              onPressed: () async {
                if (downloading) {
                  return;
                }
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
                          print(version.src);
                          print(
                              'download123 file ${info.appName}_${version.name}+${version.number}.apk');
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
                                status:
                                    simple.Status.values[event.status.index],
                                value: event.value));
                          }));
                        });
                    if (r is Stream<simple.Event>) {
                      r.listen((event) {
                        switch (event.status) {
                          case simple.Status.DOWNLOADING:
                            print('downloading %${event.value}');
                            downloading = true;
                            break;
                          case simple.Status.INSTALLING:
                            print('installing');
                            downloading = false;
                            break;
                          case simple.Status.ALREADY_RUNNING_ERROR:
                            print('download is already running');
                            downloading = false;
                            break;
                          case simple.Status.PERMISSION_NOT_GRANTED_ERROR:
                            print(
                                'could not continue because of missing permissions');
                            downloading = false;
                            break;
                          case simple.Status.INTERNAL_ERROR:
                          case simple.Status.DOWNLOAD_ERROR:
                          case simple.Status.CHECKSUM_ERROR:
                            print('error ${event.value}');
                            downloading = false;
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
          ],
        ),
      ),
    );
  }
}

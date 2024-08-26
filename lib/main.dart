import 'dart:async';
import 'dart:io';

import 'package:android_play_install_referrer/android_play_install_referrer.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  String? receivedValue;

  @override
  void initState() {
    super.initState();
    initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) async {
      debugPrint('onAppLink: $uri');
      receivedValue = await handleDeepLink(uri);
      setState(() {}); // Refresh the UI to show the new value
    });
  }

  Future<String?> handleDeepLink(Uri uri) async {
    String? value;
    bool isFirstInstall = uri.path.contains('play.google.com') || uri.path.contains('apps.apple.com');

    if (Platform.isAndroid) {
      if (isFirstInstall) {
        ReferrerDetails details = await AndroidPlayInstallReferrer.installReferrer;
        value = details.installReferrer != null ? "First Launch -> ${details.installReferrer}" : null;
      } else {
        value = "Not First Launch -> ${uri.queryParameters['districtId']}";
      }
    }

    if (Platform.isIOS) {
      if (isFirstInstall) {
        final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
        value = clipboardData?.text;
      } else {
        value = uri.queryParameters['districtId'];
      }
    }

    return value;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Default Screen')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText('''
              The app was opened via a deep link.

              Received Value: ${receivedValue ?? "No Value Received"}
              '''),
              const SizedBox(height: 20),
              IconButton(
                onPressed: () {
                  setState(() {}); // Manually refresh the screen
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

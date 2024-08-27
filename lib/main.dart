import 'dart:async';
import 'dart:io';

import 'package:android_play_install_referrer/android_play_install_referrer.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  String? receivedValue;
  String? playInstallReferrerValue;

  @override
  void initState() {
    super.initState();
    initDeepLinks();
    checkPlayInstallReferrer();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> initDeepLinks() async {
    debugPrint('Init Deep Links Called');
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) async {
      debugPrint('onAppLink: $uri');
      await handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('Failed to receive deep link: $err');
    });
  }

  Future<void> handleDeepLink(Uri uri) async {
    bool isDeepLink = !uri.path.contains('play.google.com') && !uri.path.contains('apps.apple.com');
    if (isDeepLink) {
      receivedValue = "Deep Link Value -> ${uri.queryParameters['districtId']}";
      debugPrint("Deep link detected, value: $receivedValue");
    } else {
      debugPrint("Play store URL detected, skipping deep link handling.");
    }

    // Always update the UI if a deep link is detected or if no Play Store URL is involved
    if (isDeepLink || playInstallReferrerValue == null) {
      setState(() {});
    }
  }

  Future<void> checkPlayInstallReferrer() async {
    if (Platform.isAndroid) {
      debugPrint("Checking Play Install Referrer...");
      try {
        ReferrerDetails details = await AndroidPlayInstallReferrer.installReferrer;
        if (details.installReferrer != null && details.installReferrer!.isNotEmpty) {
          playInstallReferrerValue = "Install Referrer -> ${details.installReferrer}";
          debugPrint("Install Referrer received: $playInstallReferrerValue");

          // If no deep link has been processed yet, show the install referrer
          if (receivedValue == null) {
            receivedValue = playInstallReferrerValue;
            setState(() {}); // Update UI to show referrer
          }
        } else {
          debugPrint("Install Referrer is null or empty");
        }
      } catch (e) {
        debugPrint("Error fetching Play Install Referrer: $e");
      }
    }
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
              SelectableText(
                'The app was opened via a deep link or referrer.\n\nReceived Value: ${receivedValue ?? "No Value Received"}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: checkPlayInstallReferrer,
                child: const Text('Fetch Play Install Referrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

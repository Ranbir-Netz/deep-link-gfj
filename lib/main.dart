import 'dart:async';
import 'dart:io';

import 'package:android_play_install_referrer/android_play_install_referrer.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const kWindowsScheme = 'sample';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  String? receivedValue;

  @override
  void initState() async {
    await initDeepLinks();
    super.initState();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();

    super.dispose();
  }

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle links
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) async {
      debugPrint('onAppLink: $uri');
      receivedValue = await handleDeepLink(uri);
      openAppLink(uri);
    });
  }

  void openAppLink(Uri uri) {
    _navigatorKey.currentState?.pushNamed(uri.fragment);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      initialRoute: "/",
      onGenerateRoute: (RouteSettings settings) {
        Widget routeWidget = defaultScreen();

        // Mimic web routing
        final routeName = settings.name;
        if (routeName != null) {
          if (routeName.startsWith('/book/')) {
            // Navigated to /book/:id
            routeWidget = customScreen(
              routeName.substring(routeName.indexOf('/book/')),
            );
          } else if (routeName == '/book') {
            // Navigated to /book without other parameters
            routeWidget = customScreen("None");
          }
        }

        return MaterialPageRoute(
          builder: (context) => routeWidget,
          settings: settings,
          fullscreenDialog: true,
        );
      },
    );
  }

  Widget defaultScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Default Screen')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText('''
            Launch an intent to get to the second screen.

            On web:
            http://localhost:<port>/#/book/1 for example.

            On windows & macOS, open your browser:
            sample://foo/#/book/hello-deep-linking

            This example code triggers new page from URL fragment.

            Received Value = ${receivedValue ?? "Failed"}
            '''),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget customScreen(String bookId) {
    return Scaffold(
      appBar: AppBar(title: const Text('Second Screen')),
      body: Center(child: Text('Opened with parameter: $bookId')),
    );
  }

  Future<String?> handleDeepLink(Uri uri) async {
    String? value;
    bool isFirstInstall;

    //Check if app is installed from Play/App Store
    if (uri.path.contains('play.google.com') || uri.path.contains('apps.apple.com')) {
      isFirstInstall = true;
    } else {
      isFirstInstall = false;
    }

    if (Platform.isAndroid) {
      if (isFirstInstall) {
        //Google Play Referrer Code
        ReferrerDetails details = await AndroidPlayInstallReferrer.installReferrer;
        value = "First Launch -> $details";
      } else {
        //For testing the current url we are using this parameter. Should be modified with route and data for future
        value = "Not First Launch -> ${uri.queryParameters['districtId']}";
      }
    }
    if (Platform.isIOS) {
      //Clipboard Code
      if (isFirstInstall) {
        final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
        value = clipboardData?.text;
      } else {
        value = uri.queryParameters['districtId'];
      }
    }
    return value;
  }
}

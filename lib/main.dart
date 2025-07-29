import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart'
    show AppTrackingTransparency, TrackingStatus;
import 'package:appsflyer_sdk/appsflyer_sdk.dart'
    show AppsFlyerOptions, AppsflyerSdk;

import 'GaGameme.dart' show GameSelectionScreen;

Future<void> _msgBgHandler(RemoteMessage message) async {
  print('BG MSG: ${message.data}');
}

class CosmosData {
  final String? nebulaMetrics;
  final String? galaxyID;
  CosmosData({this.nebulaMetrics, this.galaxyID});
}

class NebulaDev {
  final String? meteorUID;
  final String? quantumSession;
  final String? vesselType;
  final String? vesselBuild;
  final String? starAppBuild;
  final String? userGalacticLocale;
  final String? starlaneZone;
  final bool cometPush;
  NebulaDev({
    this.meteorUID,
    this.quantumSession,
    this.vesselType,
    this.vesselBuild,
    this.starAppBuild,
    this.userGalacticLocale,
    this.starlaneZone,
    this.cometPush = true,
  });

  Map<String, dynamic> asPacket({String? token}) => {
    "fcm_token": token ?? 'missing_token',
    "device_id": meteorUID ?? 'missing_id',
    "app_name": "amonjong",
    "instance_id": quantumSession ?? 'missing_session',
    "platform": vesselType ?? 'missing_system',
    "os_version": vesselBuild ?? 'missing_build',
    "app_version": starAppBuild ?? 'missing_app',
    "language": userGalacticLocale ?? 'en',
    "timezone": starlaneZone ?? 'UTC',
    "push_enabled": cometPush,
  };
}



class ObfuscatedWidget extends StatelessWidget {
  final String uri;
  const ObfuscatedWidget(this.uri, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ObfuscatedWidget")),
      body: Center(child: Text("URI: $uri")),
    );
  }
}

class AmonjongLoader extends StatelessWidget {
  const AmonjongLoader({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(home: PortalScreen(null)));
}

class PortalScreen extends StatefulWidget {
  final String? signalBeacon;
  const PortalScreen(this.signalBeacon, {super.key});
  @override
  State<PortalScreen> createState() => _PortalScreenState();
}

class _PortalScreenState extends State<PortalScreen> with WidgetsBindingObserver {
  late InAppWebViewController _webController;

  final _cosmos = CosmosData(nebulaMetrics: "metrics_42", galaxyID: "galaxy_123");
  final _nebulaDev = NebulaDev(
    meteorUID: "meteor_abc",
    quantumSession: "quantum_456",
    vesselType: "spaceship",
    vesselBuild: "os_2.1.1",
    starAppBuild: "app_1.0.0",
    userGalacticLocale: "en",
    starlaneZone: "Andromeda",
    cometPush: true,
  );

  bool _fetching = false;
  bool _showPortal = true;
  AppsflyerSdk? _wookie;
  String _falcon = "";
  String _sith = "";
  DateTime? _suspendedAt;
  String _currentUrl = "https://mahjong-master.click";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    FirebaseMessaging.onBackgroundMessage(_msgBgHandler);
    _initATT();
    _initAppsFlyer();
    _setupChannels();
    _initData();
    _initFCM();

    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      if (msg.data['uri'] != null) {
        _loadUrl(msg.data['uri'].toString());
      } else {
        _resetUrl();
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      if (msg.data['uri'] != null) {
        _loadUrl(msg.data['uri'].toString());
      } else {
        _resetUrl();
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      _initATT();
    });
    Future.delayed(const Duration(seconds: 6), () {
      _sendDataToWeb();
      sendDataRaw();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _suspendedAt = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      if (Platform.isIOS && _suspendedAt != null) {
        final now = DateTime.now();
        final backgroundDuration = now.difference(_suspendedAt!);
        if (backgroundDuration > const Duration(minutes: 25)) {
          _forcePortalRebuild();
        }
      }
      _suspendedAt = null;
    }
  }

  void _forcePortalRebuild() {
    setState(() {
      _showPortal = false;
    });
    Future.delayed(const Duration(milliseconds: 50), () {
      setState(() {
        _showPortal = true;
      });
    });
  }

  void _loadUrl(String url) {
    _webController.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    setState(() {
      _currentUrl = url;
    });
  }

  void _resetUrl() {
    _webController.loadUrl(urlRequest: URLRequest(url: WebUri("https://mahjong-master.click")));
    setState(() {
      _currentUrl = "https://mahjong-master.click";
    });
  }

  Future<void> _initATT() async {
    final TrackingStatus s =
    await AppTrackingTransparency.trackingAuthorizationStatus;
    if (s == TrackingStatus.notDetermined) {
      await Future.delayed(const Duration(milliseconds: 1000));
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
    final uuid = await AppTrackingTransparency.getAdvertisingIdentifier();
    print("UUID: $uuid");
  }

  void _initAppsFlyer() {
    final AppsFlyerOptions opts = AppsFlyerOptions(
      afDevKey: "qsBLmy7dAXDQhowM8V3ca4",
      appId: "6748683192",
      showDebug: true, timeToWaitForATTUserAuthorization: 0
    );
    _wookie = AppsflyerSdk(opts);
    _wookie?.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );
    _wookie?.startSDK();
    _wookie?.onInstallConversionData((res) {
      setState(() {
        _sith = res.toString();
      });
    });
    _wookie!.getAppsFlyerUID().then((value) {
      setState(() {
        _falcon = value.toString();
      });
    });
  }

  void _setupChannels() {
    // FCM notification tap
    MethodChannel('com.example.fcm/notification').setMethodCallHandler((call) async {
      if (call.method == "onNotificationTap") {
        final Map<String, dynamic> payload = Map<String, dynamic>.from(call.arguments);

        print('Payload: $payload');
        print('Payload["uri"]: ${payload["uri"]}');

        final uri = payload["uri"];
        if (uri != null && uri.toString().isNotEmpty) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => ObfuscatedWidget(uri)),
                (route) => false,
          );
        }
      }
    });
  }

  void _initData() {
    // Здесь можешь инициализировать device info, пакеты, и прочие данные если нужно
    // Можно расширить!
  }

  void _initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await messaging.getToken();
    // Можно обработать токен, если нужно
  }

  Future<void> _sendDataToWeb() async {
    final data = {
      "content": {
        "af_data": _sith,
        "af_id": _falcon,
        "fb_app_name": "amonjong",
        "app_name": "amonjong",
        "deep": null,
        "bundle_identifier": "com.amonjongtwostones.famojing.stonesamong.amonjongtwostones",
        "app_version": "1.0.0",
        "apple_id": "6748683192",
        "fcm_token": widget.signalBeacon ?? "no_token",
        "device_id": _nebulaDev.meteorUID ?? "no_device",
        "instance_id": _nebulaDev.quantumSession ?? "no_instance",
        "platform": _nebulaDev.vesselType ?? "no_type",
        "os_version": _nebulaDev.vesselBuild ?? "no_os",
        "app_version": _nebulaDev.starAppBuild ?? "no_app",
        "language": _nebulaDev.userGalacticLocale ?? "en",
        "timezone": _nebulaDev.starlaneZone ?? "UTC",
        "push_enabled": _nebulaDev.cometPush,
        "useruid": _falcon,
      },
    };

    final jsonString = jsonEncode(data);
    print("Cosmos JSON: $jsonString");
    if (_webController != null) {
      await _webController.evaluateJavascript(
        source: "sendRawData(${jsonEncode(jsonString)});",
      );
    }
  }

  void sendDataRaw() {
    // Можешь отправить любые дополнительные данные в WebView, если нужно
    print('sendDataRaw called');
  }

  final List<ContentBlocker> _lll = [
    ContentBlocker(
      trigger: ContentBlockerTrigger(urlFilter: ".*.doubleclick.net/.*"),
      action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
    ),
    // ... можно добавить остальные фильтры ...
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_showPortal)
            InAppWebView(
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                disableDefaultErrorPage: true,
            //    contentBlockers: _lll,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                allowsPictureInPictureMediaPlayback: true,
                useOnDownloadStart: true,
                javaScriptCanOpenWindowsAutomatically: true,
              ),
              initialUrlRequest: URLRequest(url: WebUri(_currentUrl)),
              onWebViewCreated: (controller) {
                _webController = controller;

                _webController.addJavaScriptHandler(
                  handlerName: 'onServerResponse',
                  callback: (args) {
                    print("JS args: $args");
                    print("From the JavaScript side:");
                    print("ResRes" + args[0]['savedata'].toString());
                    if (args[0]['savedata'].toString() == "false") {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GameSelectionScreen(),
                        ),
                            (route) => false,
                      );
                    }
                    return args.reduce((curr, next) => curr + next);
                  },
                );
              },
              onLoadStart: (controller, url) {
                setState(() {
                  _fetching = true;
                });
              },
              onLoadStop: (controller, url) async {
                await controller.evaluateJavascript(
                  source: "console.log('Portal loaded!');",
                );
                await _sendDataToWeb();
                setState(() {
                  _fetching = false;
                });
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                return NavigationActionPolicy.ALLOW;
              },
            ),
          if (!_showPortal || _fetching)
            const AmonjongLoader(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _forcePortalRebuild,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:app_tracking_transparency/app_tracking_transparency.dart' as gossamer_att;
import 'package:appsflyer_sdk/appsflyer_sdk.dart' as lunar_flyer;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel, SystemChrome, SystemUiOverlayStyle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'package:timezone/data/latest.dart' as aurora_time;
import 'package:timezone/timezone.dart' as celestia_tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:provider/provider.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart' as r;

import 'GaGameme.dart' show GameSelectionScreen;
import 'amoPU.dart' show ObfuscatedWidget;
/// --- AmonjongLoader ---
class AmonjongLoader extends StatefulWidget {
  final double fontSize;
  final Color textColor;
  final Color backgroundColor;
  final Duration letterDelay;
  final Duration? stayDuration;
  final VoidCallback? onFinish;

  const AmonjongLoader({
    super.key,
    this.fontSize = 38,
    this.textColor = Colors.amber,
    this.backgroundColor = Colors.black,
    this.letterDelay = const Duration(milliseconds: 120),
    this.stayDuration,
    this.onFinish,
  });

  @override
  State<AmonjongLoader> createState() => _AmonjongLoaderState();
}

class _AmonjongLoaderState extends State<AmonjongLoader> {
  int _letters = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animate();
  }

  void _animate() {
    _timer?.cancel();
    _letters = 0;
    _timer = Timer.periodic(widget.letterDelay, (timer) {
      setState(() {
        _letters++;
      });
      if (_letters >= 'Amonjong'.length) {
        timer.cancel();
        if (widget.stayDuration != null) {
          Future.delayed(widget.stayDuration!, () {
            widget.onFinish?.call();
          });
        } else {
          widget.onFinish?.call();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: widget.backgroundColor,
      child: SizedBox.expand(
        child: Center(
          child: Text(
            'Amonjong'.substring(0, _letters.clamp(0, 'Amonjong'.length)),
            style: TextStyle(
                fontSize: widget.fontSize,
                color: widget.textColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.5,
                fontFamily: 'monospace'
            ),
          ),
        ),
      ),
    );
  }
}
/// --- END AmonjongLoader ---

// DI
final starlightDI = GetIt.instance;

void igniteNebulae() {
  starlightDI.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());
  starlightDI.registerSingleton<Logger>(Logger());
  starlightDI.registerSingleton<Connectivity>(Connectivity());
}

// BLoC для ATT
enum HypercubeATTEvent { awaken }
enum HypercubeATTState { dormant, granted, denied, seeking }

class NebulaATTBloc extends Bloc<HypercubeATTEvent, HypercubeATTState> {
  NebulaATTBloc() : super(HypercubeATTState.dormant) {
    on<HypercubeATTEvent>((event, emit) async {
      if (event == HypercubeATTEvent.awaken) {
        emit(HypercubeATTState.seeking);
        try {
          await gossamer_att.AppTrackingTransparency.requestTrackingAuthorization();
          final result = await gossamer_att.AppTrackingTransparency.trackingAuthorizationStatus;
          emit(result == gossamer_att.TrackingStatus.authorized ? HypercubeATTState.granted : HypercubeATTState.denied);
        } catch (e) {
          emit(HypercubeATTState.denied);
        }
      }
    });
  }
}

// Network
class CelestialRelay {
  Future<bool> prismPing() async {
    var net = await starlightDI<Connectivity>().checkConnectivity();
    return net != ConnectivityResult.none;
  }

  Future<void> starlanePost(String s, Map<String, dynamic> d) async {
    try {
      await http.post(Uri.parse(s), body: jsonEncode(d));
    } catch (e) {
      starlightDI<Logger>().e("Network error: $e");
    }
  }
}
final novaDeviceProvider = r.FutureProvider<NebulaDevice>((ref) async {
  final d = NebulaDevice();
  await d.stellarConfig();
  return d;
});


// MVVM: Репозиторий для аналитики через Provider
class CosmosAnalyticsRepo with ChangeNotifier {
  lunar_flyer.AppsflyerSdk? _cosmosDrive;
  String galaxyID = "";
  String nebulaMetrics = "";

  void cometIgnition(VoidCallback onChange) {
    final conf = lunar_flyer.AppsFlyerOptions(
      afDevKey: "qsBLmy7dAXDQhowM8V3ca4",
      appId: "6748683192",
      showDebug: true,
    );
    _cosmosDrive = lunar_flyer.AppsflyerSdk(conf);
    _cosmosDrive?.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );
    _cosmosDrive?.startSDK(
      onSuccess: () => starlightDI<Logger>().i("Tracking initialized"),
      onError: (int code, String msg) => starlightDI<Logger>().e("Tracking error $code: $msg"),
    );
    _cosmosDrive?.onInstallConversionData((result) {
      nebulaMetrics = result.toString();
      onChange();
    });
    _cosmosDrive?.getAppsFlyerUID().then((val) {
      galaxyID = val.toString();
      onChange();
    });
  }
}

// Device info MVVM
class NebulaDevice {
  String? meteorUID;
  String? quantumSession = "unique-session-mark";
  String? vesselType;
  String? vesselBuild;
  String? starAppBuild;
  String? userGalacticLocale;
  String? starlaneZone;
  bool cometPush = true;

  Future<void> stellarConfig() async {
    final cosmic = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final data = await cosmic.androidInfo;
      meteorUID = data.id;
      vesselType = "android";
      vesselBuild = data.version.release;
    } else if (Platform.isIOS) {
      final data = await cosmic.iosInfo;
      meteorUID = data.identifierForVendor;
      vesselType = "ios";
      vesselBuild = data.systemVersion;
    }
    final appInfo = await PackageInfo.fromPlatform();
    starAppBuild = appInfo.version;
    userGalacticLocale = Platform.localeName.split('_')[0];
    starlaneZone = celestia_tz.local.name;
    quantumSession = "session-${DateTime.now().millisecondsSinceEpoch}";
  }

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

// Provider для репы
final cosmosAnalyticsProvider = ChangeNotifierProvider(create: (_) => CosmosAnalyticsRepo());

// App entry
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  igniteNebulae();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_shadowPulse);
  if (Platform.isAndroid) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  aurora_time.initializeTimeZones();
  final nebulaPrefs = await SharedPreferences.getInstance();
  final bool passedGate = nebulaPrefs.getBool('auth_viewed') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CosmosAnalyticsRepo()),
      ],
      child: ProviderScope(
        child: MaterialApp(
          home: BlocProvider(
            create: (_) => NebulaATTBloc(),
            child: passedGate ? const CelestialOnboardingView() : const AuroraConsentView(),
          ),
          debugShowCheckedModeBanner: false,
        ),
      ),
    ),
  );
}

// Экран согласия ATT
class AuroraConsentView extends StatefulWidget {
  const AuroraConsentView({super.key});
  @override
  State<AuroraConsentView> createState() => _AuroraConsentViewState();
}

class _AuroraConsentViewState extends State<AuroraConsentView> {
  bool _showLoader = false;

  Future<void> _markAndGo() async {
    setState(() => _showLoader = true);

    // Запрос ATT (можно убрать/заменить если не нужен)
    try {
      await gossamer_att.AppTrackingTransparency.requestTrackingAuthorization();
    } catch (_) {}

    // Сохраняем consent
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auth_viewed', true);

    // Даем время на лоадер
    await Future.delayed(const Duration(milliseconds: 1600));

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CelestialOnboardingView()),
    );
  }

  @override
  void initState() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_showLoader) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: AmonjongLoader(),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          width: 350,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Color(0xFFFFD700),
              width: 2.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.privacy_tip_outlined, size: 56, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'Personalized Experience',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Your preferences help us provide you with more relevant offers, bonuses, and notifications. We never sell or misuse your personal information — your privacy is our top priority.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _markAndGo,
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'You can change your choice in your device settings anytime.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.amber),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Экран инициализации уведомлений
class CelestialOnboardingView extends StatefulWidget {
  const CelestialOnboardingView({Key? key}) : super(key: key);
  @override
  State<CelestialOnboardingView> createState() => _CelestialOnboardingViewState();
}

class _CelestialOnboardingViewState extends State<CelestialOnboardingView> {
  final OrionSignalKeeper _orionSig = OrionSignalKeeper();
  bool _passed = false;
  Timer? _timelock;
  bool _showLoader = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
    _orionSig.listenNebula((signal) {
      _jump(signal);
    });
    _timelock = Timer(const Duration(seconds: 8), () {
      _jump('');
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showLoader = false);
    });
  }

  void _jump(String signal) {
    if (_passed) return;
    _passed = true;
    _timelock?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuantumPortalView(signalBeacon: signal),
      ),
    );
  }

  @override
  void dispose() {
    _timelock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_showLoader)
            const AmonjongLoader(),
          if (!_showLoader)
            const Center(
              child: SizedBox(
                child: Center(child:AmonjongLoader()),
              ),
            ),
        ],
      ),
    );
  }
}

// Push manager
class OrionSignalKeeper extends ChangeNotifier {
  String? _pulse;
  void listenNebula(Function(String signal) onSignal) {
    const MethodChannel('com.example.fcm/token')
        .setMethodCallHandler((call) async {
      if (call.method == 'setToken') {
        final String signal = call.arguments as String;
        onSignal(signal);
      }
    });
  }
}

class QuantumPortalView extends StatefulWidget {
  final String? signalBeacon;
  const QuantumPortalView({super.key, required this.signalBeacon});
  @override
  State<QuantumPortalView> createState() => _QuantumPortalViewState();
}

class _QuantumPortalViewState extends State<QuantumPortalView> with WidgetsBindingObserver {
  late InAppWebViewController _portalCtrl;
  bool _fetching = false;
  final String _stellarUrl = "https://mahjong-master.click/";
  final NebulaDevice _nebulaDev = NebulaDevice();
  final CosmosAnalyticsRepo _cosmos = CosmosAnalyticsRepo();
  int _portalID = 0;
  DateTime? _pausedAt;
  bool _showPortal = false;
  double _progress = 0.0;
  late Timer _progressT;
  final int _wait = 6;
  bool _showLoader = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showLoader = false);
    });
    Future.delayed(const Duration(seconds: 9), () {
      setState(() {
        _showPortal = true;
      });
    });
    _stellarLaunch();
  }

  void _stellarLaunch() {
    _progressPulse();
    _setupPulsar();
    _setupATT();
    _cosmos.cometIgnition(() => setState(() {}));
    _alertPulsar();
    _nebulaInit();
    Future.delayed(const Duration(seconds: 2), _setupATT);
    Future.delayed(const Duration(seconds: 6), () {
      _sendNebulaData();
      _sendCosmosData();
    });
  }
  void _setupPulsar() {
    FirebaseMessaging.onMessage.listen((msg) {
      final link = msg.data['uri'];
      if (link != null) {
        _toLink(link.toString());
      } else {
        _portalRefresh();
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      final link = msg.data['uri'];
      if (link != null) {
        _toLink(link.toString());
      } else {
        _portalRefresh();
      }
    });
  }
  void _alertPulsar() {
    MethodChannel('com.example.fcm/notification').setMethodCallHandler((call) async {
      if (call.method == "onNotificationTap") {
        final Map<String, dynamic> payload = Map<String, dynamic>.from(call.arguments);
        final targetUrl = payload["uri"];
        if (targetUrl != null && !targetUrl.contains("No URI")) {
         Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => ObfuscatedWidget(targetUrl)),
                (route) => false,
          );
        }
      }
    });
  }
  Future<void> _nebulaInit() async {
    try {
      await _nebulaDev.stellarConfig();
      await _nebulaPush();
      if (_portalCtrl != null) {
        _sendNebulaData();
      }
    } catch (e) {
      starlightDI<Logger>().e("Gadget initialization failed: $e");
    }
  }
  Future<void> _nebulaPush() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
  }
  Future<void> _setupATT() async {
    final status = await gossamer_att.AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == gossamer_att.TrackingStatus.notDetermined) {
      await Future.delayed(const Duration(milliseconds: 1000));
      await gossamer_att.AppTrackingTransparency.requestTrackingAuthorization();
    }
    final uuid = await gossamer_att.AppTrackingTransparency.getAdvertisingIdentifier();
    starlightDI<Logger>().i("ATT AdvertisingIdentifier: $uuid");
  }

  void _toLink(String link) async {
    if (_portalCtrl != null) {
      await _portalCtrl.loadUrl(urlRequest: URLRequest(url: WebUri(link)));
    }
  }
  void _portalRefresh() async {
    Future.delayed(const Duration(seconds: 3), () {
      if (_portalCtrl != null) {
        _portalCtrl.loadUrl(urlRequest: URLRequest(url: WebUri(_stellarUrl)));
      }
    });
  }
  Future<void> _sendNebulaData() async {

    print("load TOKEN "+widget.signalBeacon.toString());
    setState(() => _fetching = true);
    try {
      final gadgetData = _nebulaDev.asPacket(token: widget.signalBeacon);
      await _portalCtrl.evaluateJavascript(source: '''
      localStorage.setItem('app_data', JSON.stringify(${jsonEncode(gadgetData)}));
      ''');
    } finally {
      setState(() => _fetching = false);
    }
  }
  Future<void> _sendCosmosData() async {
    final data = {
      "content": {
        "af_data": _cosmos.nebulaMetrics,
        "af_id": _cosmos.galaxyID,
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
        "useruid": _cosmos.galaxyID,
      },
    };
    final jsonString = jsonEncode(data);
    starlightDI<Logger>().i("SendRawData: $jsonString");
    await _portalCtrl.evaluateJavascript(
      source: "sendRawData(${jsonEncode(jsonString)});",
    );
  }
  void _progressPulse() {
    int counter = 0;
    _progress = 0.0;
    _progressT = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        counter++;
        _progress = counter / (_wait * 10);
        if (_progress >= 1.0) {
          _progress = 1.0;
          _progressT.cancel();
        }
      });
    });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      if (Platform.isIOS && _pausedAt != null) {
        final now = DateTime.now();
        final backgroundDuration = now.difference(_pausedAt!);
        if (backgroundDuration > const Duration(minutes: 25)) {
          _rebuildPortal();
        }
      }
      _pausedAt = null;
    }
  }
  void _rebuildPortal() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => QuantumPortalView(signalBeacon: widget.signalBeacon),
        ),
            (route) => false,
      );
    });
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progressT.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _alertPulsar();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_showLoader)
            const AmonjongLoader(),
          if (!_showLoader)
            Container(
              color: Colors.black,
              child: Stack(
                children: [
                  InAppWebView(
                    key: ValueKey(_portalID),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      disableDefaultErrorPage: true,
                      mediaPlaybackRequiresUserGesture: false,
                      allowsInlineMediaPlayback: true,
                      allowsPictureInPictureMediaPlayback: true,
                      useOnDownloadStart: true,
                      javaScriptCanOpenWindowsAutomatically: true,
                    ),
                    initialUrlRequest: URLRequest(url: WebUri(_stellarUrl)),
                    onWebViewCreated: (controller) {
                      _portalCtrl = controller;
                      _portalCtrl.addJavaScriptHandler(
                          handlerName: 'onServerResponse',
                          callback: (args) {
                            print("JS args: $args");
                            print("From the JavaScript side:");
                            print("ResRes" + args[0]['savedata'].toString());
                            if (args[0]['savedata'].toString() == "false") {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GameSelectionScreen (),
                                ),
                                    (route) => false,
                              );
                            }
                            return args.reduce((curr, next) => curr + next);
                          });
                    },
                    onLoadStart: (controller, url) {
                      setState(() => _fetching = true);
                    },
                    onLoadStop: (controller, url) async {
                      await controller.evaluateJavascript(
                        source: "console.log('Portal loaded!');",
                      );
                      await _sendNebulaData();
                    },
                    shouldOverrideUrlLoading: (controller, navigationAction) async {
                      return NavigationActionPolicy.ALLOW;
                    },
                  ),
                  Visibility(
                    visible: !_showPortal,
                    child: const AmonjongLoader(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<void> _shadowPulse(RemoteMessage message) async {
  starlightDI<Logger>().i("Background alert: ${message.messageId}");
  starlightDI<Logger>().i("Background payload: ${message.data}");
}


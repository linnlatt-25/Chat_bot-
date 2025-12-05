import 'dart:convert';
import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart'
    as loc;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart'
    as stt;
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MedicalApp());
}

class MedicalApp
    extends StatelessWidget {
  const MedicalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medical Assistant',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Home Screen with navigation options
class HomeScreen
    extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1976d2),
              Color(0xFF42a5f5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment
                    .center,
            children: [
              // App Logo/Icon
              Container(
                padding:
                    EdgeInsets.all(24),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  shape:
                      BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors
                          .black
                          .withOpacity(
                              0.2),
                      blurRadius: 20,
                      offset:
                          Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons
                      .medical_services_rounded,
                  size: 80,
                  color:
                      Color(0xFF1976d2),
                ),
              ),
              SizedBox(height: 32),

              // App Title
              Text(
                'Medical Assistant',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight:
                      FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your health companion',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white
                      .withOpacity(0.9),
                ),
              ),
              SizedBox(height: 60),

              // Navigation Cards
              Padding(
                padding: EdgeInsets
                    .symmetric(
                        horizontal: 32),
                child: Column(
                  children: [
                    _buildNavigationCard(
                      context: context,
                      icon: Icons
                          .chat_bubble_rounded,
                      title:
                          'AI Chatbot',
                      subtitle:
                          'Get medical advice',
                      color: Color(
                          0xFF1976d2),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    const ChatbotScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(
                        height: 20),
                    _buildNavigationCard(
                      context: context,
                      icon: Icons
                          .map_rounded,
                      title:
                          'Find Hospitals',
                      subtitle:
                          'Locate nearby hospitals',
                      color: Color(
                          0xFF0D8C6B),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    const HospitalMap(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding:
                  EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color
                    .withOpacity(0.1),
                borderRadius:
                    BorderRadius
                        .circular(16),
              ),
              child: Icon(
                icon,
                size: 36,
                color: color,
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight
                              .bold,
                      color: Colors
                          .black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors
                          .grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== CHATBOT SCREEN ====================

class ChatbotScreen
    extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() =>
      _ChatbotScreenState();
}

class _ChatbotScreenState
    extends State<ChatbotScreen> {
  final TextEditingController
      _controller =
      TextEditingController();
  final ScrollController
      _scrollController =
      ScrollController();
  bool _isLoading = false;

  List<ChatMessage> _messages = [];
  List<Map<String, dynamic>>
      _conversationHistory = [];

  // Store last found hospitals for map navigation (multiple hospitals now!)
  List<HospitalInfo>
      _lastFoundHospitals = [];
  LatLng? _lastUserLocation;

  bool _isDetailedMode = true;
  bool _isEnglish = true;

  // NEW: Voice features
  late FlutterTts _flutterTts;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  bool _ttsEnabled = true;
  String _recognizedWords = '';

  final List<String> _apiKeys = [
    "AIzaSyBJTW6ebw14SM8sYiprE6T17Yah3V03rnk",
    "AIzaSyCRp3ddG_1dzcw7oiSxDzUGa26CPjJbZ2Q",
    "AIzaSyDLlur0ZDI74CaTS1gAryJfvdIHkXDBpT8",
    "AIzaSyDeWjNksqEm0QdDpE_3usoOuKjCtRqAQrI",
  ];

  int _currentKeyIndex = 0;

  final Color primaryBlue =
      Color(0xFF1976d2);
  final Color lightBlue =
      Color(0xFF42a5f5);
  final Color veryLightBlue =
      Color(0xFFe3f2fd);
  final Color accentBlue =
      Color(0xFF2196f3);
  final Color quickOrange =
      Color(0xFFff9800);
  final Color lightOrange =
      Color(0xFFffb74d);
  final Color successGreen =
      Color(0xFF4caf50);
  final Color warningRed =
      Color(0xFFf44336);
  final Color infoYellow =
      Color(0xFFffc107);
  final Color lightGreen =
      Color(0xFFc8e6c9);
  final Color lightRed =
      Color(0xFFffcdd2);
  final Color lightYellow =
      Color(0xFFfff9c4);

  @override
  void initState() {
    super.initState();
    _initializeTTS();
    _initializeSpeech();

    _messages.add(
      ChatMessage(
        text:
            "Hello! I'm your medical assistant. You can speak to me or type your questions. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  // Initialize Text-to-Speech
  Future<void> _initializeTTS() async {
    try {
      _flutterTts = FlutterTts();

      // Set handlers to avoid platform errors
      _flutterTts
          .setErrorHandler((msg) {
        print("TTS Error: $msg");
      });

      _flutterTts
          .setCompletionHandler(() {
        print("TTS completed");
      });

      // Configure TTS settings with error handling
      try {
        await _flutterTts.setLanguage(
            _isEnglish
                ? "en-US"
                : "ja-JP");
      } catch (e) {
        print(
            "Error setting language: $e");
      }

      try {
        await _flutterTts
            .setSpeechRate(0.5);
        await _flutterTts
            .setVolume(1.0);
        await _flutterTts.setPitch(1.0);
      } catch (e) {
        print(
            "Error setting TTS parameters: $e");
      }

      print(
          "✅ TTS initialized successfully");

      // DON'T speak on startup - can cause platform errors
      // User will hear responses when they interact
    } catch (e) {
      print(
          "❌ Error initializing TTS: $e");
      // Continue without TTS if initialization fails
      setState(() {
        _ttsEnabled = false;
      });
    }
  }

  // Initialize Speech-to-Text
  Future<void>
      _initializeSpeech() async {
    try {
      _speech = stt.SpeechToText();
      _speechEnabled =
          await _speech.initialize(
        onError: (error) => print(
            'Speech error: $error'),
        onStatus: (status) {
          print(
              'Speech status: $status');
          if (status == 'done' &&
              _isListening) {
            _stopListening();
          }
        },
      );

      if (_speechEnabled) {
        print(
            "✅ Speech recognition initialized successfully");
      } else {
        print(
            "⚠️ Speech recognition not available");
      }
    } catch (e) {
      print(
          "❌ Error initializing speech recognition: $e");
      setState(() {
        _speechEnabled = false;
      });
    }
  }

  // Speak text aloud
  Future<void> _speak(
      String text) async {
    if (!_ttsEnabled || text.isEmpty)
      return;

    try {
      String cleanText = text
          .replaceAll(
              RegExp(
                  r'[🎯🏥📍✅❌💡⚠️📋📏🗺️✨🦷🩺👂👁️🔪👶🤰🧠🩹🦴💙🔊🎙️📳👆]'),
              '')
          .replaceAll(
              RegExp(r'\*\*'), '')
          .replaceAll(RegExp(r'•'), ' ')
          .replaceAll('\n\n', '. ')
          .replaceAll('\n', '. ')
          .trim();

      if (cleanText.isNotEmpty) {
        await _flutterTts
            .speak(cleanText);
      }
    } catch (e) {
      print("Error speaking: $e");
      // Continue without speaking if there's an error
    }
  }

  // Stop speaking
  Future<void> _stopSpeaking() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print(
          "Error stopping speech: $e");
    }
  }

  // Start listening to voice input
  Future<void> _startListening() async {
    print("🎤 START LISTENING CALLED!");
    print(
        "📊 Speech enabled: $_speechEnabled");

    if (!_speechEnabled) {
      print(
          "❌ Speech recognition not enabled");
      await _speak(_isEnglish
          ? "Speech recognition is not available"
          : "音声認識が利用できません");
      return;
    }

    try {
      print(
          "🔐 Requesting microphone permission...");
      var status = await Permission
          .microphone
          .request();
      print(
          "🔐 Permission status: $status");

      if (status.isGranted) {
        print(
            "✅ Microphone permission granted!");
        await _stopSpeaking();

        setState(() {
          _isListening = true;
          _recognizedWords = '';
          _controller.clear();
        });

        print(
            "🎤 State updated - listening: $_isListening");

        HapticFeedback.mediumImpact();
        print(
            "📳 Haptic feedback triggered");

        await Future.delayed(Duration(
            milliseconds: 300));

        print(
            "🎙️ Starting speech.listen()...");
        await _speech.listen(
          onResult: (result) {
            print(
                "🗣️ Speech result: ${result.recognizedWords}");
            setState(() {
              _recognizedWords = result
                  .recognizedWords;
              _controller.text =
                  _recognizedWords;
            });
          },
          listenFor:
              Duration(seconds: 30),
          pauseFor:
              Duration(seconds: 3),
          partialResults: true,
          localeId: _isEnglish
              ? 'en_US'
              : 'ja_JP',
          listenMode: stt
              .ListenMode.confirmation,
        );
        print(
            "✅ Speech listening started successfully!");
      } else if (status.isDenied) {
        print("❌ Permission denied");
        await _speak(_isEnglish
            ? "Microphone permission is required for voice input"
            : "音声入力にはマイクの許可が必要です");
      } else if (status
          .isPermanentlyDenied) {
        print(
            "❌ Permission permanently denied - opening settings");
        openAppSettings();
      }
    } catch (e) {
      print(
          "❌ ERROR starting speech recognition: $e");
      print(
          "📊 Error type: ${e.runtimeType}");
      setState(() {
        _isListening = false;
      });
      await _speak(_isEnglish
          ? "Error starting voice input"
          : "音声入力の開始エラー");
    }
  }

  // Stop listening
  Future<void> _stopListening() async {
    try {
      await _speech.stop();

      setState(() {
        _isListening = false;
      });

      HapticFeedback.lightImpact();

      if (_recognizedWords
          .trim()
          .isNotEmpty) {
        await _speak(_isEnglish
            ? "Got it. Processing."
            : "わかりました。");
        await Future.delayed(Duration(
            milliseconds: 500));
        askGemini();
      }
    } catch (e) {
      print(
          "❌ Error stopping speech: $e");
      setState(() {
        _isListening = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    try {
      _flutterTts.stop();
    } catch (e) {
      print(
          "Error stopping TTS in dispose: $e");
    }
    try {
      _speech.stop();
    } catch (e) {
      print(
          "Error stopping speech in dispose: $e");
    }
    super.dispose();
  }

  String _getNextApiKey() {
    String key =
        _apiKeys[_currentKeyIndex];
    _currentKeyIndex =
        (_currentKeyIndex + 1) %
            _apiKeys.length;
    return key;
  }

  void _scrollToBottom() {
    Future.delayed(
      Duration(milliseconds: 100),
      () {
        if (_scrollController
            .hasClients) {
          _scrollController.animateTo(
            _scrollController.position
                .maxScrollExtent,
            duration: Duration(
                milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      },
    );
  }

  bool _isAskingForHospitalLocation(
      String message) {
    String lowerMessage =
        message.toLowerCase();

    // More comprehensive location keywords
    List<String> locationKeywords = [
      'where',
      'find',
      'hospital',
      'clinic',
      'nearest',
      'closest',
      'nearby',
      'near me',
      'show',
      'locate',
      'location',
      'go to',
      'direction',
      'navigate',
      'map',
      'どこ',
      '病院',
      '探',
      '近く',
      '場所',
      '行',
      '地図',
      '案内',
      '最寄',
    ];

    // Check if message contains any location keyword
    bool hasLocationKeyword =
        locationKeywords.any(
            (keyword) => lowerMessage
                .contains(keyword));

    // Specific phrases that indicate hospital location request
    List<String> locationPhrases = [
      'where should i go',
      'where can i go',
      'where do i go',
      'where to go',
      'どこに行',
      '病院はどこ',
      '病院を探',
      'find hospital',
      'find clinic',
      'show hospital',
      'hospital near',
      'clinic near',
      'nearest hospital',
      'closest hospital',
    ];

    bool hasLocationPhrase =
        locationPhrases.any((phrase) =>
            lowerMessage
                .contains(phrase));

    return hasLocationKeyword ||
        hasLocationPhrase;
  }

  String? _detectMedicalDepartment(
      String text) {
    String lowerText =
        text.toLowerCase();

    // PRIORITY SYSTEM: Check specific departments FIRST (most specific to least specific)
    // This ensures "toothache" matches 歯科 before "ache" might match something else

    // Priority 1: Dentistry (HIGHEST - check first!)
    if (lowerText.contains('tooth') ||
        lowerText.contains('teeth') ||
        lowerText
            .contains('toothache') ||
        lowerText.contains('dental') ||
        lowerText.contains('dentist') ||
        lowerText.contains('gum') ||
        lowerText.contains('gums') ||
        lowerText.contains('cavity') ||
        lowerText
            .contains('cavities') ||
        lowerText.contains('molar') ||
        lowerText
            .contains('wisdom tooth') ||
        lowerText
            .contains('root canal') ||
        lowerText.contains('filling') ||
        lowerText.contains('歯') ||
        lowerText.contains('歯痛') ||
        lowerText.contains('歯科') ||
        lowerText.contains('虫歯') ||
        lowerText.contains('歯茎')) {
      print(
          "🦷 Dental keyword detected → 歯科");
      return '歯科';
    }

    // Priority 2: Orthopedics
    if (lowerText.contains('bone') ||
        lowerText.contains('joint') ||
        lowerText
            .contains('back pain') ||
        lowerText
            .contains('fracture') ||
        lowerText.contains('sprain') ||
        lowerText
            .contains('orthopedic') ||
        lowerText.contains('骨') ||
        lowerText.contains('関節') ||
        lowerText.contains('腰痛') ||
        lowerText.contains('骨折') ||
        lowerText.contains('捻挫') ||
        lowerText.contains('整形外科')) {
      print(
          "🦴 Orthopedic keyword detected → 整形外科");
      return '整形外科';
    }

    // Priority 3: Dermatology
    if (lowerText.contains('skin') ||
        lowerText.contains('rash') ||
        lowerText.contains('itch') ||
        lowerText.contains('acne') ||
        lowerText
            .contains('dermatology') ||
        lowerText.contains('皮膚') ||
        lowerText.contains('湿疹') ||
        lowerText.contains('かゆみ') ||
        lowerText.contains('ニキビ') ||
        lowerText.contains('皮膚科')) {
      print(
          "🩹 Dermatology keyword detected → 皮膚科");
      return '皮膚科';
    }

    // Priority 4: Ophthalmology
    if (lowerText.contains('eye') ||
        lowerText.contains('vision') ||
        lowerText.contains('sight') ||
        lowerText.contains(
            'ophthalmology') ||
        lowerText.contains('目') ||
        lowerText.contains('視力') ||
        lowerText.contains('眼科')) {
      print(
          "👁️ Eye keyword detected → 眼科");
      return '眼科';
    }

    // Priority 5: ENT
    if (lowerText.contains('ear') ||
        lowerText.contains('nose') ||
        lowerText.contains('throat') ||
        lowerText.contains('sinus') ||
        lowerText.contains('ent') ||
        lowerText.contains('耳') ||
        lowerText.contains('鼻') ||
        lowerText.contains('喉') ||
        lowerText.contains('耳鼻咽喉科')) {
      print(
          "👂 ENT keyword detected → 耳鼻咽喉科");
      return '耳鼻咽喉科';
    }

    // Priority 6: Surgery
    if (lowerText.contains('cut') ||
        lowerText.contains('wound') ||
        lowerText.contains('injury') ||
        lowerText
            .contains('bleeding') ||
        lowerText.contains('surgery') ||
        lowerText.contains('trauma') ||
        lowerText.contains('切り傷') ||
        lowerText.contains('怪我') ||
        lowerText.contains('外傷') ||
        lowerText.contains('出血') ||
        lowerText.contains('外科')) {
      print(
          "🔪 Surgery keyword detected → 外科");
      return '外科';
    }

    // Priority 7: Pediatrics
    if (lowerText.contains('child') ||
        lowerText.contains('baby') ||
        lowerText
            .contains('pediatric') ||
        lowerText.contains('infant') ||
        lowerText.contains('子供') ||
        lowerText.contains('赤ちゃん') ||
        lowerText.contains('小児科')) {
      print(
          "👶 Pediatric keyword detected → 小児科");
      return '小児科';
    }

    // Priority 8: OB/GYN
    if (lowerText
            .contains('pregnancy') ||
        lowerText
            .contains('pregnant') ||
        lowerText
            .contains('gynecology') ||
        lowerText
            .contains('obstetrics') ||
        lowerText.contains('妊娠') ||
        lowerText.contains('産婦人科')) {
      print(
          "🤰 OB/GYN keyword detected → 産婦人科");
      return '産婦人科';
    }

    // Priority 9: Psychiatry
    if (lowerText.contains('mental') ||
        lowerText
            .contains('depression') ||
        lowerText.contains('anxiety') ||
        lowerText
            .contains('psychiatry') ||
        lowerText.contains('うつ') ||
        lowerText.contains('不安') ||
        lowerText.contains('精神科')) {
      print(
          "🧠 Psychiatry keyword detected → 精神科");
      return '精神科';
    }

    if (lowerText
            .contains('psychology') ||
        lowerText.contains('心療内科')) {
      print(
          "🧠 Psychology keyword detected → 心療内科");
      return '心療内科';
    }

    // Priority 10: Internal Medicine (LAST - most general)
    if (lowerText.contains('fever') ||
        lowerText.contains('cold') ||
        lowerText.contains('cough') ||
        lowerText.contains('fatigue') ||
        lowerText
            .contains('headache') ||
        lowerText.contains('stomach') ||
        lowerText.contains('nausea') ||
        lowerText
            .contains('diarrhea') ||
        lowerText
            .contains('vomiting') ||
        lowerText.contains(
            'internal medicine') ||
        lowerText.contains('熱') ||
        lowerText.contains('風邪') ||
        lowerText.contains('咳') ||
        lowerText.contains('疲労') ||
        lowerText.contains('頭痛') ||
        lowerText.contains('腹痛') ||
        lowerText.contains('吐き気') ||
        lowerText.contains('下痢') ||
        lowerText.contains('内科')) {
      print(
          "🩺 Internal Medicine keyword detected → 内科");
      return '内科';
    }

    print(
        "❌ No medical department keywords detected");
    return null;
  }

  String _getDepartmentEnglishName(
      String japaneseDept) {
    Map<String, String> deptMap = {
      '内科': 'Internal Medicine',
      '外科': 'Surgery',
      '整形外科': 'Orthopedics',
      '皮膚科': 'Dermatology',
      '眼科': 'Ophthalmology',
      '耳鼻咽喉科': 'ENT',
      '歯科': 'Dentistry',
      '小児科': 'Pediatrics',
      '産婦人科': 'OB/GYN',
      '精神科': 'Psychiatry',
      '心療内科': 'Psychosomatic Medicine',
    };
    return deptMap[japaneseDept] ??
        japaneseDept;
  }

  Future<LatLng?>
      _getUserLocation() async {
    loc.Location location =
        loc.Location();

    try {
      bool serviceEnabled;
      loc.PermissionStatus
          permissionGranted;

      serviceEnabled = await location
          .serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location
            .requestService();
        if (!serviceEnabled) {
          return null;
        }
      }

      permissionGranted = await location
          .hasPermission();
      if (permissionGranted ==
          loc.PermissionStatus.denied) {
        permissionGranted =
            await location
                .requestPermission();
        if (permissionGranted !=
            loc.PermissionStatus
                .granted) {
          return null;
        }
      }

      var userLoc =
          await location.getLocation();
      if (userLoc.latitude != null &&
          userLoc.longitude != null) {
        return LatLng(userLoc.latitude!,
            userLoc.longitude!);
      }
    } catch (e) {
      print(
          "Error getting location: $e");
      // Return default location (Kobe City Center) if location fails
      return LatLng(34.6901, 135.1955);
    }
    return null;
  }

  double _calculateDistance(
      LatLng start, LatLng end) {
    const double earthRadius = 6371;
    double lat1 = start.latitude *
        3.14159265359 /
        180;
    double lat2 = end.latitude *
        3.14159265359 /
        180;
    double lon1 = start.longitude *
        3.14159265359 /
        180;
    double lon2 = end.longitude *
        3.14159265359 /
        180;

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = (_sin(dLat / 2) *
            _sin(dLat / 2)) +
        _cos(lat1) *
            _cos(lat2) *
            _sin(dLon / 2) *
            _sin(dLon / 2);
    double c = 2 * _asin(_sqrt(a));

    return earthRadius * c;
  }

  double _sin(double x) => (x -
      (x * x * x) / 6 +
      (x * x * x * x * x) / 120);
  double _cos(double x) =>
      1 -
      (x * x) / 2 +
      (x * x * x * x) / 24 -
      (x * x * x * x * x * x) / 720;
  double _sqrt(double x) {
    if (x == 0) return 0;
    double z = x;
    double prev;
    do {
      prev = z;
      z = (z + x / z) / 2;
    } while ((z - prev).abs() > 0.0001);
    return z;
  }

  double _asin(double x) =>
      x +
      (x * x * x) / 6 +
      (3 * x * x * x * x * x) / 40;

  Future<List<Map<String, dynamic>>>
      _findMatchingHospitals(
          {String? department}) async {
    LatLng? userLocation =
        await _getUserLocation();
    if (userLocation == null) return [];

    const overpassUrl =
        "https://overpass-api.de/api/interpreter";

    // Build query - for dentist, search specifically for dental facilities
    // For other departments, search hospitals and clinics
    String query;
    if (department == '歯科') {
      // Specific query for dentists
      query = """
[out:json][timeout:25];
(
  node["amenity"="dentist"](34.65,135.13,34.73,135.22);
  node["healthcare"="dentist"](34.65,135.13,34.73,135.22);
);
out;
""";
    } else {
      // General query for hospitals and clinics (expanded area)
      query = """
[out:json][timeout:25];
(
  node["amenity"="hospital"](34.65,135.13,34.73,135.22);
  node["healthcare"="clinic"](34.65,135.13,34.73,135.22);
);
out;
""";
    }

    try {
      final response = await http.post(
        Uri.parse(overpassUrl),
        body: {"data": query},
      );

      if (response.statusCode == 200) {
        final data =
            jsonDecode(response.body);
        final List elements =
            data["elements"];

        if (elements.isEmpty) {
          print(
              "⚠️ No hospitals found in area");
          return [];
        }

        List<Map<String, dynamic>>
            allHospitals = [];

        // Collect all hospitals with distances
        for (var e in elements) {
          if (e["lat"] == null ||
              e["lon"] == null)
            continue;

          String name = e["tags"]
                  ?["name"] ??
              "Unnamed Hospital";
          String type = e["tags"]
                  ?["healthcare"] ??
              e["tags"]?["amenity"] ??
              "hospital";

          LatLng hospitalPos = LatLng(
              e["lat"], e["lon"]);
          double distance =
              _calculateDistance(
                  userLocation,
                  hospitalPos);

          // Only include hospitals within reasonable distance (5km)
          if (distance <= 5.0) {
            allHospitals.add({
              'name': name,
              'type': type,
              'distance': distance,
              'position': hospitalPos,
            });
          }
        }

        if (allHospitals.isEmpty) {
          print(
              "⚠️ No hospitals within 5km");
          return [];
        }

        // Sort by distance
        allHospitals.sort((a, b) =>
            a['distance'].compareTo(
                b['distance']));

        print(
            "📋 Found ${allHospitals.length} hospitals");

        // If looking for specific department, filter matching hospitals
        if (department != null) {
          print(
              "🔍 Filtering for department: $department");

          String deptEnglish =
              _getDepartmentEnglishName(
                      department)
                  .toLowerCase();
          List<Map<String, dynamic>>
              matchingHospitals = [];

          // Strategy 1: Find all hospitals with department in name
          for (var hospital
              in allHospitals) {
            String hospitalName =
                hospital['name']
                    .toLowerCase();

            bool matchesDepartment =
                false;

            if (department == '内科') {
              matchesDepartment = hospitalName
                      .contains('内科') ||
                  hospitalName.contains(
                      'medical') ||
                  hospitalName.contains(
                      'clinic') ||
                  hospitalName.contains(
                      'general') ||
                  hospital['type'] ==
                      'hospital';
            } else if (department ==
                '外科') {
              matchesDepartment =
                  hospitalName.contains(
                          '外科') ||
                      hospitalName.contains(
                          'surgical') ||
                      hospitalName
                          .contains(
                              'surgery');
            } else if (department ==
                '整形外科') {
              matchesDepartment =
                  hospitalName.contains(
                          '整形') ||
                      hospitalName.contains(
                          'orthopedic');
            } else if (department ==
                '皮膚科') {
              matchesDepartment =
                  hospitalName.contains(
                          '皮膚') ||
                      hospitalName
                          .contains(
                              'skin') ||
                      hospitalName
                          .contains(
                              'derma');
            } else if (department ==
                '眼科') {
              matchesDepartment =
                  hospitalName.contains(
                          '眼') ||
                      hospitalName
                          .contains(
                              'eye') ||
                      hospitalName
                          .contains(
                              'ophtha');
            } else if (department ==
                '耳鼻咽喉科') {
              matchesDepartment =
                  hospitalName.contains(
                          '耳鼻') ||
                      hospitalName
                          .contains(
                              'ent');
            } else if (department ==
                '歯科') {
              matchesDepartment =
                  hospitalName.contains(
                          '歯') ||
                      hospital[
                              'type'] ==
                          'dentist' ||
                      hospitalName
                          .contains(
                              'dental');
            } else if (department ==
                '小児科') {
              matchesDepartment =
                  hospitalName.contains(
                          '小児') ||
                      hospitalName
                          .contains(
                              'child') ||
                      hospitalName
                          .contains(
                              'pediatric');
            } else if (department ==
                '産婦人科') {
              matchesDepartment =
                  hospitalName.contains(
                          '産婦') ||
                      hospitalName
                          .contains(
                              'women') ||
                      hospitalName
                          .contains(
                              'maternity');
            } else if (department ==
                    '精神科' ||
                department == '心療内科') {
              matchesDepartment =
                  hospitalName
                          .contains(
                              '精神') ||
                      hospitalName
                          .contains(
                              '心療') ||
                      hospitalName
                          .contains(
                              'mental');
            }

            if (matchesDepartment) {
              matchingHospitals.add({
                ...hospital,
                'department':
                    department,
                'matched': true,
              });
            }
          }

          // If we found matching hospitals, return all of them
          if (matchingHospitals
              .isNotEmpty) {
            print(
                "✅ Found ${matchingHospitals.length} matching hospitals for $department");
            return matchingHospitals;
          }

          // Strategy 2: For general departments (内科, 外科), return all general hospitals
          if (department == '内科' ||
              department == '外科') {
            List<Map<String, dynamic>>
                generalHospitals = [];
            for (var hospital
                in allHospitals) {
              if (hospital['type'] ==
                  'hospital') {
                generalHospitals.add({
                  ...hospital,
                  'department':
                      department,
                  'matched': false,
                });
              }
            }
            if (generalHospitals
                .isNotEmpty) {
              print(
                  "✅ Returning ${generalHospitals.length} general hospitals for $department");
              return generalHospitals;
            }
          }

          // Strategy 3: No exact match found, return all facilities with department tag
          print(
              "ℹ️ No exact match found, returning all nearby facilities");
          return allHospitals
              .map((h) => {
                    ...h,
                    'department':
                        department,
                    'matched': false,
                  })
              .toList();
        }

        // No department specified, return all
        return allHospitals;
      }
    } catch (e) {
      print(
          "❌ Error fetching hospitals: $e");
    }
    return [];
  }

  String _getSystemInstruction() {
    String languageInstruction = _isEnglish
        ? "Respond in English."
        : "Respond in Japanese (日本語で返答してください).";

    if (_isDetailedMode) {
      return '''You are a compassionate and knowledgeable medical assistant chatbot for a Japanese hospital finder app.

$languageInstruction

IMPORTANT FORMATTING RULES:
- Use section headers with emojis for visual clarity
- Start each major section on a new line with a header
- Use bullet points (•) for lists
- Add line breaks between sections for readability

Your communication style:
- Start with empathy
- Use clear, structured formatting with visual sections
- Be thorough but organized
- Always maintain a supportive tone

Response Structure:
When users describe symptoms, provide responses in this EXACT format:

💙 **Understanding Your Concern**
[1-2 sentences acknowledging their concern]

✅ **Possible Common Causes**
• [Cause 1]
• [Cause 2]
• [Cause 3]
• [Cause 4]

💡 **What You Can Try Now**
• [Self-care tip 1]
• [Self-care tip 2]
• [Self-care tip 3]
• [Self-care tip 4]
• [Self-care tip 5]

⚠️ **Seek Medical Help If You Have:**
• [Warning sign 1]
• [Warning sign 2]
• [Warning sign 3]
• [Warning sign 4]

❓ **Questions to Consider**
• [Question 1]
• [Question 2]
• [Question 3]

🏥 **Recommended Department**
[Department name in Japanese and English with brief explanation]

Important reminders:
- For emergencies: "🚨 Call 119 immediately"
- Always remind: "⚕️ This is not a diagnosis. Please consult a doctor."

Available departments:
• 内科 (Internal Medicine) - general illness, fever, fatigue
• 外科 (Surgery) - injuries, wounds
• 整形外科 (Orthopedics) - bone/joint issues
• 皮膚科 (Dermatology) - skin problems
• 眼科 (Ophthalmology) - eye issues
• 耳鼻咽喉科 (ENT) - ear, nose, throat
• 歯科 (Dentistry) - dental issues
• 小児科 (Pediatrics) - children
• 産婦人科 (OB/GYN) - women's health
• 精神科/心療内科 (Psychiatry) - mental health''';
    } else {
      return '''You are a quick-response medical assistant chatbot.

$languageInstruction

IMPORTANT: Use emojis and clear formatting even in quick mode.

Response Format (Quick Mode):
💙 [Brief empathetic acknowledgment]

💡 [Quick self-care tip]

🏥 [Recommended department with name in Japanese and English]

⚠️ [One critical warning sign if needed]

For emergencies: "🚨 Call 119 now"

Keep total response under 100 words but use emojis and line breaks for clarity.''';
    }
  }

  Future<void> askGemini() async {
    if (_controller.text.trim().isEmpty)
      return;

    String userMessage =
        _controller.text;
    _controller.clear();
    _recognizedWords = '';

    setState(() {
      _messages.add(
        ChatMessage(
          text: userMessage,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });

    await _speak(_isEnglish
        ? "Thinking..."
        : "考え中...");
    _scrollToBottom();

    // Check if user is asking for hospital location (ONLY after getting medical advice)
    if (_isAskingForHospitalLocation(
        userMessage)) {
      print(
          "🔍 Hospital location request detected!");
      print(
          "📝 User message: '$userMessage'");

      // Try to detect department from current user message FIRST
      String? department =
          _detectMedicalDepartment(
              userMessage);

      if (department != null) {
        print(
            "🏥 Department detected from CURRENT message: $department");
      } else {
        // If not in current message, check recent conversation (last 5 AI responses)
        print(
            "🔍 Department not in current message, checking conversation history...");

        if (_messages.length >= 2) {
          for (int i =
                  _messages.length - 1;
              i >= 0 &&
                  i >=
                      _messages.length -
                          5;
              i--) {
            if (!_messages[i].isUser) {
              print(
                  "🔍 Checking AI message: '${_messages[i].text.substring(0, _messages[i].text.length > 100 ? 100 : _messages[i].text.length)}...'");
              department =
                  _detectMedicalDepartment(
                      _messages[i]
                          .text);
              if (department != null) {
                print(
                    "🏥 Department detected from HISTORY: $department");
                break;
              }
            }
          }
        }
      }

      if (department == null) {
        print(
            "ℹ️ No department detected, searching for general hospital");
      } else {
        print(
            "✅ FINAL DEPARTMENT TO USE: $department");
      }

      // Fetch matching hospitals with department filter
      print(
          "🔍 Searching for matching hospitals...");
      List<Map<String, dynamic>>
          matchingHospitals =
          await _findMatchingHospitals(
              department: department);

      if (matchingHospitals
          .isNotEmpty) {
        print(
            "✅ Found ${matchingHospitals.length} hospital(s)");

        // Get info from nearest hospital for the message
        var nearestHospital =
            matchingHospitals.first;
        String hospitalName =
            nearestHospital['name'];
        String hospitalType =
            nearestHospital['type'];
        double distance =
            nearestHospital['distance'];
        String? recommendedDept =
            nearestHospital[
                'department'];
        bool matched = nearestHospital[
                'matched'] ??
            false;

        // Get user location for map navigation
        LatLng? userLoc =
            await _getUserLocation();

        // Store ALL matching hospitals for map navigation
        List<HospitalInfo>
            hospitalInfoList =
            matchingHospitals
                .map((h) =>
                    HospitalInfo(
                      id: h['name']
                          .hashCode
                          .toString(),
                      name: h['name'],
                      type: h['type'],
                      position:
                          h['position'],
                      distance:
                          h['distance'],
                    ))
                .toList();

        setState(() {
          _lastFoundHospitals =
              hospitalInfoList; // Store multiple hospitals
          _lastUserLocation = userLoc;
        });

        String responseText;
        int hospitalCount =
            matchingHospitals.length;

        if (recommendedDept != null) {
          String deptEnglish =
              _getDepartmentEnglishName(
                  recommendedDept);
          if (_isEnglish) {
            responseText =
                "📍 **Found $hospitalCount ${hospitalCount > 1 ? 'Hospitals' : 'Hospital'}!**\n\n";
            responseText +=
                "🏥 **Nearest:** $hospitalName\n";
            responseText +=
                "📋 **Type:** ${hospitalType[0].toUpperCase()}${hospitalType.substring(1)}\n";
            responseText +=
                "📏 **Distance:** ${distance.toStringAsFixed(2)} km from your location\n\n";
            responseText +=
                "🏥 **Recommended for:** $deptEnglish ($recommendedDept)\n\n";

            if (hospitalCount > 1) {
              responseText +=
                  "✨ **${hospitalCount - 1} more option${hospitalCount > 2 ? 's' : ''} available nearby!**\n\n";
            }

            if (!matched) {
              responseText +=
                  "💡 **Note:** ${hospitalCount > 1 ? 'These are general facilities' : 'This is a general facility'} that can handle $deptEnglish cases.\n\n";
            } else {
              responseText +=
                  "✅ **${hospitalCount > 1 ? 'These facilities specialize' : 'This facility specializes'} in $deptEnglish**\n\n";
            }
            responseText +=
                "🗺️ Opening the map to show all ${hospitalCount > 1 ? '$hospitalCount locations' : 'location'}...\n\n(Tap the green button below to open immediately)";
          } else {
            responseText =
                "📍 **${hospitalCount}件の病院が見つかりました！**\n\n";
            responseText +=
                "🏥 **最寄り:** $hospitalName\n";
            responseText +=
                "📋 **種類:** $hospitalType\n";
            responseText +=
                "📏 **距離:** あなたの位置から${distance.toStringAsFixed(2)} km\n\n";
            responseText +=
                "🏥 **推奨科:** $recommendedDept ($deptEnglish)\n\n";

            if (hospitalCount > 1) {
              responseText +=
                  "✨ **他に${hospitalCount - 1}件の選択肢があります！**\n\n";
            }

            if (!matched) {
              responseText +=
                  "💡 **注意:** ${hospitalCount > 1 ? 'これらは' : 'こちらは'}${recommendedDept}に対応できる総合施設です。\n\n";
            } else {
              responseText +=
                  "✅ **${hospitalCount > 1 ? 'これらの施設は' : 'この施設は'}${recommendedDept}を専門としています**\n\n";
            }
            responseText +=
                "🗺️ ${hospitalCount > 1 ? '全ての場所' : '場所'}を表示するために地図を開きます...\n\n(下の緑色のボタンをタップすると今すぐ開けます)";
          }
        } else {
          if (_isEnglish) {
            responseText =
                "📍 **Found $hospitalCount ${hospitalCount > 1 ? 'Hospitals' : 'Hospital'}!**\n\n";
            responseText +=
                "🏥 **Nearest:** $hospitalName\n";
            responseText +=
                "📋 **Type:** ${hospitalType[0].toUpperCase()}${hospitalType.substring(1)}\n";
            responseText +=
                "📏 **Distance:** ${distance.toStringAsFixed(2)} km from your location\n\n";
            if (hospitalCount > 1) {
              responseText +=
                  "✨ **${hospitalCount - 1} more option${hospitalCount > 2 ? 's' : ''} available!**\n\n";
            }
            responseText +=
                "🗺️ Opening the map to show all locations...\n\n(Tap the green button below to open immediately)";
          } else {
            responseText =
                "📍 **${hospitalCount}件の病院が見つかりました！**\n\n";
            responseText +=
                "🏥 **最寄り:** $hospitalName\n";
            responseText +=
                "📋 **種類:** $hospitalType\n";
            responseText +=
                "📏 **距離:** あなたの位置から${distance.toStringAsFixed(2)} km\n\n";
            if (hospitalCount > 1) {
              responseText +=
                  "✨ **他に${hospitalCount - 1}件の選択肢があります！**\n\n";
            }
            responseText +=
                "🗺️ 全ての場所を表示するために地図を開きます...\n\n(下の緑色のボタンをタップすると今すぐ開けます)";
          }
        }

        setState(() {
          _messages.add(
            ChatMessage(
              text: responseText,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();

        await _speak(responseText);

        // Navigate to map after showing the message
        print(
            "⏳ Scheduling map navigation in 3 seconds...");
        Future.delayed(
                Duration(seconds: 3))
            .then((_) {
          print(
              "🗺️ Attempting to open map...");
          if (mounted &&
              context.mounted &&
              _lastFoundHospitals
                  .isNotEmpty) {
            print(
                "✅ Context is mounted, navigating with ${_lastFoundHospitals.length} hospital(s)...");
            Navigator.of(context)
                .push(
              MaterialPageRoute(
                builder: (context) =>
                    HospitalMap(
                  specificHospitals:
                      _lastFoundHospitals,
                  userLocation:
                      _lastUserLocation,
                ),
              ),
            )
                .then((_) {
              print(
                  "✅ Map navigation completed!");
            }).catchError((error) {
              print(
                  "❌ Navigation error: $error");
            });
          } else {
            print(
                "❌ Context not mounted or no hospital data");
          }
        });
      } else {
        print("⚠️ No hospital found");

        setState(() {
          _messages.add(
            ChatMessage(
              text: _isEnglish
                  ? "🏥 I'll help you find nearby hospitals!\n\nPlease allow location access and ensure you're in the Kobe area. Opening the map now..."
                  : "🏥 近くの病院を見つけるお手伝いをします！\n\n位置情報へのアクセスを許可し、神戸エリアにいることを確認してください。地図を開いています...",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();

        Future.delayed(
                Duration(seconds: 2))
            .then((_) {
          if (mounted &&
              context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    const HospitalMap(),
              ),
            );
          }
        });
      }
      return;
    }

    // Normal medical advice flow (NOT hospital location request)
    _conversationHistory.add({
      "role": "user",
      "parts": [
        {"text": userMessage},
      ],
    });

    int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        String apiKey =
            _getNextApiKey();

        final response =
            await http.post(
          Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
          ),
          headers: {
            'Content-Type':
                'application/json',
            "x-goog-api-key": apiKey,
          },
          body: jsonEncode({
            "contents":
                _conversationHistory,
            "systemInstruction": {
              "parts": [
                {
                  "text":
                      _getSystemInstruction(),
                },
              ],
            },
          }),
        );

        if (response.statusCode ==
            200) {
          final data =
              jsonDecode(response.body);
          String aiResponse =
              data['candidates'][0]
                      ['content']
                  ['parts'][0]['text'];

          _conversationHistory.add({
            "role": "model",
            "parts": [
              {"text": aiResponse},
            ],
          });

          setState(() {
            _messages.add(
              ChatMessage(
                text: aiResponse,
                isUser: false,
                timestamp:
                    DateTime.now(),
              ),
            );
            _isLoading = false;
          });

          _scrollToBottom();
          await _speak(aiResponse);
          return;
        } else if (response
                    .statusCode ==
                429 ||
            response.statusCode ==
                503) {
          retryCount++;
          if (retryCount < maxRetries) {
            await Future.delayed(
              Duration(
                  seconds:
                      2 * retryCount),
            );
          } else {
            setState(() {
              _messages.add(
                ChatMessage(
                  text:
                      "I'm currently overloaded. Please try again in a moment.",
                  isUser: false,
                  timestamp:
                      DateTime.now(),
                ),
              );
              _isLoading = false;
            });
            _scrollToBottom();
            return;
          }
        } else {
          setState(() {
            _messages.add(
              ChatMessage(
                text:
                    "Sorry, I encountered an error. Please try again.",
                isUser: false,
                timestamp:
                    DateTime.now(),
              ),
            );
            _isLoading = false;
          });
          _scrollToBottom();
          return;
        }
      } catch (e) {
        setState(() {
          _messages.add(
            ChatMessage(
              text:
                  "Network error. Please check your connection.",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
        return;
      }
    }
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setModalState) {
            return Container(
              padding:
                  EdgeInsets.all(24),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Container(
                    width: 45,
                    height: 5,
                    decoration:
                        BoxDecoration(
                      color: Colors.grey
                          .shade300,
                      borderRadius:
                          BorderRadius
                              .circular(
                                  3),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    _isEnglish
                        ? 'Settings'
                        : '設定',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight:
                          FontWeight
                              .bold,
                      color:
                          primaryBlue,
                    ),
                  ),
                  SizedBox(height: 24),
                  Align(
                    alignment: Alignment
                        .centerLeft,
                    child: Text(
                      _isEnglish
                          ? '🌐 Language'
                          : '🌐 言語',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight
                                .w600,
                        color: Colors
                            .black87,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child:
                            _buildLanguageCard(
                          flag: '🇬🇧',
                          label:
                              'English',
                          isSelected:
                              _isEnglish,
                          onTap: () {
                            setModalState(() =>
                                _isEnglish =
                                    true);
                            setState(
                                () {
                              _isEnglish =
                                  true;
                              _conversationHistory
                                  .clear();
                              _messages
                                  .add(
                                ChatMessage(
                                  text:
                                      "✅ Language changed to English.",
                                  isUser:
                                      false,
                                  timestamp:
                                      DateTime.now(),
                                ),
                              );
                            });
                            _scrollToBottom();
                          },
                        ),
                      ),
                      SizedBox(
                          width: 12),
                      Expanded(
                        child:
                            _buildLanguageCard(
                          flag: '🇯🇵',
                          label: '日本語',
                          isSelected:
                              !_isEnglish,
                          onTap: () {
                            setModalState(() =>
                                _isEnglish =
                                    false);
                            setState(
                                () {
                              _isEnglish =
                                  false;
                              _conversationHistory
                                  .clear();
                              _messages
                                  .add(
                                ChatMessage(
                                  text:
                                      "✅ 言語を日本語に変更しました。",
                                  isUser:
                                      false,
                                  timestamp:
                                      DateTime.now(),
                                ),
                              );
                            });
                            _scrollToBottom();
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Align(
                    alignment: Alignment
                        .centerLeft,
                    child: Text(
                      _isEnglish
                          ? '💬 Response Type'
                          : '💬 応答タイプ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight
                                .w600,
                        color: Colors
                            .black87,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildModeCard(
                    icon: Icons
                        .bolt_rounded,
                    title: _isEnglish
                        ? 'Quick Mode'
                        : 'クイックモード',
                    subtitle: _isEnglish
                        ? 'Fast answers'
                        : '迅速な回答',
                    isSelected:
                        !_isDetailedMode,
                    color: quickOrange,
                    onTap: () {
                      setModalState(() =>
                          _isDetailedMode =
                              false);
                      setState(() {
                        _isDetailedMode =
                            false;
                        _conversationHistory
                            .clear();
                        _messages.add(
                          ChatMessage(
                            text: _isEnglish
                                ? "⚡ Quick Mode activated"
                                : "⚡ クイックモード起動",
                            isUser:
                                false,
                            timestamp:
                                DateTime
                                    .now(),
                          ),
                        );
                      });
                      _scrollToBottom();
                    },
                  ),
                  SizedBox(height: 12),
                  _buildModeCard(
                    icon: Icons
                        .description_rounded,
                    title: _isEnglish
                        ? 'Detailed Mode'
                        : '詳細モード',
                    subtitle: _isEnglish
                        ? 'Full guidance'
                        : '完全なガイダンス',
                    isSelected:
                        _isDetailedMode,
                    color: primaryBlue,
                    onTap: () {
                      setModalState(() =>
                          _isDetailedMode =
                              true);
                      setState(() {
                        _isDetailedMode =
                            true;
                        _conversationHistory
                            .clear();
                        _messages.add(
                          ChatMessage(
                            text: _isEnglish
                                ? "📋 Detailed Mode activated"
                                : "📋 詳細モード起動",
                            isUser:
                                false,
                            timestamp:
                                DateTime
                                    .now(),
                          ),
                        );
                      });
                      _scrollToBottom();
                    },
                  ),
                  SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLanguageCard({
    required String flag,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration:
            Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? veryLightBlue
              : Colors.grey.shade50,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? primaryBlue
                : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(flag,
                style: TextStyle(
                    fontSize: 28)),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w600,
                color: isSelected
                    ? primaryBlue
                    : Colors.black87,
              ),
            ),
            if (isSelected) ...[
              SizedBox(height: 4),
              Icon(Icons.check_circle,
                  color: primaryBlue,
                  size: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration:
            Duration(milliseconds: 200),
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding:
                  EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? color
                    : Colors
                        .grey.shade300,
                borderRadius:
                    BorderRadius
                        .circular(12),
              ),
              child: Icon(icon,
                  color: Colors.white,
                  size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style:
                            TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight
                                  .bold,
                          color: Colors
                              .black87,
                        ),
                      ),
                      if (isSelected) ...[
                        SizedBox(
                            width: 8),
                        Icon(
                            Icons
                                .check_circle,
                            color:
                                color,
                            size: 20),
                      ],
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors
                            .grey
                            .shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        toolbarHeight: 70,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Colors.white),
          onPressed: () =>
              Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding:
                  EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius
                        .circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(
                            0.1),
                    blurRadius: 8,
                    offset:
                        Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons
                    .medical_services_rounded,
                color: primaryBlue,
                size: 26,
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    _isEnglish
                        ? 'Medical Assistant'
                        : '医療アシスタント',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight
                              .bold,
                      color:
                          Colors.white,
                    ),
                  ),
                  Text(
                    _isDetailedMode
                        ? (_isEnglish
                            ? 'Detailed'
                            : '詳細')
                        : (_isEnglish
                            ? 'Quick'
                            : 'クイック'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors
                          .white
                          .withOpacity(
                              0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
                Icons.tune_rounded,
                size: 28),
            color: Colors.white,
            onPressed:
                _showSettingsBottomSheet,
          ),
          IconButton(
            icon: Icon(
                Icons.refresh_rounded,
                size: 28),
            color: Colors.white,
            onPressed: () {
              setState(() {
                _messages.clear();
                _conversationHistory
                    .clear();
                _messages.add(
                  ChatMessage(
                    text: _isEnglish
                        ? "✅ Chat cleared. How can I help you?"
                        : "✅ チャットをクリアしました。",
                    isUser: false,
                    timestamp:
                        DateTime.now(),
                  ),
                );
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              veryLightBlue,
              Colors.white
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller:
                    _scrollController,
                padding:
                    EdgeInsets.all(16),
                itemCount:
                    _messages.length,
                itemBuilder:
                    (context, index) {
                  final message =
                      _messages[index];

                  // Check if this is a hospital info message
                  bool isHospitalInfo = !message
                          .isUser &&
                      (message.text
                              .contains(
                                  '📍 **Nearest Hospital Found!**') ||
                          message.text
                              .contains(
                                  '📍 **最寄りの病院が見つかりました！**'));

                  return Column(
                    children: [
                      ColorfulChatBubble(
                        message:
                            message,
                        primaryBlue:
                            primaryBlue,
                        lightBlue:
                            lightBlue,
                        successGreen:
                            successGreen,
                        warningRed:
                            warningRed,
                        infoYellow:
                            infoYellow,
                        lightGreen:
                            lightGreen,
                        lightRed:
                            lightRed,
                        lightYellow:
                            lightYellow,
                        isEnglish:
                            _isEnglish,
                      ),

                      // Add "Open Map Now" button for hospital info messages
                      if (isHospitalInfo)
                        Padding(
                          padding: EdgeInsets
                              .only(
                                  left:
                                      56,
                                  right:
                                      16,
                                  top:
                                      12,
                                  bottom:
                                      8),
                          child:
                              Material(
                            color: Colors
                                .transparent,
                            child:
                                InkWell(
                              onTap:
                                  () {
                                print(
                                    "🗺️ Manual map open triggered!");
                                if (_lastFoundHospitals
                                    .isNotEmpty) {
                                  Navigator.of(context)
                                      .push(
                                    MaterialPageRoute(
                                      builder: (context) => HospitalMap(
                                        specificHospitals: _lastFoundHospitals,
                                        userLocation: _lastUserLocation,
                                      ),
                                    ),
                                  );
                                } else {
                                  // Fallback to general map
                                  Navigator.of(context)
                                      .push(
                                    MaterialPageRoute(
                                      builder: (context) => const HospitalMap(),
                                    ),
                                  );
                                }
                              },
                              borderRadius:
                                  BorderRadius.circular(
                                      16),
                              child:
                                  Container(
                                padding: EdgeInsets.symmetric(
                                    vertical:
                                        16,
                                    horizontal:
                                        24),
                                decoration:
                                    BoxDecoration(
                                  gradient:
                                      LinearGradient(
                                    colors: [
                                      Color(0xFF10A37F),
                                      Color(0xFF0D8C6B)
                                    ],
                                    begin:
                                        Alignment.topLeft,
                                    end:
                                        Alignment.bottomRight,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF10A37F).withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child:
                                    Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.map_rounded,
                                        color: Colors.white,
                                        size: 24),
                                    SizedBox(width: 12),
                                    Text(
                                      _isEnglish ? '🗺️ Open Map Now' : '🗺️ 今すぐ地図を開く',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Icon(Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 22),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            if (_isLoading)
              Container(
                padding:
                    EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor:
                            AlwaysStoppedAnimation<
                                    Color>(
                                primaryBlue),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      _isEnglish
                          ? 'Thinking...'
                          : '考え中...',
                      style: TextStyle(
                        fontSize: 17,
                        color:
                            primaryBlue,
                        fontWeight:
                            FontWeight
                                .w500,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding:
                  EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(
                            0.05),
                    blurRadius: 10,
                    offset:
                        Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Microphone Button (NEW!)
                  Container(
                    width: 56,
                    height: 56,
                    decoration:
                        BoxDecoration(
                      gradient:
                          LinearGradient(
                        colors:
                            _isListening
                                ? [
                                    Colors.red,
                                    Colors.redAccent
                                  ]
                                : [
                                    Color(0xFFff6b6b),
                                    Color(0xFFee5a6f)
                                  ],
                        begin: Alignment
                            .topLeft,
                        end: Alignment
                            .bottomRight,
                      ),
                      shape: BoxShape
                          .circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening
                                  ? Colors
                                      .red
                                  : Color(
                                      0xFFff6b6b))
                              .withOpacity(
                                  0.3),
                          blurRadius:
                              10,
                          offset:
                              Offset(
                                  0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _isListening
                          ? _stopListening
                          : _startListening,
                      icon: Icon(
                        _isListening
                            ? Icons.stop
                            : Icons.mic,
                        color: Colors
                            .white,
                        size: 28,
                      ),
                      padding:
                          EdgeInsets
                              .zero,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration:
                          BoxDecoration(
                        color:
                            veryLightBlue,
                        borderRadius:
                            BorderRadius
                                .circular(
                                    24),
                        border:
                            Border.all(
                          color: primaryBlue
                              .withOpacity(
                                  0.3),
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller:
                            _controller,
                        style: TextStyle(
                            fontSize:
                                17,
                            color: Colors
                                .black87),
                        decoration:
                            InputDecoration(
                          hintText: _isListening
                              ? (_isEnglish
                                  ? 'Listening...'
                                  : '聞いています...')
                              : (_isEnglish
                                  ? 'Type or speak...'
                                  : 'タイプまたは話す...'),
                          hintStyle:
                              TextStyle(
                            fontSize:
                                17,
                            color: Colors
                                .grey
                                .shade500,
                          ),
                          border:
                              InputBorder
                                  .none,
                          contentPadding:
                              EdgeInsets
                                  .symmetric(
                            horizontal:
                                20,
                            vertical:
                                14,
                          ),
                        ),
                        onSubmitted: (_) =>
                            askGemini(),
                        maxLines: null,
                        textCapitalization:
                            TextCapitalization
                                .sentences,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    width: 56,
                    height: 56,
                    decoration:
                        BoxDecoration(
                      gradient:
                          LinearGradient(
                        colors: [
                          primaryBlue,
                          lightBlue
                        ],
                        begin: Alignment
                            .topLeft,
                        end: Alignment
                            .bottomRight,
                      ),
                      shape: BoxShape
                          .circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue
                              .withOpacity(
                                  0.3),
                          blurRadius:
                              10,
                          offset:
                              Offset(
                                  0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed:
                          _isLoading
                              ? null
                              : askGemini,
                      icon: Icon(
                        Icons
                            .send_rounded,
                        color: Colors
                            .white,
                        size: 24,
                      ),
                      padding:
                          EdgeInsets
                              .zero,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ColorfulChatBubble
    extends StatelessWidget {
  final ChatMessage message;
  final Color primaryBlue;
  final Color lightBlue;
  final Color successGreen;
  final Color warningRed;
  final Color infoYellow;
  final Color lightGreen;
  final Color lightRed;
  final Color lightYellow;
  final bool isEnglish;

  const ColorfulChatBubble({
    super.key,
    required this.message,
    required this.primaryBlue,
    required this.lightBlue,
    required this.successGreen,
    required this.warningRed,
    required this.infoYellow,
    required this.lightGreen,
    required this.lightRed,
    required this.lightYellow,
    required this.isEnglish,
  });

  Widget _buildFormattedText(
      String text) {
    List<Widget> widgets = [];
    List<String> lines =
        text.split('\n');

    for (int i = 0;
        i < lines.length;
        i++) {
      String line = lines[i];

      if (line.trim().isEmpty) {
        widgets
            .add(SizedBox(height: 8));
        continue;
      }

      if (line.contains('**') ||
          line.startsWith('#')) {
        String cleanLine = line
            .replaceAll('**', '')
            .replaceAll('#', '')
            .trim();
        Color headerColor = primaryBlue;
        Color bgColor =
            lightBlue.withOpacity(0.1);
        IconData? icon;

        if (line.contains('💙') ||
            line.contains(
                'Understanding')) {
          headerColor = primaryBlue;
          icon = Icons.favorite;
        } else if (line.contains('✅') ||
            line.contains('Possible') ||
            line.contains('Common')) {
          headerColor = successGreen;
          bgColor = lightGreen
              .withOpacity(0.3);
          icon = Icons.check_circle;
        } else if (line
                .contains('💡') ||
            line.contains('Try') ||
            line.contains(
                'What You Can')) {
          headerColor = infoYellow;
          bgColor = lightYellow
              .withOpacity(0.4);
          icon = Icons.lightbulb;
        } else if (line
                .contains('⚠️') ||
            line.contains('Seek') ||
            line.contains('Warning')) {
          headerColor = warningRed;
          bgColor =
              lightRed.withOpacity(0.3);
          icon = Icons.warning;
        } else if (line.contains('❓') ||
            line.contains('Question')) {
          headerColor =
              Color(0xFF9c27b0);
          bgColor = Color(0xFFe1bee7)
              .withOpacity(0.3);
          icon = Icons.help;
        } else if (line
                .contains('🏥') ||
            line.contains('Hospital') ||
            line.contains(
                'Department')) {
          headerColor =
              Color(0xFF00897b);
          bgColor = Color(0xFFb2dfdb)
              .withOpacity(0.3);
          icon = Icons.local_hospital;
        }

        widgets.add(
          Container(
            margin: EdgeInsets.only(
                top: 12, bottom: 8),
            padding:
                EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius:
                  BorderRadius.circular(
                      12),
              border: Border.all(
                color: headerColor
                    .withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon,
                      color:
                          headerColor,
                      size: 20),
                  SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    cleanLine,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight
                              .bold,
                      color:
                          headerColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line
              .trim()
              .startsWith('•') ||
          line.trim().startsWith('-')) {
        String cleanLine = line
            .replaceAll('•', '')
            .replaceAll('-', '')
            .trim();
        widgets.add(
          Padding(
            padding: EdgeInsets.only(
                left: 8,
                top: 6,
                bottom: 6),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Container(
                  margin:
                      EdgeInsets.only(
                          top: 8,
                          right: 12),
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(
                    color: primaryBlue,
                    shape:
                        BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    cleanLine,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors
                          .black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.contains('🚨') ||
          line
              .toLowerCase()
              .contains('emergency') ||
          line.contains('119')) {
        widgets.add(
          Container(
            margin:
                EdgeInsets.symmetric(
                    vertical: 10),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: warningRed,
              borderRadius:
                  BorderRadius.circular(
                      12),
              boxShadow: [
                BoxShadow(
                  color: warningRed
                      .withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.emergency,
                    color: Colors.white,
                    size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    line.trim(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight
                              .bold,
                      color:
                          Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (line.contains('⚕️') ||
          line.toLowerCase().contains(
              'not a diagnosis')) {
        widgets.add(
          Container(
            margin: EdgeInsets.only(
                top: 12),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  Colors.grey.shade100,
              borderRadius:
                  BorderRadius.circular(
                      10),
              border: Border.all(
                  color: Colors
                      .grey.shade300,
                  width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors
                        .grey.shade700,
                    size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line.trim(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey
                          .shade700,
                      fontStyle:
                          FontStyle
                              .italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding:
                EdgeInsets.symmetric(
                    vertical: 4),
            child: Text(
              line.trim(),
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: widgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        mainAxisAlignment: message
                .isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient:
                    LinearGradient(
                        colors: [
                      primaryBlue,
                      lightBlue
                    ]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue
                        .withOpacity(
                            0.3),
                    blurRadius: 8,
                    offset:
                        Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons
                    .medical_services_rounded,
                size: 24,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding:
                  EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? LinearGradient(
                        colors: [
                            primaryBlue,
                            lightBlue
                          ])
                    : null,
                color: message.isUser
                    ? null
                    : Colors.white,
                borderRadius:
                    BorderRadius
                        .circular(20),
                border: Border.all(
                  color: message.isUser
                      ? Colors
                          .transparent
                      : Colors.grey
                          .shade200,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(
                            0.08),
                    blurRadius: 10,
                    offset:
                        Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Row(
                    children: [
                      Text(
                        message.isUser
                            ? (isEnglish
                                ? 'You'
                                : 'あなた')
                            : (isEnglish
                                ? 'Assistant'
                                : 'アシスタント'),
                        style:
                            TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight
                                  .w600,
                          color: message
                                  .isUser
                              ? Colors
                                  .white
                                  .withOpacity(
                                      0.9)
                              : primaryBlue,
                        ),
                      ),
                      Spacer(),
                      Text(
                        _formatTime(message
                            .timestamp),
                        style:
                            TextStyle(
                          fontSize: 12,
                          color: message
                                  .isUser
                              ? Colors
                                  .white
                                  .withOpacity(
                                      0.7)
                              : Colors
                                  .grey
                                  .shade600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  message.isUser
                      ? Text(
                          message.text,
                          style:
                              TextStyle(
                            fontSize:
                                17,
                            height: 1.6,
                            color: Colors
                                .white,
                          ),
                        )
                      : _buildFormattedText(
                          message.text),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient:
                    LinearGradient(
                  colors: [
                    Color(0xFF1e88e5),
                    Color(0xFF1565c0)
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(
                            0xFF1e88e5)
                        .withOpacity(
                            0.3),
                    blurRadius: 8,
                    offset:
                        Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                  Icons.person_rounded,
                  size: 24,
                  color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// ==================== HOSPITAL MAP SCREEN ====================

class HospitalInfo {
  final String id;
  final String name;
  final String type;
  final LatLng position;
  final double distance;

  HospitalInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.position,
    required this.distance,
  });
}

class HospitalMap
    extends StatefulWidget {
  final List<HospitalInfo>
      specificHospitals; // Changed to list
  final LatLng? userLocation;

  const HospitalMap({
    super.key,
    this.specificHospitals =
        const [], // Default empty list
    this.userLocation,
  });

  @override
  _HospitalMapState createState() =>
      _HospitalMapState();
}

class _HospitalMapState
    extends State<HospitalMap> {
  GoogleMapController? _mapController;
  Set<Marker> _allMarkers = {};
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _userLocation;
  List<HospitalInfo> _nearbyHospitals =
      [];
  List<HospitalInfo>
      _filteredHospitals = [];
  HospitalInfo? _selectedHospital;
  String _selectedFilter = "All";
  String _selectedSort = "Distance";

  final String googleApiKey =
      ""; // Add your Google Maps API key here

  @override
  void initState() {
    super.initState();

    // If specific hospitals provided, use them directly
    if (widget.specificHospitals
            .isNotEmpty &&
        widget.userLocation != null) {
      setState(() {
        _userLocation =
            widget.userLocation;
        _selectedHospital = widget
            .specificHospitals
            .first; // Select nearest by default
      });
      _loadSpecificHospitals();
    } else {
      _getUserLocation();
    }
  }

  // Load the specific hospitals (multiple)
  void _loadSpecificHospitals() {
    if (widget.specificHospitals
            .isEmpty ||
        _userLocation == null) return;

    Set<Marker> markers = {};
    List<HospitalInfo> hospitals =
        widget.specificHospitals;

    // Create markers for ALL specific hospitals
    for (var hospital in hospitals) {
      BitmapDescriptor icon;
      if (hospital.type == "hospital") {
        icon = BitmapDescriptor
            .defaultMarkerWithHue(
                BitmapDescriptor
                    .hueRed);
      } else if (hospital.type ==
          "dentist") {
        icon = BitmapDescriptor
            .defaultMarkerWithHue(
                BitmapDescriptor
                    .hueBlue);
      } else if (hospital.type ==
          "clinic") {
        icon = BitmapDescriptor
            .defaultMarkerWithHue(
                BitmapDescriptor
                    .hueGreen);
      } else {
        icon = BitmapDescriptor
            .defaultMarker;
      }

      markers.add(
        Marker(
          markerId:
              MarkerId(hospital.id),
          position: hospital.position,
          infoWindow: InfoWindow(
            title: hospital.name,
            snippet:
                "${hospital.distance.toStringAsFixed(1)} km away",
          ),
          icon: icon,
          onTap: () {
            setState(() {
              _selectedHospital =
                  hospital;
            });
            _openGoogleMaps(hospital);
          },
        ),
      );
    }

    setState(() {
      _allMarkers = markers;
      _markers = markers;
      _nearbyHospitals = hospitals;
      _filteredHospitals = hospitals;
    });

    // Move camera to show all hospitals
    if (_mapController != null &&
        hospitals.length > 1) {
      // Calculate bounds to show all hospitals
      double minLat =
          _userLocation!.latitude;
      double maxLat =
          _userLocation!.latitude;
      double minLng =
          _userLocation!.longitude;
      double maxLng =
          _userLocation!.longitude;

      for (var hospital in hospitals) {
        if (hospital.position.latitude <
            minLat)
          minLat = hospital
              .position.latitude;
        if (hospital.position.latitude >
            maxLat)
          maxLat = hospital
              .position.latitude;
        if (hospital
                .position.longitude <
            minLng)
          minLng = hospital
              .position.longitude;
        if (hospital
                .position.longitude >
            maxLng)
          maxLng = hospital
              .position.longitude;
      }

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest:
                LatLng(minLat, minLng),
            northeast:
                LatLng(maxLat, maxLng),
          ),
          100, // padding
        ),
      );
    } else if (_mapController != null &&
        hospitals.length == 1) {
      // Single hospital - zoom to show user and hospital
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              _userLocation!.latitude <
                      hospitals
                          .first
                          .position
                          .latitude
                  ? _userLocation!
                      .latitude
                  : hospitals
                      .first
                      .position
                      .latitude,
              _userLocation!.longitude <
                      hospitals
                          .first
                          .position
                          .longitude
                  ? _userLocation!
                      .longitude
                  : hospitals
                      .first
                      .position
                      .longitude,
            ),
            northeast: LatLng(
              _userLocation!.latitude >
                      hospitals
                          .first
                          .position
                          .latitude
                  ? _userLocation!
                      .latitude
                  : hospitals
                      .first
                      .position
                      .latitude,
              _userLocation!.longitude >
                      hospitals
                          .first
                          .position
                          .longitude
                  ? _userLocation!
                      .longitude
                  : hospitals
                      .first
                      .position
                      .longitude,
            ),
          ),
          100, // padding
        ),
      );
    }
  }

  void _applyFilterAndSort() {
    List<HospitalInfo> filtered =
        _nearbyHospitals;

    if (_selectedFilter != "All") {
      filtered = filtered
          .where((h) =>
              h.type == _selectedFilter)
          .toList();
    }

    if (_selectedSort == "Distance") {
      filtered.sort((a, b) => a.distance
          .compareTo(b.distance));
    } else if (_selectedSort ==
        "Name") {
      filtered.sort((a, b) =>
          a.name.compareTo(b.name));
    }

    Set<Marker> filteredMarkers = {};
    for (var hospital in filtered) {
      var marker =
          _allMarkers.firstWhere(
        (m) =>
            m.markerId.value ==
            hospital.id,
        orElse: () => Marker(
            markerId: MarkerId('')),
      );
      if (marker
          .markerId.value.isNotEmpty) {
        filteredMarkers.add(marker);
      }
    }

    setState(() {
      _filteredHospitals = filtered;
      _markers = filteredMarkers;
    });
  }

  double _calculateDistance(
      LatLng start, LatLng end) {
    const double earthRadius = 6371;
    double lat1 = start.latitude *
        3.14159265359 /
        180;
    double lat2 = end.latitude *
        3.14159265359 /
        180;
    double lon1 = start.longitude *
        3.14159265359 /
        180;
    double lon2 = end.longitude *
        3.14159265359 /
        180;

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = (sin(dLat / 2) *
            sin(dLat / 2)) +
        cos(lat1) *
            cos(lat2) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  double sin(double x) => (x -
      (x * x * x) / 6 +
      (x * x * x * x * x) / 120);

  double cos(double x) =>
      1 -
      (x * x) / 2 +
      (x * x * x * x) / 24 -
      (x * x * x * x * x * x) / 720;

  Future<void>
      _getUserLocation() async {
    loc.Location location =
        loc.Location();

    try {
      bool serviceEnabled;
      loc.PermissionStatus
          permissionGranted;

      serviceEnabled = await location
          .serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location
            .requestService();
        if (!serviceEnabled) {
          print(
              "Location service is disabled");
          return;
        }
      }

      permissionGranted = await location
          .hasPermission();
      if (permissionGranted ==
          loc.PermissionStatus.denied) {
        permissionGranted =
            await location
                .requestPermission();
        if (permissionGranted !=
            loc.PermissionStatus
                .granted) {
          print(
              "Location permission denied");
          return;
        }
      }

      var userLoc =
          await location.getLocation();
      if (userLoc.latitude != null &&
          userLoc.longitude != null) {
        setState(() {
          _userLocation = LatLng(
              userLoc.latitude!,
              userLoc.longitude!);
        });

        _loadHospitals();
      }
    } catch (e) {
      print(
          "Error getting location: $e");
      setState(() {
        _userLocation =
            LatLng(34.6901, 135.1955);
      });
      _loadHospitals();
    }
  }

  Future<void> _loadHospitals() async {
    if (_userLocation == null) return;

    const overpassUrl =
        "https://overpass-api.de/api/interpreter";
    const query = """
[out:json][timeout:25];
(
  node["amenity"="hospital"](34.67,135.15,34.71,135.20);
  node["healthcare"="clinic"](34.67,135.15,34.71,135.20);
  node["healthcare"="dentist"](34.67,135.15,34.71,135.20);
);
out;
""";

    final response = await http.post(
      Uri.parse(overpassUrl),
      body: {"data": query},
    );

    if (response.statusCode == 200) {
      final data =
          jsonDecode(response.body);
      final List elements =
          data["elements"];

      Set<Marker> markers = {};
      List<HospitalInfo> allHospitals =
          [];

      for (var e in elements) {
        if (e["lat"] == null ||
            e["lon"] == null) continue;

        String name = e["tags"]
                ?["name"] ??
            "Unnamed";
        String type = e["tags"]
                ?["healthcare"] ??
            e["tags"]?["amenity"] ??
            "other";

        LatLng position =
            LatLng(e["lat"], e["lon"]);
        double distance =
            _calculateDistance(
                _userLocation!,
                position);

        allHospitals.add(HospitalInfo(
          id: "${e['id']}",
          name: name,
          type: type,
          position: position,
          distance: distance,
        ));

        BitmapDescriptor icon;
        if (type == "hospital") {
          icon = BitmapDescriptor
              .defaultMarkerWithHue(
                  BitmapDescriptor
                      .hueRed);
        } else if (type == "dentist") {
          icon = BitmapDescriptor
              .defaultMarkerWithHue(
                  BitmapDescriptor
                      .hueBlue);
        } else if (type == "clinic") {
          icon = BitmapDescriptor
              .defaultMarkerWithHue(
                  BitmapDescriptor
                      .hueGreen);
        } else {
          icon = BitmapDescriptor
              .defaultMarker;
        }

        markers.add(
          Marker(
            markerId:
                MarkerId("${e['id']}"),
            position: position,
            infoWindow: InfoWindow(
                title: name,
                snippet: type),
            icon: icon,
            onTap: () {
              if (_userLocation !=
                  null) {
                HospitalInfo hospital =
                    allHospitals
                        .firstWhere(
                  (h) =>
                      h.id ==
                      "${e['id']}",
                );
                setState(() {
                  _selectedHospital =
                      hospital;
                });
                _openGoogleMaps(
                    hospital);
              }
            },
          ),
        );
      }

      List<HospitalInfo> nearby =
          allHospitals
              .where((h) =>
                  h.distance <= 2.0)
              .toList()
            ..sort((a, b) => a.distance
                .compareTo(b.distance));

      setState(() {
        _allMarkers = markers;
        _markers = markers;
        _nearbyHospitals = nearby;
        _filteredHospitals = nearby;
      });

      _applyFilterAndSort();
    } else {
      print(
          "Failed to load hospitals: ${response.statusCode}");
    }
  }

  Future<void> _openGoogleMaps(
      HospitalInfo hospital) async {
    if (_userLocation == null) return;

    final String origin =
        "${_userLocation!.latitude},${_userLocation!.longitude}";
    final String destination =
        "${hospital.position.latitude},${hospital.position.longitude}";

    final List<String> urls = [
      "https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving",
      "https://maps.apple.com/?saddr=$origin&daddr=$destination&dirflg=d",
    ];

    bool launched = false;
    for (String urlString in urls) {
      final Uri url =
          Uri.parse(urlString);
      try {
        if (await canLaunchUrl(url)) {
          launched = await launchUrl(
            url,
            mode: LaunchMode
                .externalApplication,
          );
          if (launched) return;
        }
      } catch (e) {
        print(
            "Could not launch $urlString: $e");
      }
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
              "Could not open maps application"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<LatLng> _decodePolyline(
      String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded
                .codeUnitAt(index++) -
            63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0)
          ? ~(result >> 1)
          : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded
                .codeUnitAt(index++) -
            63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0)
          ? ~(result >> 1)
          : (result >> 1);
      lng += dlng;

      polyline.add(
          LatLng(lat / 1e5, lng / 1e5));
    }

    return polyline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _userLocation == null
          ? Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  CircularProgressIndicator(
                      color: Color(
                          0xFF0D8C6B)),
                  SizedBox(height: 16),
                  Text(
                    "Getting your location...",
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors
                            .grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Please enable location services",
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors
                            .grey[500]),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated:
                      (controller) =>
                          _mapController =
                              controller,
                  initialCameraPosition:
                      CameraPosition(
                    target:
                        _userLocation!,
                    zoom: 14,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled:
                      true,
                  myLocationButtonEnabled:
                      false,
                  zoomControlsEnabled:
                      false,
                ),
                Positioned(
                  top: 40,
                  left: 16,
                  child: Container(
                    decoration:
                        BoxDecoration(
                      color: Color(
                          0xFF0D5D4D),
                      shape: BoxShape
                          .circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                          Icons
                              .arrow_back,
                          color: Colors
                              .white),
                      onPressed: () =>
                          Navigator.pop(
                              context),
                    ),
                  ),
                ),
                if (_filteredHospitals
                    .isNotEmpty)
                  Positioned(
                    top: 100,
                    left: 16,
                    child: Container(
                      padding: EdgeInsets
                          .symmetric(
                              horizontal:
                                  16,
                              vertical:
                                  8),
                      decoration:
                          BoxDecoration(
                        color: Color
                            .fromARGB(
                                255,
                                95,
                                208,
                                178),
                        borderRadius:
                            BorderRadius
                                .circular(
                                    8),
                      ),
                      child: Text(
                        _filteredHospitals
                            .first.name,
                        style:
                            TextStyle(
                          color: Colors
                              .white,
                          fontSize: 14,
                          fontWeight:
                              FontWeight
                                  .w500,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 400,
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,
                      borderRadius:
                          BorderRadius
                              .only(
                        topLeft: Radius
                            .circular(
                                20),
                        topRight: Radius
                            .circular(
                                20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors
                              .black
                              .withOpacity(
                                  0.1),
                          blurRadius:
                              10,
                          offset:
                              Offset(0,
                                  -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets
                              .only(
                                  top:
                                      12),
                          width: 40,
                          height: 4,
                          decoration:
                              BoxDecoration(
                            color: Colors
                                    .grey[
                                300],
                            borderRadius:
                                BorderRadius
                                    .circular(2),
                          ),
                        ),
                        SizedBox(
                            height: 16),
                        Padding(
                          padding: EdgeInsets
                              .symmetric(
                                  horizontal:
                                      16),
                          child: Row(
                            children: [
                              _buildFilterChip(
                                  "All"),
                              SizedBox(
                                  width:
                                      8),
                              _buildFilterChip(
                                  "hospital"),
                              SizedBox(
                                  width:
                                      8),
                              _buildFilterChip(
                                  "clinic"),
                              SizedBox(
                                  width:
                                      8),
                              _buildFilterChip(
                                  "dentist"),
                            ],
                          ),
                        ),
                        SizedBox(
                            height: 12),
                        Padding(
                          padding: EdgeInsets
                              .symmetric(
                                  horizontal:
                                      16),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: [
                              Text(
                                "${_filteredHospitals.length} results",
                                style:
                                    TextStyle(
                                  color:
                                      Colors.grey[600],
                                  fontSize:
                                      14,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal:
                                        12,
                                    vertical:
                                        6),
                                decoration:
                                    BoxDecoration(
                                  color:
                                      Color(0xFF0D8C6B).withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: DropdownButton<
                                    String>(
                                  value:
                                      _selectedSort,
                                  underline:
                                      SizedBox(),
                                  isDense:
                                      true,
                                  icon: Icon(
                                      Icons.arrow_drop_down,
                                      color: Color(0xFF0D8C6B)),
                                  style:
                                      TextStyle(
                                    color:
                                        Color(0xFF0D8C6B),
                                    fontSize:
                                        14,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                  items: [
                                    "Distance",
                                    "Name"
                                  ].map((String
                                      value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text("Sort: $value"),
                                    );
                                  }).toList(),
                                  onChanged:
                                      (String? newValue) {
                                    if (newValue !=
                                        null) {
                                      setState(() {
                                        _selectedSort = newValue;
                                      });
                                      _applyFilterAndSort();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                            height: 12),
                        Expanded(
                          child: _filteredHospitals
                                  .isEmpty
                              ? Center(
                                  child:
                                      Text(
                                    "No hospitals found",
                                    style:
                                        TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : ListView
                                  .builder(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 16),
                                  itemCount:
                                      _filteredHospitals.length,
                                  itemBuilder:
                                      (context, index) {
                                    final hospital =
                                        _filteredHospitals[index];
                                    return _buildHospitalCard(hospital);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(
      String label) {
    bool isSelected =
        _selectedFilter == label;
    String displayLabel = label == "All"
        ? "All"
        : label
                .substring(0, 1)
                .toUpperCase() +
            label.substring(1);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
        _applyFilterAndSort();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Color(0xFF0D8C6B)
              : Colors.grey[200],
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: Text(
          displayLabel,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Colors.grey[700],
            fontSize: 14,
            fontWeight: isSelected
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalCard(
      HospitalInfo hospital) {
    bool isSelected =
        _selectedHospital?.id ==
            hospital.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedHospital = hospital;
        });
        _openGoogleMaps(hospital);
      },
      child: Container(
        margin:
            EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF0D8C6B),
          borderRadius:
              BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: Colors.white,
                  width: 2)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white
                    .withOpacity(0.2),
                borderRadius:
                    BorderRadius
                        .circular(8),
              ),
              child: Icon(
                Icons.local_hospital,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    hospital.name,
                    style: TextStyle(
                      color:
                          Colors.white,
                      fontSize: 16,
                      fontWeight:
                          FontWeight
                              .w600,
                    ),
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons
                            .location_on,
                        color: Colors
                            .white
                            .withOpacity(
                                0.8),
                        size: 16,
                      ),
                      SizedBox(
                          width: 4),
                      Text(
                        "${hospital.distance.toStringAsFixed(1)} km • ${hospital.type}",
                        style:
                            TextStyle(
                          color: Colors
                              .white
                              .withOpacity(
                                  0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.navigate_next,
              color: Colors.white,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

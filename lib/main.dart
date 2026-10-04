import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const SmartNavigationApp());
}

// ============================================================
// APP
// ============================================================

class SmartNavigationApp extends StatelessWidget {
  const SmartNavigationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Smart Navigation',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF101820),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ============================================================
// HOME SCREEN
// ============================================================

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

    static const MethodChannel _volumeChannel =
        MethodChannel('smart_navigation/volume_button');

    bool _volumeTriggerRunning = false;


    final FlutterTts homeTts = FlutterTts();

  @override
  void initState() {
    super.initState();

    initializeHomeTts();

    _setupVolumeButton();
  }

    void _setupVolumeButton() {
      _volumeChannel.setMethodCallHandler((call) async {
        if (call.method != 'volumeDownPressed') {
          return;
        }

        if (_volumeTriggerRunning || !mounted) {
          return;
        }

        _volumeTriggerRunning = true;

        try {
          debugPrint('VOLUME BUTTON TRIGGERED');

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const NavigationSetupScreen(
                autoStartVoice: true,
              ),
            ),
          );
        } catch (e) {
          debugPrint(
            'Volume button navigation error: $e',
          );
        } finally {
          _volumeTriggerRunning = false;
        }
      });
    }

    Future<void> initializeHomeTts() async {
      await homeTts.setLanguage('en-IN');
      await homeTts.setSpeechRate(0.45);
      await homeTts.setVolume(1.0);
      await homeTts.setPitch(1.0);
    }

  @override
  void dispose() {
    homeTts.stop();

    _volumeChannel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),

              const Icon(
                Icons.accessibility_new,
                size: 90,
                color: Colors.blue,
              ),

              const SizedBox(height: 25),

              const Text(
                'AI Smart Navigation',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'AI Enhanced Navigation System\n'
                'for Visually Impaired Persons',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const NavigationSetupScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.navigation,
                    size: 28,
                  ),
                  label: const Text(
                    'START NAVIGATION',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Double clap to speak your destination',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NAVIGATION SETUP SCREEN
// ============================================================

class NavigationSetupScreen extends StatefulWidget {
  final bool autoStartVoice;

  const NavigationSetupScreen({
    super.key,
    this.autoStartVoice = false,
  });

  @override
  State<NavigationSetupScreen> createState() =>
      _NavigationSetupScreenState();
}

class _NavigationSetupScreenState
    extends State<NavigationSetupScreen> {
  
  bool navigationStarted = false;

  final TextEditingController destinationController =
      TextEditingController();

  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts flutterTts = FlutterTts();

  bool isListening = false;
  bool isSearching = false;
  bool speechAvailable = false;

  String statusMessage = '';

  @override
  void initState() {
    super.initState();

    initializeSpeech();

    if (widget.autoStartVoice) {
      Future.delayed(
        const Duration(milliseconds: 800),
        () {
          if (!mounted) return;

          startVoiceInput();
        },
      );
    }
  }

  Future<void> initializeSpeech() async {
    try {
      speechAvailable = await speech.initialize(
        onStatus: (status) {
          if (!mounted) return;

          if (status == 'done' || status == 'notListening') {
            setState(() {
              isListening = false;
            });
          }
        },
        onError: (error) {
          if (!mounted) return;

          setState(() {
            isListening = false;
            statusMessage =
                'Voice input error. Please try again.';
          });
        },
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      speechAvailable = false;
    }
  }

  Future<void> initializeTts() async {
    await flutterTts.setLanguage('en-IN');
    await flutterTts.setSpeechRate(0.45);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  Future<void> startVoiceInput() async {
    if (!speechAvailable) {
      await initializeSpeech();
    }

    if (!speechAvailable) {
      if (mounted) {
        setState(() {
          statusMessage =
              'Speech recognition is not available.';
        });
      }
      return;
    }

    if (isListening) {
      await speech.stop();

      if (mounted) {
        setState(() {
          isListening = false;
        });
      }

      return;
    }

    // ==============================
    // START DESTINATION LISTENING
    // ==============================

    if (mounted) {
      setState(() {
        isListening = true;
        statusMessage =
            'Listening... Speak your destination.';
      });
    }

    // Make sure microphone is completely stopped
    // before TTS starts.
    await speech.stop();

    await flutterTts.stop();

    await flutterTts.speak(
      'Please say your destination.',
    );

    // Give the TTS time to finish completely.
    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    // ==============================
    // START MICROPHONE
    // ==============================

    await speech.listen(
      localeId: 'en_IN',
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      cancelOnError: false,
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 5),
      onResult: (result) async {
        if (!mounted) return;

        final recognizedText =
            result.recognizedWords.trim();

        if (recognizedText.isEmpty) return;

        setState(() {
          destinationController.text =
              recognizedText;

          statusMessage = result.finalResult
              ? 'Destination captured.'
              : 'Listening...';
        });

        // Continue listening until the result is final.
        if (!result.finalResult) return;

        // Prevent duplicate final results.
        if (navigationStarted) return;

        // ==============================
        // STOP MICROPHONE IMMEDIATELY
        // ==============================

        await speech.stop();

        if (mounted) {
          setState(() {
            isListening = false;
          });
        }

        // Small delay to make sure microphone
        // is completely released.
        await Future.delayed(
          const Duration(milliseconds: 300),
        );

        if (!mounted) return;

        // ==============================
        // DESTINATION CONFIRMATION
        // ==============================

        await flutterTts.stop();

        await flutterTts.speak(
          '$recognizedText, destination is captured.',
        );

        await Future.delayed(
          const Duration(milliseconds: 800),
        );

        if (!mounted) return;

        // ==============================
        // START NAVIGATION
        // ==============================

        await searchDestination();
      },
    );
  }

  Future<void> searchDestination() async {

    if (navigationStarted) return;

    // Stop speech recognition before starting navigation
    if (isListening) {
      await speech.stop();

      if (mounted) {
        setState(() {
          isListening = false;
        });
      }
    }

    final destination =
        destinationController.text.trim();

    if (destination.isEmpty) {
      if (mounted) {
        setState(() {
          statusMessage =
              'Please enter or speak a destination.';
        });
      }

      await flutterTts.speak(
        'Please enter or speak your destination.',
      );

      return;
    }

    // Lock navigation only after we have a valid destination
    navigationStarted = true;

    // Stop speech recognition before starting navigation
    if (isListening) {
      await speech.stop();

      if (mounted) {
        setState(() {
          isListening = false;
        });
      }
    }

    if (destination.isEmpty) {
      setState(() {
        statusMessage =
            'Please enter or speak a destination.';
      });

      await flutterTts.speak(
        'Please enter or speak your destination.',
      );

      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isSearching = true;
      statusMessage = 'Finding destination...';
    });

    await flutterTts.speak(
      'Finding $destination.',
    );

    try {
      final encoded = Uri.encodeComponent(destination);

      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=$encoded'
        '&format=json'
        '&limit=1',
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent':
              'AI-Smart-Navigation-App/1.0',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Geocoding failed: ${response.statusCode}',
        );
      }

      final List<dynamic> data =
          jsonDecode(response.body);

      if (data.isEmpty) {
        if (!mounted) return;

        setState(() {
          isSearching = false;
          statusMessage =
              'Destination not found. Try another name.';
        });

        await flutterTts.speak(
          'Destination not found. Please try another destination.',
        );

        return;
      }

      final result = data.first;

      final latitude =
          double.tryParse(result['lat'].toString());

      final longitude =
          double.tryParse(result['lon'].toString());

      if (latitude == null || longitude == null) {
        throw Exception(
          'Invalid destination coordinates.',
        );
      }

      if (!mounted) return;

      setState(() {
        isSearching = false;
        statusMessage = 'Destination found.';
      });

      await flutterTts.speak(
        'Destination found. Starting navigation.',
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              NavigationStatusScreen(
            destination: destination,
            destinationLatitude: latitude,
            destinationLongitude: longitude,
          ),
        ),
      );
    } catch (e) {
      print('DESTINATION ERROR: $e');

      if (!mounted) return;

      setState(() {
        isSearching = false;
        statusMessage =
            'Unable to find destination.';
      });

      await flutterTts.speak(
        'Unable to find the destination. Please check your internet connection and try again.',
      );
    }
  }

  @override
  void dispose() {
    destinationController.dispose();
    speech.stop();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Navigation Setup',
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              const Icon(
                Icons.location_on,
                size: 75,
                color: Colors.blue,
              ),

              const SizedBox(height: 20),

              const Text(
                'Where do you want to go?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Type your destination or use voice input.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: destinationController,
                decoration: InputDecoration(
                  labelText: 'Destination',
                  hintText:
                      'Example: Government College of Engineering Bargur',
                  prefixIcon: const Icon(
                    Icons.place,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: isListening
                      ? null
                      : startVoiceInput,
                  icon: Icon(
                    isListening
                        ? Icons.mic
                        : Icons.mic_none,
                  ),
                  label: Text(
                    isListening
                        ? 'LISTENING...'
                        : 'SPEAK DESTINATION',
                  ),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: isSearching
                      ? null
                      : searchDestination,
                  icon: isSearching
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.navigation,
                        ),
                  label: Text(
                    isSearching
                        ? 'FINDING DESTINATION...'
                        : 'START NAVIGATION',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (statusMessage.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue
                        .withOpacity(0.08),
                    borderRadius:
                        BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.blue
                          .withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    statusMessage,
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NAVIGATION STATUS SCREEN
// ============================================================

class NavigationStatusScreen extends StatefulWidget {
  final String destination;
  final double destinationLatitude;
  final double destinationLongitude;

  const NavigationStatusScreen({
    super.key,
    required this.destination,
    required this.destinationLatitude,
    required this.destinationLongitude,
  });

  @override
  State<NavigationStatusScreen> createState() =>
      _NavigationStatusScreenState();
}

class _NavigationStatusScreenState
    extends State<NavigationStatusScreen> {

  bool _aiVisionStarted = false;

  Position? currentPosition;

  double? distanceInMeters;
  double? bearingToDestination;

  String locationStatus =
      'Getting your location...';

  bool isLoadingLocation = false;
  bool isSpeaking = false;

  final FlutterTts flutterTts = FlutterTts();

  List<LatLng> routePoints = [];

  double routeDistance = 0;
  double routeDuration = 0;

  List<Map<String, dynamic>> routeSteps = [];
  int currentStepIndex = 0;

  bool warnedAt50 = false;
  bool warnedAt20 = false;

  bool isOffRoute = false;
  DateTime? lastOffRouteWarning;

  StreamSubscription<Position>? positionStream;

  DateTime? lastVoiceTime;
  String? lastSpokenDirection;

  bool destinationReached = false;

  @override
  void initState() {
    super.initState();

    initializeTts();

    getCurrentLocation().then((_) {
      getRoadRoute();
      startAutomaticGuidance();

      // ==============================
      // AUTOMATIC AI VISION
      // ==============================

      Future.delayed(
        const Duration(seconds: 3),
        () async {
          if (!mounted) return;

          // Prevent AI Vision from being opened
          // multiple times.
          if (_aiVisionStarted) return;

          _aiVisionStarted = true;

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const CameraVisionScreen(),
            ),
          );

          // Reset when AI Vision is closed,
          // allowing it to be opened again
          // only when a new NavigationStatusScreen
          // is created.
        },
      );
    });
  }

  // ==========================================================
  // TTS
  // ==========================================================

  Future<void> initializeTts() async {
    await flutterTts.setLanguage('en-IN');
    await flutterTts.setSpeechRate(0.45);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);

    flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          isSpeaking = true;
        });
      }
    });

    flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          isSpeaking = false;
        });
      }
    });

    flutterTts.setCancelHandler(() {
      if (mounted) {
        setState(() {
          isSpeaking = false;
        });
      }
    });
  }

  // ==========================================================
  // LOCATION
  // ==========================================================

  Future<void> getCurrentLocation() async {
    if (mounted) {
      setState(() {
        isLoadingLocation = true;
        locationStatus = 'Getting your location...';
      });
    }

    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            locationStatus =
                'Location service is disabled.';
            isLoadingLocation = false;
          });
        }
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            locationStatus =
                'Location permission denied.';
            isLoadingLocation = false;
          });
        }
        return;
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        currentPosition = position;
        distanceInMeters =
            Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          widget.destinationLatitude,
          widget.destinationLongitude,
        );

        bearingToDestination =
            Geolocator.bearingBetween(
          position.latitude,
          position.longitude,
          widget.destinationLatitude,
          widget.destinationLongitude,
        );

        locationStatus = 'Location updated.';
        isLoadingLocation = false;
      });

      calculateNavigation();
    } catch (e) {
      print('LOCATION ERROR: $e');

      if (!mounted) return;

      setState(() {
        locationStatus =
            'Unable to get current location.';
        isLoadingLocation = false;
      });
    }
  }

  // ==========================================================
  // ROAD ROUTING - OSRM
  // ==========================================================

  Future<void> getRoadRoute() async {
    if (currentPosition == null) return;

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${currentPosition!.longitude},'
      '${currentPosition!.latitude};'
      '${widget.destinationLongitude},'
      '${widget.destinationLatitude}'
      '?steps=true&overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['code'] == 'Ok') {
          final route = data['routes'][0];

          final distance = route['distance'];
          final duration = route['duration'];

          final legs = route['legs'] as List<dynamic>;

          final List<Map<String, dynamic>> steps = [];

          for (final leg in legs) {
            final legSteps = leg['steps'] as List<dynamic>;

            for (final step in legSteps) {
              final maneuver =
                  step['maneuver'] as Map<String, dynamic>;

              final maneuverLocation =
                  maneuver['location'] as List<dynamic>;

              steps.add({
                'name': step['name'] ?? '',
                'distance':
                    (step['distance'] as num).toDouble(),
                'duration':
                    (step['duration'] as num).toDouble(),
                'maneuver': maneuver,

                'maneuverLatitude':
                    (maneuverLocation[1] as num).toDouble(),

                'maneuverLongitude':
                    (maneuverLocation[0] as num).toDouble(),
              });
            }
          }

          final coordinates =
              route['geometry']['coordinates']
                  as List<dynamic>;

          final points =
              coordinates.map<LatLng>((coordinate) {
            return LatLng(
              (coordinate[1] as num).toDouble(),
              (coordinate[0] as num).toDouble(),
            );
          }).toList();

          if (!mounted) return;

          setState(() {
            routePoints = points;

            routeDistance =
                (distance as num).toDouble() / 1000;

            routeDuration =
                (duration as num).toDouble() / 60;

            routeSteps = steps;

            currentStepIndex = 0;
          });

          print('ROAD ROUTE FOUND');
          print(
            'Distance: '
            '${routeDistance.toStringAsFixed(2)} km',
          );
          print(
            'Duration: '
            '${routeDuration.toStringAsFixed(0)} minutes',
          );
        }
      }
    } catch (e) {
      print('Routing error: $e');
    }
  }

  // ==========================================================
  // NAVIGATION CALCULATION
  // ==========================================================

  void calculateNavigation() {
    if (currentPosition == null) return;

    final distance =
        Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      widget.destinationLatitude,
      widget.destinationLongitude,
    );

    final bearing =
        Geolocator.bearingBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      widget.destinationLatitude,
      widget.destinationLongitude,
    );

    if (!mounted) return;

    setState(() {
      distanceInMeters = distance;
      bearingToDestination = bearing;
    });

    if (distance <= 10 && !destinationReached) {
      destinationReached = true;

      speakText(
        'You have reached your destination.',
      );
    }
  }

  // ==========================================================
  // AUTOMATIC GPS GUIDANCE
  // ==========================================================

  void startAutomaticGuidance() {
    positionStream?.cancel();

    positionStream =
        Geolocator.getPositionStream(
      locationSettings:
          const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (!mounted) return;

      setState(() {
        currentPosition = position;
      });

      calculateNavigation();
      checkOffRoute();
      automaticVoiceGuidance();
    });
  }

  void checkOffRoute() {
    if (currentPosition == null ||
        routePoints.isEmpty ||
        destinationReached) {
      return;
    }

    double minimumDistance = double.infinity;

    for (final point in routePoints) {
      final distance = Geolocator.distanceBetween(
        currentPosition!.latitude,
        currentPosition!.longitude,
        point.latitude,
        point.longitude,
      );

      if (distance < minimumDistance) {
        minimumDistance = distance;
      }
    }

    // More than 50 meters away from the calculated route
    if (minimumDistance > 50) {
      if (!isOffRoute) {
        isOffRoute = true;

        speakText(
          'You are off the planned route. '
          'Please move back toward the route.',
        );

        lastOffRouteWarning = DateTime.now();
      } else if (lastOffRouteWarning == null ||
          DateTime.now()
                  .difference(lastOffRouteWarning!)
                  .inSeconds >=
              20) {
        speakText(
          'You are still off the planned route.',
        );

        lastOffRouteWarning = DateTime.now();
      }
    } else {
      if (isOffRoute) {
        isOffRoute = false;

        speakText(
          'You are back on the planned route.',
        );
      }
    }
  }

  void automaticVoiceGuidance() {
    if (currentPosition == null ||
        routeSteps.isEmpty ||
        destinationReached) {
      return;
    }

    if (currentStepIndex >= routeSteps.length) {
      return;
    }

    final step = routeSteps[currentStepIndex];

    final double maneuverLatitude =
        step['maneuverLatitude'];

    final double maneuverLongitude =
        step['maneuverLongitude'];

    final double distanceToTurn =
        Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      maneuverLatitude,
      maneuverLongitude,
    );

    final maneuver =
        step['maneuver'] as Map<String, dynamic>;

    final String type =
        maneuver['type']?.toString() ?? '';

    final String modifier =
        maneuver['modifier']?.toString() ?? '';

    String instruction;

    if (type == 'arrive') {
      if (distanceToTurn <= 20) {
        destinationReached = true;

        speakText(
          'You have reached your destination.',
        );
      }

      return;
    }

    if (type == 'turn') {
      if (modifier == 'left') {
        instruction = 'Turn left';
      } else if (modifier == 'right') {
        instruction = 'Turn right';
      } else if (modifier == 'slight left') {
        instruction = 'Slight left';
      } else if (modifier == 'slight right') {
        instruction = 'Slight right';
      } else if (modifier == 'sharp left') {
        instruction = 'Sharp left';
      } else if (modifier == 'sharp right') {
        instruction = 'Sharp right';
      } else if (modifier == 'uturn') {
        instruction = 'Make a U-turn';
      } else {
        instruction = 'Continue straight';
      }
    } else if (type == 'depart') {
      instruction = 'Start navigation';
    } else {
      instruction = 'Continue straight';
    }

    final String roadName =
        step['name'].toString().trim();

    if (roadName.isNotEmpty) {
      instruction =
          '$instruction onto $roadName';
    }

    // 50 meter warning
    if (distanceToTurn <= 50 &&
        distanceToTurn > 20 &&
        !warnedAt50) {
      warnedAt50 = true;

      speakText(
        '$instruction in approximately '
        '${distanceToTurn.round()} meters.',
      );

      return;
    }

    // 20 meter warning
    if (distanceToTurn <= 20 &&
        distanceToTurn > 5 &&
        !warnedAt20) {
      warnedAt20 = true;

      speakText(
        '$instruction in '
        '${distanceToTurn.round()} meters.',
      );

      return;
    }

    // Turn now
    if (distanceToTurn <= 5) {
      speakText(
        '$instruction now.',
      );

      currentStepIndex++;

      warnedAt50 = false;
      warnedAt20 = false;

      // Give the next instruction after completing this maneuver
      if (currentStepIndex < routeSteps.length) {
        Future.delayed(
          const Duration(seconds: 2),
          () {
            if (!mounted ||
                destinationReached ||
                currentStepIndex >= routeSteps.length) {
              return;
            }

            automaticVoiceGuidance();
          },
        );
      }
    }
  }
  // ==========================================================
  // VOICE HELPERS
  // ==========================================================

  Future<void> speakText(String text) async {
    if (!mounted) return;

    setState(() {
      isSpeaking = true;
    });

    await flutterTts.stop();
    await flutterTts.speak(text);
  }

  Future<void> speakNavigationInstruction() async {
    if (currentPosition == null) {
      await speakText(
        'Current location is not available.',
      );
      return;
    }

    final direction = getDirection();

    final distance = getDistanceText();

    await speakText(
      'Your destination is $distance away. '
      'Continue towards $direction.',
    );
  }

  Future<void> speakShortInstruction() async {
    if (currentPosition == null) {
      await speakText(
        'Location is not available.',
      );
      return;
    }

    await speakText(
      'Continue towards ${getDirection()}.',
    );
  }

  Future<void> stopSpeaking() async {
    await flutterTts.stop();

    if (mounted) {
      setState(() {
        isSpeaking = false;
      });
    }
  }

  // ==========================================================
  // DISTANCE
  // ==========================================================

  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} meters';
    }

    return '${(meters / 1000).toStringAsFixed(2)} kilometers';
  }

  String getDistanceText() {
    if (distanceInMeters == null) {
      return 'Calculating...';
    }

    return formatDistance(distanceInMeters!);
  }

  // ==========================================================
  // DIRECTION
  // ==========================================================

  String getDirectionFromBearing(double bearing) {
    double normalized = bearing;

    if (normalized < 0) {
      normalized += 360;
    }

    if (normalized >= 337.5 ||
        normalized < 22.5) {
      return 'North';
    } else if (normalized < 67.5) {
      return 'North East';
    } else if (normalized < 112.5) {
      return 'East';
    } else if (normalized < 157.5) {
      return 'South East';
    } else if (normalized < 202.5) {
      return 'South';
    } else if (normalized < 247.5) {
      return 'South West';
    } else if (normalized < 292.5) {
      return 'West';
    } else {
      return 'North West';
    }
  }

  String getDirection() {
    if (bearingToDestination == null) {
      return 'Calculating...';
    }

    return getDirectionFromBearing(
      bearingToDestination!,
    );
  }

  // ==========================================================
  // WALKING TIME
  // ==========================================================

  String getWalkingTime() {
    if (distanceInMeters == null) {
      return 'Calculating...';
    }

    // Approximate walking speed: 1.4 m/s
    final seconds =
        distanceInMeters! / 1.4;

    final minutes =
        (seconds / 60).round();

    if (minutes < 1) {
      return 'Less than 1 minute';
    }

    if (minutes == 1) {
      return '1 minute';
    }

    if (minutes < 60) {
      return '$minutes minutes';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return '$hours hour${hours > 1 ? 's' : ''}';
    }

    return '$hours hour${hours > 1 ? 's' : ''} '
        '$remainingMinutes min';
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final mapCenter = currentPosition != null
        ? LatLng(
            currentPosition!.latitude,
            currentPosition!.longitude,
          )
        : LatLng(
            widget.destinationLatitude,
            widget.destinationLongitude,
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Smart Navigation',
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,

            children: [
              const SizedBox(height: 10),

              const Icon(
                Icons.navigation,
                size: 70,
                color: Colors.blue,
              ),

              const SizedBox(height: 15),

              const Text(
                'Navigation Started',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // MAP
              // ==================================================

              SizedBox(
                height: 380,

                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(18),

                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: mapCenter,
                      initialZoom: 14,
                    ),

                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

                        userAgentPackageName:
                            'com.example.smart_navigation',
                      ),

                      // ROUTE
                      if (routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: routePoints,
                              strokeWidth: 5,
                            ),
                          ],
                        ),

                      // MARKERS
                      MarkerLayer(
                        markers: [
                          if (currentPosition != null)
                            Marker(
                              point: LatLng(
                                currentPosition!
                                    .latitude,
                                currentPosition!
                                    .longitude,
                              ),
                              width: 50,
                              height: 50,
                              child: const Icon(
                                Icons.my_location,
                                size: 35,
                                color: Colors.blue,
                              ),
                            ),

                          Marker(
                            point: LatLng(
                              widget
                                  .destinationLatitude,
                              widget
                                  .destinationLongitude,
                            ),
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.location_on,
                              size: 42,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ==================================================
              // ROUTE INFORMATION
              // ==================================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),

                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceAround,

                    children: [
                      Column(
                        children: [
                          const Icon(
                            Icons.route,
                            size: 30,
                          ),

                          const SizedBox(height: 5),

                          Text(
                            routeDistance > 0
                                ? '${routeDistance.toStringAsFixed(2)} km'
                                : 'Calculating...',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),

                          const Text(
                            'Road Distance',
                          ),
                        ],
                      ),

                      Column(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 30,
                          ),

                          const SizedBox(height: 5),

                          Text(
                            routeDuration > 0
                                ? '${routeDuration.toStringAsFixed(0)} min'
                                : 'Calculating...',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),

                          const Text(
                            'Estimated Time',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ==================================================
              // DESTINATION
              // ==================================================

              Container(
                padding:
                    const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.blue
                      .withOpacity(0.08),

                  borderRadius:
                      BorderRadius.circular(18),

                  border: Border.all(
                    color: Colors.blue
                        .withOpacity(0.4),
                  ),
                ),

                child: Column(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 40,
                      color: Colors.red,
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'DESTINATION',
                      style: TextStyle(
                        color:
                            Colors.white54,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      widget.destination,
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // ==================================================
              // CURRENT LOCATION
              // ==================================================

              Container(
                padding:
                    const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.green
                      .withOpacity(0.08),

                  borderRadius:
                      BorderRadius.circular(18),

                  border: Border.all(
                    color: Colors.green
                        .withOpacity(0.4),
                  ),
                ),

                child: Column(
                  children: [
                    const Icon(
                      Icons.my_location,
                      size: 40,
                      color: Colors.green,
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'CURRENT LOCATION',
                      style: TextStyle(
                        color:
                            Colors.white54,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (currentPosition != null) ...[
                      Text(
                        'Latitude: '
                        '${currentPosition!.latitude.toStringAsFixed(6)}',
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Longitude: '
                        '${currentPosition!.longitude.toStringAsFixed(6)}',
                      ),
                    ] else
                      Text(
                        locationStatus,
                        textAlign:
                            TextAlign.center,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // ==================================================
              // NAVIGATION INFORMATION
              // ==================================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(20),

                  child: Column(
                    children: [
                      const Text(
                        'NAVIGATION INFORMATION',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.straighten,
                                  size: 32,
                                  color:
                                      Colors.orange,
                                ),

                                const SizedBox(
                                    height: 8),

                                const Text(
                                  'Distance',
                                ),

                                const SizedBox(
                                    height: 5),

                                Text(
                                  getDistanceText(),
                                ),
                              ],
                            ),
                          ),

                          Expanded(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.explore,
                                  size: 32,
                                  color:
                                      Colors.orange,
                                ),

                                const SizedBox(
                                    height: 8),

                                const Text(
                                  'Direction',
                                ),

                                const SizedBox(
                                    height: 5),

                                Text(
                                  getDirection(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      const Divider(),

                      const SizedBox(height: 10),

                      const Icon(
                        Icons.directions_walk,
                        size: 32,
                        color: Colors.orange,
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Estimated Walking Time',
                      ),

                      const SizedBox(height: 5),

                      Text(
                        getWalkingTime(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ==================================================
              // AUTOMATIC VOICE
              // ==================================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(20),

                  child: Column(
                    children: [
                      Icon(
                        isSpeaking
                            ? Icons.volume_up
                            : Icons
                                .record_voice_over,
                        size: 48,
                        color:
                            Colors.deepPurple,
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'AUTOMATIC VOICE GUIDANCE',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        isSpeaking
                            ? 'Speaking navigation instruction...'
                            : 'Automatic guidance is active.',
                        textAlign:
                            TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ==================================================
              // SPEAK
              // ==================================================

              SizedBox(
                height: 55,

                child: ElevatedButton.icon(
                  onPressed: () {
                    speakNavigationInstruction();
                  },
                  icon: const Icon(Icons.volume_up),
                  label: const Text('SPEAK NAVIGATION INSTRUCTION'),
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // QUICK VOICE
              // ==================================================

              SizedBox(
                height: 50,

                child: OutlinedButton.icon(
                  onPressed: isSpeaking
                      ? null
                      : speakShortInstruction,

                  icon: const Icon(
                    Icons.navigation,
                  ),

                  label: const Text(
                    'QUICK VOICE GUIDANCE',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // STOP VOICE
              // ==================================================

              SizedBox(
                height: 50,

                child: OutlinedButton.icon(
                  onPressed: stopSpeaking,

                  icon: const Icon(
                    Icons.stop,
                  ),

                  label: const Text(
                    'STOP VOICE',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // UPDATE LOCATION
              // ==================================================

              SizedBox(
                height: 55,

                child: ElevatedButton.icon(
                  onPressed:
                      isLoadingLocation
                          ? null
                          : getCurrentLocation,

                  icon: const Icon(
                    Icons.gps_fixed,
                  ),

                  label: const Text(
                    'UPDATE CURRENT LOCATION',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // CHANGE DESTINATION
              // ==================================================

              const SizedBox(height: 12),

              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const CameraVisionScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.camera_alt,
                  ),
                  label: const Text(
                    'AI VISION',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              
              SizedBox(
                height: 50,

                child: OutlinedButton.icon(
                  onPressed: () async {
                    await stopSpeaking();

                    await positionStream
                        ?.cancel();

                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },

                  icon: const Icon(
                    Icons.edit_location_alt,
                  ),

                  label: const Text(
                    'CHANGE DESTINATION',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  
  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    positionStream?.cancel();
    flutterTts.stop();

    super.dispose();
  }
  }

class CameraVisionScreen extends StatefulWidget {
  const CameraVisionScreen({super.key});

  @override
  State<CameraVisionScreen> createState() =>
      _CameraVisionScreenState();
}

class _CameraVisionScreenState
    extends State<CameraVisionScreen> {
  final FlutterTts visionTts = FlutterTts();

  String? lastAnnouncedObject;
  DateTime? lastAnnouncementTime;

  // Prevent multiple AI voice warnings from overlapping
  bool isSpeakingWarning = false;

  // ==============================
  // AI VISION UI STATE
  // ==============================

  String detectionStatus = 'Starting AI Vision...';

  String detectedObject = 'Waiting for detection';

  String detectedConfidence = '--';

  String detectedDistance = '--';

  String detectedDirection = '--';

  String detectedRisk = 'WAITING';

  String detectedAction =
      'AI is analyzing the camera view...';

  // ==============================
  // AI DECISION ENGINE
  // ==============================

  Future<void> safetyWarning(
    String objectName,
    double objectSize,
    String objectDirection,
    double confidence,
    String estimatedDistance,
  ) async {
    if (!mounted) return;

    // ==============================
    // AI DECISION ENGINE
    // ==============================

    final highRiskObjects = [
      'car',
      'motorcycle',
      'bus',
      'truck',
    ];

    final mediumRiskObjects = [
      'person',
      'bicycle',
      'traffic light',
      'stop sign',
      'bench',
      'chair',
    ];

    final bool isHighRiskObject =
        highRiskObjects.contains(objectName);

    final bool isMediumRiskObject =
        mediumRiskObjects.contains(objectName);

    final bool isAhead =
        objectDirection == 'directly ahead';

    String riskLevel;
    String message;

    // ==============================
    // VERY CLOSE
    // ==============================

    if (estimatedDistance == 'VERY CLOSE') {
      riskLevel = 'HIGH';

      if (isHighRiskObject && isAhead) {
        message =
            '$objectName very close directly ahead. Please stop and be careful.';
      } else if (isHighRiskObject) {
        message =
            '$objectName very close $objectDirection. Please be careful.';
      } else {
        message =
            '$objectName very close $objectDirection. Please be careful.';
      }

      debugPrint(
        'AI DECISION ENGINE → HIGH RISK',
      );

      await HapticFeedback.heavyImpact();

      await Future.delayed(
        const Duration(milliseconds: 120),
      );

      await HapticFeedback.heavyImpact();

      await Future.delayed(
        const Duration(milliseconds: 120),
      );

      await HapticFeedback.heavyImpact();
    }

    // ==============================
    // CLOSE
    // ==============================

    else if (estimatedDistance == 'CLOSE') {
      riskLevel = 'HIGH';

      if (isHighRiskObject && isAhead) {
        message =
            '$objectName close directly ahead. Be careful.';
      } else if (isMediumRiskObject && isAhead) {
        message =
            '$objectName close ahead. Please be careful.';
      } else {
        message =
            '$objectName close $objectDirection. Be careful.';
      }

      debugPrint(
        'AI DECISION ENGINE → HIGH RISK',
      );

      await HapticFeedback.heavyImpact();

      await Future.delayed(
        const Duration(milliseconds: 150),
      );

      await HapticFeedback.heavyImpact();
    }

    // ==============================
    // MEDIUM DISTANCE
    // ==============================

    else if (estimatedDistance == 'MEDIUM DISTANCE') {
      riskLevel = 'MEDIUM';

      if (isHighRiskObject && isAhead) {
        message =
            '$objectName detected ahead. Please be careful.';
      } else if (isMediumRiskObject) {
        message =
            '$objectName nearby $objectDirection.';
      } else {
        message =
            '$objectName detected $objectDirection.';
      }

      debugPrint(
        'AI DECISION ENGINE → MEDIUM RISK',
      );

      await HapticFeedback.mediumImpact();
    }

    // ==============================
    // FAR
    // ==============================

    else {
      riskLevel = 'LOW';

      message =
          '$objectName detected $objectDirection.';

      debugPrint(
        'AI DECISION ENGINE → LOW RISK',
      );

      await HapticFeedback.lightImpact();
    }

    // ==============================
    // CONFIDENCE INFORMATION
    // ==============================

    if (confidence >= 0.80) {
      debugPrint(
        'AI CONFIDENCE → HIGH '
        '(${(confidence * 100).toStringAsFixed(0)}%)',
      );
    } else if (confidence >= 0.60) {
      debugPrint(
        'AI CONFIDENCE → MEDIUM '
        '(${(confidence * 100).toStringAsFixed(0)}%)',
      );
    } else {
      debugPrint(
        'AI CONFIDENCE → LOW '
        '(${(confidence * 100).toStringAsFixed(0)}%)',
      );
    }

    // ==============================
    // UPDATE AI DECISION UI
    // ==============================

    if (mounted) {
      setState(() {
        detectedObject = objectName;

        detectedConfidence =
            '${(confidence * 100).toStringAsFixed(0)}%';

        detectedDistance = estimatedDistance;

        detectedDirection = objectDirection;

        detectedRisk = riskLevel;

        detectedAction = message;
      });
    }

    // ==============================
    // FINAL AI DECISION LOG
    // ==============================

    debugPrint(
      '================================',
    );

    debugPrint(
      'AI DECISION ENGINE',
    );

    debugPrint(
      'OBJECT      : $objectName',
    );

    debugPrint(
      'CONFIDENCE  : '
      '${(confidence * 100).toStringAsFixed(0)}%',
    );

    debugPrint(
      'PROXIMITY   : $estimatedDistance',
    );

    debugPrint(
      'DIRECTION   : $objectDirection',
    );

    debugPrint(
      'RISK LEVEL  : $riskLevel',
    );

    debugPrint(
      'FINAL ACTION: $message',
    );

    debugPrint(
      '================================',
    );

    // ==============================
    // VOICE OUTPUT
    // ==============================

    await visionTts.stop();

    await visionTts.speak(message);

    await Future.delayed(
      const Duration(milliseconds: 500),
    );
  }

  // ==============================
  // YOLO DETECTION
  // ==============================

  void handleDetections(List<YOLOResult> results) {
    if (!mounted) return;

    if (results.isEmpty) {
      setState(() {
        detectionStatus = 'Scanning for obstacles...';
      });

      return;
    }

    // ==============================
    // FIND HIGHEST CONFIDENCE OBJECT
    // ==============================

    final bestDetection = results.reduce(
      (a, b) =>
          a.confidence > b.confidence ? a : b,
    );

    final objectName =
        bestDetection.className.toLowerCase();

    final confidence =
        bestDetection.confidence;

    final box = bestDetection.normalizedBox;

    final objectWidth =
        box.width.abs();

    final objectHeight =
        box.height.abs();

    final objectSize =
        objectWidth * objectHeight;

    // ==============================
    // ESTIMATED DEPTH / PROXIMITY
    // ==============================

    String estimatedDistance;

    if (objectSize >= 0.35) {
      estimatedDistance = 'VERY CLOSE';
    } else if (objectSize >= 0.20) {
      estimatedDistance = 'CLOSE';
    } else if (objectSize >= 0.10) {
      estimatedDistance = 'MEDIUM DISTANCE';
    } else {
      estimatedDistance = 'FAR';
    }

    debugPrint(
      'DEPTH ESTIMATION → $estimatedDistance',
    );

    // ==============================
    // OBJECT DIRECTION
    // ==============================

    final objectCenterX =
        box.center.dx;

    String objectDirection;

    if (objectCenterX < 0.33) {
      objectDirection = 'on your left';
    } else if (objectCenterX > 0.66) {
      objectDirection = 'on your right';
    } else {
      objectDirection = 'directly ahead';
    }

    // ==============================
    // UPDATE BASIC UI
    // ==============================

    setState(() {
      detectionStatus =
          'Obstacle detected — AI analyzing';
    });

    // ==============================
    // CONFIDENCE FILTER
    // ==============================

    if (confidence < 0.50) return;

    // ==============================
    // IMPORTANT OBJECTS
    // ==============================

    final importantObjects = [
      'person',
      'car',
      'motorcycle',
      'bicycle',
      'bus',
      'truck',
      'traffic light',
      'stop sign',
      'bench',
      'chair',
    ];

    if (!importantObjects.contains(objectName)) {
      return;
    }

    // ==============================
    // PREVENT REPEATED ANNOUNCEMENTS
    // ==============================

    final now = DateTime.now();

    if (lastAnnouncedObject == objectName &&
        lastAnnouncementTime != null &&
        now
                .difference(lastAnnouncementTime!)
                .inSeconds <
            4) {
      return;
    }

    // ==============================
    // PREVENT OVERLAPPING WARNINGS
    // ==============================

    if (isSpeakingWarning) {
      return;
    }

    lastAnnouncedObject = objectName;
    lastAnnouncementTime = now;

    isSpeakingWarning = true;

    debugPrint(
      'AI OBJECT DETECTED → $objectName',
    );

    debugPrint(
      'AI CONFIDENCE → '
      '${(confidence * 100).toStringAsFixed(0)}%',
    );

    debugPrint(
      'AI PROXIMITY → $estimatedDistance',
    );

    debugPrint(
      'AI DIRECTION → $objectDirection',
    );

    // ==============================
    // RUN AI DECISION ENGINE
    // ==============================

    safetyWarning(
      objectName,
      objectSize,
      objectDirection,
      confidence,
      estimatedDistance,
    ).whenComplete(() {
      isSpeakingWarning = false;
    });
  }

  // ==============================
  // BUILD AI VISION UI
  // ==============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // ==============================
      // APP BAR
      // ==============================

      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'AI Vision',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Test vibration',
            icon: const Icon(
              Icons.vibration,
            ),
            onPressed: () async {
              await HapticFeedback.heavyImpact();
            },
          ),
        ],
      ),

      // ==============================
      // BODY
      // ==============================

      body: Stack(
        children: [

          // ============================
          // YOLO CAMERA
          // ============================

          Positioned.fill(
            child: YOLOView(
              modelPath: 'yolo26n',
              task: YOLOTask.detect,
              confidenceThreshold: 0.35,
              iouThreshold: 0.7,
              useGpu: true,
              onResult: handleDetections,

              onModelLoad: (
                modelPath,
                task,
              ) {
                if (!mounted) return;

                setState(() {
                  detectionStatus =
                      'YOLO AI is ready';
                });
              },

              onModelError: (
                error,
                modelPath,
                task,
              ) {
                if (!mounted) return;

                setState(() {
                  detectionStatus =
                      'YOLO model error';
                });

                debugPrint(
                  'YOLO MODEL ERROR → $error',
                );
              },
            ),
          ),

          // ============================
          // TOP STATUS
          // ============================

          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.black
                    .withValues(alpha: 0.78),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.visibility,
                    color: Colors.white,
                    size: 24,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      detectionStatus,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ============================
          // AI DECISION PANEL
          // ============================

          Positioned(
            left: 12,
            right: 12,
            bottom: 18,
            child: Container(
              padding:
                  const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black
                    .withValues(alpha: 0.88),
                borderRadius:
                    BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white24,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  // ======================
                  // PANEL TITLE
                  // ======================

                  Row(
                    children: [
                      const Icon(
                        Icons.psychology,
                        color: Colors.white,
                        size: 25,
                      ),

                      const SizedBox(width: 9),

                      const Text(
                        'AI DECISION',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const Spacer(),

                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.white
                              .withValues(
                            alpha: 0.12,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(10),
                        ),
                        child: Text(
                          detectedRisk,
                          style:
                              const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // ======================
                  // OBJECT
                  // ======================

                  _buildDecisionRow(
                    Icons.category,
                    'Object',
                    detectedObject,
                  ),

                  const SizedBox(height: 8),

                  // ======================
                  // CONFIDENCE
                  // ======================

                  _buildDecisionRow(
                    Icons.analytics,
                    'Confidence',
                    detectedConfidence,
                  ),

                  const SizedBox(height: 8),

                  // ======================
                  // PROXIMITY
                  // ======================

                  _buildDecisionRow(
                    Icons.social_distance,
                    'Proximity',
                    detectedDistance,
                  ),

                  const SizedBox(height: 8),

                  // ======================
                  // DIRECTION
                  // ======================

                  _buildDecisionRow(
                    Icons.explore,
                    'Direction',
                    detectedDirection,
                  ),

                  const SizedBox(height: 14),

                  // ======================
                  // FINAL ACTION
                  // ======================

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(13),
                    decoration:
                        BoxDecoration(
                      color: Colors.white
                          .withValues(
                        alpha: 0.08,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        const Icon(
                          Icons.record_voice_over,
                          color: Colors.white,
                          size: 22,
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child: Text(
                            detectedAction,
                            style:
                                const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
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

  // ==============================
  // DECISION ROW WIDGET
  // ==============================

  Widget _buildDecisionRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [

        Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),

        const SizedBox(width: 10),

        SizedBox(
          width: 85,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ==============================
  // DISPOSE
  // ==============================

  @override
  void dispose() {
    visionTts.stop();

    super.dispose();
  }
}
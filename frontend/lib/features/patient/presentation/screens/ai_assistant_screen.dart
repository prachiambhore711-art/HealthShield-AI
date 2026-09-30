import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/colors.dart';
import '../../data/patient_service.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({Key? key}) : super(key: key);

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final PatientService _patientService = PatientService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? _medicalProfile;
  bool _isLoadingProfile = false;
  
  // Location States
  bool _isLocating = false;
  bool _isShowingClosest = false;
  String? _apiError;
  String? _locationStatus;
  double? _latitude;
  double? _longitude;
  List<Map<String, dynamic>> _nearbyProviders = [];

  // Chat Log States
  final List<Map<String, dynamic>> _messages = [
    {
      "isUser": false,
      "text": "Hello! I am your AI Health Assistant. I can help explain common medical concepts, wellness tips, nutrition, exercise, or translate medical profile questions into simple terms. How can I help you today?",
      "timestamp": ""
    }
  ];

  @override
  void initState() {
    super.initState();
    _loadPatientContext();
  }

  Future<void> _loadPatientContext() async {
    setState(() {
      _isLoadingProfile = true;
    });
    try {
      final profileRes = await _patientService.getMedicalProfile();
      if (profileRes["success"]) {
        setState(() {
          _medicalProfile = profileRes["profile"];
        });
      }
    } catch (_) {}
    setState(() {
      _isLoadingProfile = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _submitMessage(String query) async {
    if (query.trim().isEmpty) return;

    final trimmed = query.trim();
    setState(() {
      _messages.add({
        "isUser": true,
        "text": trimmed,
        "timestamp": ""
      });
    });

    _inputController.clear();
    _scrollToBottom();

    // Call backend unified AI service
    try {
      final res = await _patientService.sendAIChat(trimmed);
      if (!mounted) return;

      if (res["success"] == true && res["response"] != null) {
        setState(() {
          _messages.add({
            "isUser": false,
            "text": res["response"],
            "timestamp": ""
          });
        });
        _scrollToBottom();
        return;
      }
    } catch (_) {}

    // Fallback to local processing if offline or backend error
    if (!mounted) return;
    final responseText = _processLocalAIQuery(trimmed.toLowerCase());
    setState(() {
      _messages.add({
        "isUser": false,
        "text": responseText,
        "timestamp": ""
      });
    });
    _scrollToBottom();
  }

  String _processLocalAIQuery(String query) {
    const String disclaimer = "\n\n*Disclaimer: This information is for general health education and is not a medical diagnosis. For persistent or serious symptoms, consult a qualified healthcare professional.*";

    if (query.contains("blood pressure") || query.contains("hypertension") || query.contains(" bp")) {
      return "Hypertension (high blood pressure) occurs when the force of blood pumping through your arteries is consistently too high. "
             "Normal blood pressure is typically around 120/80 mmHg. Chronic high blood pressure can strain your heart and blood vessels over time. "
             "Leading a healthy lifestyle, reducing salt intake, and exercising regularly can help manage blood pressure." + disclaimer;
    }

    if (query.contains("fever") || query.contains("temp") || query.contains("feverish")) {
      return "A fever is a temporary increase in your body temperature, often due to an illness or infection. "
             "For general support, ensure plenty of rest, drink fluids to stay hydrated, and monitor your temperature. "
             "Seek immediate medical attention if a fever exceeds 103°F (39.4°C), lasts more than 3 days, or is accompanied by difficulty breathing, severe headache, confusion, or neck stiffness." + disclaimer;
    }

    if (query.contains("exercise") || query.contains("workout") || query.contains("fitness") || query.contains("run")) {
      String contextNote = "";
      if (_medicalProfile != null) {
        final conditions = (_medicalProfile!["chronic_conditions"] ?? "").toString().toLowerCase();
        if (conditions.contains("asthma")) {
          contextNote = "\n*Note: Since you have Asthma listed in your profile, please avoid high-intensity workouts in cold, dry air without consult, and keep your rescue inhaler handy.*";
        }
      }
      return "Physical exercise is key to overall cardiovascular health, muscle strength, and mood elevation. "
             "General guidelines suggest aiming for at least 150 minutes of moderate aerobic activity (like brisk walking) or 75 minutes of vigorous activity per week, along with strength training twice a week." + contextNote + disclaimer;
    }

    if (query.contains("bmi") || query.contains("body mass index")) {
      if (_medicalProfile != null && _medicalProfile!["height"] != null && _medicalProfile!["weight"] != null) {
        try {
          final double h = double.parse(_medicalProfile!["height"].toString());
          final double w = double.parse(_medicalProfile!["weight"].toString());
          if (h > 0 && w > 0) {
            final double bmi = w / ((h / 100) * (h / 100));
            String status = "Normal weight";
            if (bmi < 18.5) status = "Underweight";
            else if (bmi >= 25.0 && bmi < 30.0) status = "Overweight";
            else if (bmi >= 30.0) status = "Obese";

            return "Based on your stored profile (Height: ${h}cm, Weight: ${w}kg), your calculated Body Mass Index (BMI) is: **${bmi.toStringAsFixed(1)}**.\n"
                   "This falls under the **$status** classification.\n"
                   "Please note that BMI is a general screening indicator and does not directly measure body fat composition." + disclaimer;
          }
        } catch (_) {}
      }
      return "Body Mass Index (BMI) is a simple height-to-weight ratio used to classify weight status (Underweight, Normal, Overweight, Obese).\n"
             "Formula: Weight (kg) / [Height (m)]².\n"
             "**Your medical profile does not contain height/weight information to calculate this locally.**" + disclaimer;
    }

    if (query.contains("allergy") || query.contains("allergies") || query.contains("allergic")) {
      String allergyNote = "";
      if (_medicalProfile != null && _medicalProfile!["allergies"] != null && _medicalProfile!["allergies"].toString().trim().isNotEmpty) {
        allergyNote = "\n*Your profile lists active allergy: [${_medicalProfile!["allergies"]}]. Always inspect product/food labels carefully and communicate triggers to caregivers.*";
      }
      return "Allergies are immune responses to substances (triggers) like food, dust, pollen, or medications. "
             "Prevention involves identifying and avoiding known triggers. "
             "If you have a history of severe allergic reactions (anaphylaxis), carry prescribed epinephrine at all times." + allergyNote + disclaimer;
    }

    if (query.contains("sleep") || query.contains("insomnia") || query.contains("tired")) {
      return "Healthy sleep hygiene supports brain function, immune health, and emotional balance. "
             "Aim for 7 to 9 hours of quality sleep per night. "
             "Tips include keeping a consistent schedule, avoiding screens 1 hour before bed, keeping the bedroom cool and dark, and limiting caffeine later in the day." + disclaimer;
    }

    if (query.contains("water") || query.contains("hydration") || query.contains("drink")) {
      return "Hydration supports kidney function, temperature regulation, and joint lubrication. "
             "A general baseline is around 8 cups (2 liters) of fluid daily, though individual needs vary by weight and activity. "
             "A good indicator of hydration status is light-yellow or clear urine." + disclaimer;
    }

    if (query.contains("nutrition") || query.contains("diet") || query.contains("food") || query.contains("sugar")) {
      return "A balanced diet provides essential vitamins and macro-nutrients. "
             "Focus on incorporating whole grains, lean proteins, vegetables, and healthy fats while limiting added sugars, excessive sodium, and highly processed meals." + disclaimer;
    }

    if (query.contains("when should i see") || query.contains("danger") || query.contains("doctor") || query.contains("hospital")) {
      return "You should seek immediate professional medical attention or emergency care if you experience warning signs such as: "
             "difficulty breathing, persistent chest pain or pressure, sudden confusion, severe local pain, numbness or weakness, or persistent high fever. "
             "Always trust your judgment and consult a qualified provider for clinical queries." + disclaimer;
    }

    return "I can help with general health education, wellness, nutrition, exercise, and understanding common medical terms. "
           "For diagnosis or treatment decisions, please consult a healthcare professional.";
  }

  Future<void> _findNearbyDoctors({bool showClosest = false}) async {
    setState(() {
      _isLocating = true;
      _isShowingClosest = showClosest;
      _apiError = null;
      _locationStatus = "Checking location service status...";
      if (!showClosest) {
        _latitude = null;
        _longitude = null;
        _nearbyProviders = [];
      }
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatus = "Location services are disabled on this device.";
          _isLocating = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        _locationStatus = "Requesting location permission...";
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus = "Location permission denied. Permission required to scan nearby providers.";
            _isLocating = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus = "Location permission permanently denied in device settings. Please enable manually.";
          _isLocating = false;
        });
        return;
      }

      setState(() {
        _locationStatus = "Resolving GPS coordinates...";
      });

      // Try last known position first (fastest on mobile devices)
      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      // If no cached position, get current position with 12s timeout
      if (position == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 12),
          );
        } catch (e) {
          // Retry last known position once more
          try {
            position = await Geolocator.getLastKnownPosition();
          } catch (_) {}
          if (position == null) {
            setState(() {
              _locationStatus = "GPS timeout: Unable to determine coordinates within 12 seconds. Please check device GPS.";
              _isLocating = false;
            });
            return;
          }
        }
      }

      setState(() {
        _latitude = position!.latitude;
        _longitude = position.longitude;
        _locationStatus = "Location detected (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}). Querying directory...";
      });

      final res = await _patientService.getNearbyProviders(
        position.latitude,
        position.longitude,
        radiusKm: showClosest ? 20000.0 : 50.0,
      );

      if (!mounted) return;

      if (res["success"] != true) {
        setState(() {
          _apiError = res["error"] ?? "Failed to load healthcare providers.";
          _locationStatus = _apiError;
          _nearbyProviders = [];
          _isLocating = false;
        });
        return;
      }

      final List<Map<String, dynamic>> providers =
          List<Map<String, dynamic>>.from(res["providers"] ?? []);

      setState(() {
        _nearbyProviders = providers;
        _apiError = null;
        if (showClosest) {
          _locationStatus = "Showing closest registered healthcare facilities (beyond 50 km):";
        } else if (providers.isNotEmpty) {
          _locationStatus = "Location resolved. Found ${providers.length} provider(s) within 50 km.";
        } else {
          _locationStatus = "Location resolved. No providers found within 50 km.";
        }
        _isLocating = false;
      });

    } catch (e) {
      setState(() {
        _locationStatus = "Error resolving location: $e";
        _isLocating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "AI Assistant",
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status indicator banner
            Container(
              color: AppColors.softPink,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: AppColors.deepPink, size: 14),
                  SizedBox(width: 6),
                  Text(
                    "AI Health Education & Assistance",
                    style: TextStyle(color: AppColors.deepPink, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Top safety disclaimer banner
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.softEmergencyBg,
                border: Border.all(color: AppColors.errorRed.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.emergency_outlined, color: AppColors.errorRed, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "This assistant provides health education only. For immediate medical emergencies, call your local ambulance or visit a hospital.",
                      style: TextStyle(fontSize: 11, color: AppColors.textDark, fontWeight: FontWeight.w500, height: 1.3),
                    ),
                  )
                ],
              ),
            ),

            // Chat Messages area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg["isUser"] as bool;
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                          Container(
                            margin: const EdgeInsets.only(top: 6, right: 8),
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: AppColors.softPink,
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/illustrations/ai_assistant_avatar.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: AppColors.premiumPink,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(14),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                          decoration: BoxDecoration(
                            color: isUser ? AppColors.green : AppColors.lightestPink,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isUser ? 16 : 4),
                              bottomRight: Radius.circular(isUser ? 4 : 16),
                            ),
                            border: isUser ? null : Border.all(color: AppColors.babyPink.withOpacity(0.35)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            msg["text"] ?? "",
                            style: TextStyle(
                              color: isUser ? AppColors.white : AppColors.textDark,
                              fontSize: 13.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            if (!isKeyboardOpen) ...[
              // Suggested quick questions
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildSuggestedChip("What does high blood pressure mean?"),
                    _buildSuggestedChip("How can I improve my sleep?"),
                    _buildSuggestedChip("What is my BMI?"),
                    _buildSuggestedChip("What is my allergy warning?"),
                    _buildSuggestedChip("When should I see a doctor?"),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Input Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.borderGrey),
                      ),
                      child: TextField(
                        controller: _inputController,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: "Ask health education questions...",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (val) => _submitMessage(val),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _submitMessage(_inputController.text),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.premiumPink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: AppColors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Find Nearby Doctors Section
            if (!isKeyboardOpen)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGrey, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: AppColors.deepGreen, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Find Nearby Healthcare Providers",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_locationStatus != null) ...[
                      Text(
                        _locationStatus!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _locationStatus!.contains("error") ||
                                  _locationStatus!.contains("denied") ||
                                  _locationStatus!.contains("timeout") ||
                                  _locationStatus!.contains("expired")
                              ? AppColors.errorRed
                              : (_locationStatus!.contains("resolved") || _locationStatus!.contains("successfully")
                                  ? AppColors.green
                                  : AppColors.textDark),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_apiError != null) ...[
                        Container(
                          margin: const EdgeInsets.only(top: 4, bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.softEmergencyBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_apiError!, style: const TextStyle(fontSize: 12, color: AppColors.errorRed)),
                              ),
                              TextButton(
                                onPressed: _isLocating ? null : () => _findNearbyDoctors(),
                                child: const Text("Retry", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.deepGreen)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_latitude != null && _longitude != null) ...[
                        Text(
                          "Coordinates: Lat: ${_latitude!.toStringAsFixed(5)}, Lng: ${_longitude!.toStringAsFixed(5)}",
                          style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontFamily: 'monospace'),
                        ),
                        const SizedBox(height: 10),
                        if (_nearbyProviders.isEmpty && _apiError == null) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "No nearby healthcare providers found within 50 km.",
                                style: TextStyle(fontSize: 12, color: AppColors.textGrey, fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _isLocating ? null : () => _findNearbyDoctors(showClosest: true),
                                icon: const Icon(Icons.travel_explore_rounded, size: 16, color: AppColors.deepGreen),
                                label: const Text(
                                  "Show closest registered facilities",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.deepGreen),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.deepGreen),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ] else if (_nearbyProviders.isNotEmpty) ...[
                          if (_isShowingClosest) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.softMint,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.deepGreen),
                                  const SizedBox(width: 6),
                                  const Expanded(
                                    child: Text(
                                      "Facilities outside 50 km radius:",
                                      style: TextStyle(fontSize: 11, color: AppColors.deepGreen, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _findNearbyDoctors(showClosest: false),
                                    child: const Text("Reset", style: TextStyle(fontSize: 11, color: AppColors.textGrey, decoration: TextDecoration.underline)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 180),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: _nearbyProviders.map((provider) {
                                  final name = provider["name"] ?? "Clinic";
                                  final spec = provider["specialization"] ?? "General";
                                  final dist = provider["distance"] ?? 0.0;
                                  final phone = provider["phone_number"] ?? "N/A";
                                  final status = provider["availability_status"] ?? "available";
                                  final isAvailable = status == "available";

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.borderGrey),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            color: AppColors.softMint,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.local_hospital_rounded, color: AppColors.deepGreen, size: 18),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "$spec • $phone",
                                                style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "${dist.toStringAsFixed(1)} km",
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.deepGreen),
                                            ),
                                            const SizedBox(height: 2),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (isAvailable ? AppColors.green : AppColors.errorRed).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                status.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                  color: isAvailable ? AppColors.green : AppColors.errorRed,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLocating ? null : () => _findNearbyDoctors(showClosest: false),
                        icon: _isLocating
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                            : const Icon(Icons.my_location_rounded, size: 16, color: AppColors.white),
                        label: const Text("Scan Nearby Locations", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepGreen,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
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

  Widget _buildSuggestedChip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ActionChip(
        backgroundColor: AppColors.lightestPink,
        side: BorderSide(color: AppColors.babyPink.withOpacity(0.4)),
        label: Text(text, style: const TextStyle(fontSize: 11.5, color: AppColors.deepPink, fontWeight: FontWeight.bold)),
        onPressed: () => _submitMessage(text),
      ),
    );
  }
}

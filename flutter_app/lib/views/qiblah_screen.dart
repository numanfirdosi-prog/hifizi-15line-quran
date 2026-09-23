import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:provider/provider.dart';
import '../services/prayer_calculation_service.dart';
import '../services/preferences_service.dart';

class QiblahScreen extends StatefulWidget {
  const QiblahScreen({Key? key}) : super(key: key);

  @override
  State<QiblahScreen> createState() => _QiblahScreenState();
}

class _QiblahScreenState extends State<QiblahScreen> {
  double _heading = 0.0;

  @override
  void initState() {
    super.initState();
    FlutterCompass.events?.listen((event) {
      if (mounted && event.heading != null) {
        setState(() {
          _heading = event.heading!;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<PreferencesService>(context);
    final qiblah = PrayerCalculationService.calculateQiblah(
      prefs.selectedCity.lat,
      prefs.selectedCity.lng,
    );

    // Difference between device compass heading and Kaaba bearing
    final diffAngle = (qiblah.bearing - _heading + 360.0) % 360.0;
    final isFacingKaaba = diffAngle < 5.0 || diffAngle > 355.0;

    return Scaffold(
      backgroundColor: const Color(0xFF071F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3A2C),
        title: const Text(
          'قبلہ نما (Qiblah Compass)',
          style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // City & Bearing Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3A2C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                ),
                child: Text(
                  '${prefs.selectedCity.name} • ${qiblah.bearing}° ${qiblah.cardinal} • ${qiblah.distanceKm} km',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 36),

              // Animated Compass Dial
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Dial Ring
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isFacingKaaba ? Colors.greenAccent : const Color(0xFFD4AF37),
                        width: 3,
                      ),
                      color: const Color(0xFF0B2D22),
                      boxShadow: [
                        BoxShadow(
                          color: isFacingKaaba ? Colors.greenAccent.withOpacity(0.4) : const Color(0xFFD4AF37).withOpacity(0.2),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                  ),

                  // Rotating Compass needle (rotates opposite device heading)
                  Transform.rotate(
                    angle: ((_heading * -1) * (math.pi / 180.0)),
                    child: SizedBox(
                      width: 230,
                      height: 230,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Align(
                            alignment: Alignment.topCenter,
                            child: Text('N', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                          const Align(
                            alignment: Alignment.bottomCenter,
                            child: Text('S', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text('E', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('W', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Kaaba Target Needle
                  Transform.rotate(
                    angle: ((qiblah.bearing - _heading) * (math.pi / 180.0)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.navigation, size: 52, color: Color(0xFFD4AF37)),
                        SizedBox(height: 70),
                      ],
                    ),
                  ),

                  // Center Kaaba Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFacingKaaba ? Colors.green : const Color(0xFFD4AF37),
                    ),
                    child: const Icon(Icons.mosque, color: Colors.black, size: 24),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // Status Banner
              Text(
                isFacingKaaba ? '✓ You are facing Kaaba directly!' : 'Turn device to align needle with top',
                style: TextStyle(
                  color: isFacingKaaba ? Colors.greenAccent : const Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


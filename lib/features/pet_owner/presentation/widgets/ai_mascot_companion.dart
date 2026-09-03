import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available 3D AI Mascot Companion styles.
enum AiMascotStyle {
  classic, // 3D Aero Bot (Classic)
  cat,     // 3D Cyber Neko (Cat Bot)
  dog,     // 3D Cyber Pup (Dog Bot)
  astral,  // 3D Astral Bot (Space Chibi)
}

extension AiMascotStyleExt on AiMascotStyle {
  String get assetPath => switch (this) {
        AiMascotStyle.classic => 'assets/images/ai_mascot_classic.jpg',
        AiMascotStyle.cat => 'assets/images/ai_mascot_cat.jpg',
        AiMascotStyle.dog => 'assets/images/ai_mascot_dog.jpg',
        AiMascotStyle.astral => 'assets/images/ai_mascot_astral.jpg',
      };

  String get displayName => switch (this) {
        AiMascotStyle.classic => 'Aero Bot (Classic)',
        AiMascotStyle.cat => 'Cyber Neko (Cat Bot)',
        AiMascotStyle.dog => 'Cyber Pup (Dog Bot)',
        AiMascotStyle.astral => 'Astral Bot (Space Chibi)',
      };

  String get tagline => switch (this) {
        AiMascotStyle.classic => 'Sleek 3D Aerodynamic AI Companion',
        AiMascotStyle.cat => 'Adorable 3D Robotic Cat with Holographic Ears',
        AiMascotStyle.dog => 'Playful 3D Cyber Puppy with Golden Shield',
        AiMascotStyle.astral => 'Cosmic 3D Space Chibi with Celestial Halo',
      };

  Color get glowColor => switch (this) {
        AiMascotStyle.classic => const Color(0xFF06B6D4), // Cyan
        AiMascotStyle.cat => const Color(0xFFEC4899),     // Neon Pink
        AiMascotStyle.dog => const Color(0xFFF59E0B),     // Amber Gold
        AiMascotStyle.astral => const Color(0xFF8B5CF6),  // Cosmic Violet
      };

  List<String> get greetings => switch (this) {
        AiMascotStyle.classic => [
            'Hi! Aero AI here ⚡',
            'Ready to assist your pet! 🤖',
            'Symptom scan ready! 🩺',
            'Ask me anything! 💡',
          ],
        AiMascotStyle.cat => [
            'Nya~ Hi friend! 🐾',
            'Waving paws to you! 🐱',
            'Purr-fect day ahead! 💖',
            'Meow! Need health tips? ✨',
          ],
        AiMascotStyle.dog => [
            'Woof! Hi there! 🐶',
            'Ready for an AI checkup! 🦴',
            'Always happy to help! 🐾',
            'Good dog vibes today! 🌟',
          ],
        AiMascotStyle.astral => [
            'Greetings Explorer! ✨',
            'Cosmic sensors active! 🔮',
            'Scanning pet vitals! 🚀',
            'Starry health alert! 🌌',
          ],
      };

  IconData get emoteIcon => switch (this) {
        AiMascotStyle.classic => Icons.waving_hand_rounded,
        AiMascotStyle.cat => Icons.pets_rounded,
        AiMascotStyle.dog => Icons.celebration_rounded,
        AiMascotStyle.astral => Icons.auto_awesome_rounded,
      };
}

/// Global stream/notifier so both the FAB, AI Hub, and Top AppBar update synchronously.
class MascotChangeNotifier extends ChangeNotifier {
  static final MascotChangeNotifier instance = MascotChangeNotifier._();
  MascotChangeNotifier._();

  AiMascotStyle currentStyle = AiMascotStyle.classic;

  void notifyStyleChanged(AiMascotStyle style) {
    currentStyle = style;
    notifyListeners();
  }
}

/// Opens the bottom sheet modal to choose from the 4 3D character avatars.
void showAiMascotSwitcherModal(
  BuildContext context, {
  required AiMascotStyle currentStyle,
  required ValueChanged<AiMascotStyle> onSelect,
}) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF0F172A),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose 3D AI Mascot Companion',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Freestanding companion with live articulated arm & visor emotes',
                            style: TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.88,
                    physics: const NeverScrollableScrollPhysics(),
                    children: AiMascotStyle.values.map((style) {
                      final isSelected = currentStyle == style;
                      return InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          onSelect(style);
                          setModalState(() {});
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? style.glowColor.withValues(alpha: 0.18)
                                : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? style.glowColor
                                  : Colors.white.withValues(alpha: 0.1),
                              width: isSelected ? 2.2 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: style.glowColor.withValues(alpha: 0.35),
                                      blurRadius: 14,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 72,
                                height: 72,
                                child: FreestandingBotCharacter(
                                  size: 64,
                                  style: style,
                                  glowColor: style.glowColor,
                                  waveRotation: 0.25,
                                  glowValue: 0.8,
                                  emote: '^ ‿ ^',
                                  isCompact: true,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                style.displayName,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                style.tagline,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// **FreestandingBotCharacter**: The freestanding 3D vector-rendered robot model.
///
/// Renders an uncontained, freestanding character featuring:
/// 1. Antenna / cybernetic ears (style specific).
/// 2. Metallic 3D specularity head chassis with ambient shadow.
/// 3. Curved OLED visor with glossy glass reflection and animated digital eyes (`^ ‿ ^`, `★ ‿ ★`, `♥ ‿ ♥`, etc.).
/// 4. Mechanical torso with glowing pulse reactor core.
/// 5. Left resting arm.
/// 6. **Articulated Right Robotic Arm**: Directly attached to the robot's shoulder socket, waving smoothly in an arc.
/// 7. Online status telemetry beacon.
class FreestandingBotCharacter extends StatelessWidget {
  const FreestandingBotCharacter({
    required this.size,
    required this.style,
    required this.glowColor,
    required this.waveRotation,
    required this.glowValue,
    required this.emote,
    this.isCompact = false,
    super.key,
  });

  final double size;
  final AiMascotStyle style;
  final Color glowColor;
  final double waveRotation;
  final double glowValue;
  final String emote;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    // Proportional dimensions based on size
    final w = size;
    final h = size * 1.12;

    final headW = w * 0.72;
    final headH = h * 0.48;

    final visorW = headW * 0.76;
    final visorH = headH * 0.54;

    final bodyW = w * 0.48;
    final bodyH = h * 0.28;

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── 1. Top Antenna / Ears based on Style ────────────────────
          if (style == AiMascotStyle.classic) ...[
            // Aero Classic Antenna
            Positioned(
              top: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: size * 0.12,
                    height: size * 0.12,
                    decoration: BoxDecoration(
                      color: glowColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.95),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 2.5,
                    height: h * 0.10,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ] else if (style == AiMascotStyle.cat) ...[
            // Cyber Neko - Left Holographic Ear
            Positioned(
              top: h * 0.04,
              left: w * 0.18,
              child: Transform.rotate(
                angle: -0.32,
                child: Container(
                  width: size * 0.22,
                  height: size * 0.22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(3),
                      bottomLeft: Radius.circular(3),
                    ),
                    border: Border.all(color: glowColor, width: 1.6),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: size * 0.09,
                      height: size * 0.09,
                      decoration: BoxDecoration(
                        color: glowColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Cyber Neko - Right Holographic Ear
            Positioned(
              top: h * 0.04,
              right: w * 0.18,
              child: Transform.rotate(
                angle: 0.32,
                child: Container(
                  width: size * 0.22,
                  height: size * 0.22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(3),
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(3),
                    ),
                    border: Border.all(color: glowColor, width: 1.6),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: size * 0.09,
                      height: size * 0.09,
                      decoration: BoxDecoration(
                        color: glowColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ] else if (style == AiMascotStyle.dog) ...[
            // Cyber Pup - Left Lop Ear
            Positioned(
              top: h * 0.10,
              left: w * 0.06,
              child: Transform.rotate(
                angle: -0.40,
                child: Container(
                  width: size * 0.18,
                  height: size * 0.30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: glowColor, width: 1.6),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.35),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Cyber Pup - Right Lop Ear
            Positioned(
              top: h * 0.10,
              right: w * 0.06,
              child: Transform.rotate(
                angle: 0.40,
                child: Container(
                  width: size * 0.18,
                  height: size * 0.30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: glowColor, width: 1.6),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.35),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else if (style == AiMascotStyle.astral) ...[
            // Astral Space Chibi - Cosmic Ring Halo
            Positioned(
              top: h * 0.02,
              child: Container(
                width: w * 0.85,
                height: h * 0.20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: glowColor.withValues(alpha: 0.85),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.7),
                      blurRadius: 10,
                      spreadRadius: 1.5,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── 2. Mechanical Torso & Chest Power Core ───────────────────
          Positioned(
            top: h * 0.48,
            child: Container(
              width: bodyW,
              height: bodyH,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF1F5F9),
                    const Color(0xFFE2E8F0),
                    glowColor.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(bodyW * 0.36),
                ),
                border: Border.all(
                  color: glowColor.withValues(alpha: 0.65),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                // Glowing Pulse Reactor Core
                child: Container(
                  width: bodyW * 0.34,
                  height: bodyW * 0.34,
                  decoration: BoxDecoration(
                    color: glowColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: glowColor, width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.85 * glowValue),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: bodyW * 0.14,
                      height: bodyW * 0.14,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 3. Left Resting Arm ──────────────────────────────────────
          Positioned(
            top: h * 0.50,
            left: w * 0.14,
            child: Transform.rotate(
              angle: -0.22,
              child: Container(
                width: size * 0.12,
                height: h * 0.22,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(size * 0.06),
                  border: Border.all(
                    color: glowColor.withValues(alpha: 0.55),
                    width: 1.0,
                  ),
                ),
              ),
            ),
          ),

          // ── 4. ARTICULATED WAVING ARM & ROBOTIC HAND (Right Shoulder) ─
          // Connected directly to the bot's right shoulder joint!
          Positioned(
            top: h * 0.24,
            right: w * 0.02,
            child: Transform.rotate(
              angle: waveRotation,
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Robotic Hand / Cybernetic Paw
                  Container(
                    width: size * 0.24,
                    height: size * 0.24,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.white,
                          glowColor.withValues(alpha: 0.25),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: glowColor, width: 2.0),
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.9 * glowValue),
                          blurRadius: 10,
                          spreadRadius: 1.5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        style.emoteIcon,
                        size: size * 0.13,
                        color: glowColor,
                      ),
                    ),
                  ),
                  // Upper Arm Link to Shoulder Joint
                  Container(
                    width: size * 0.08,
                    height: h * 0.18,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(size * 0.04),
                      border: Border.all(
                        color: glowColor.withValues(alpha: 0.65),
                        width: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 5. Main Robot Head Chassis (Specular Metallic Gradient) ───
          Positioned(
            top: h * 0.12,
            child: Container(
              width: headW,
              height: headH,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFFFFFF),
                    const Color(0xFFF8FAFC),
                    const Color(0xFFE2E8F0),
                    glowColor.withValues(alpha: 0.38),
                  ],
                  stops: const [0.0, 0.35, 0.75, 1.0],
                ),
                borderRadius: BorderRadius.circular(headW * 0.38),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: glowValue * 0.5),
                    blurRadius: 18,
                    spreadRadius: 1.5,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: glowColor.withValues(alpha: 0.85),
                  width: 1.6,
                ),
              ),
              child: Center(
                // ── 6. Glowing OLED Digital Visor ──────────────────────
                child: Container(
                  width: visorW,
                  height: visorH,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1120),
                    borderRadius: BorderRadius.circular(visorH * 0.48),
                    border: Border.all(
                      color: glowColor.withValues(alpha: 0.75),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Curved Gloss Reflection
                      Positioned(
                        top: 2,
                        left: 6,
                        right: 6,
                        height: 5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      // Animated Digital Cyber Eyes Emote
                      Center(
                        child: Text(
                          emote,
                          style: TextStyle(
                            color: glowColor,
                            fontSize: isCompact ? 10 : 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(color: glowColor, blurRadius: 8),
                              Shadow(color: Colors.white.withValues(alpha: 0.9), blurRadius: 3),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 7. Mini Online Telemetry Beacon ──────────────────────────
          Positioned(
            bottom: 4,
            right: w * 0.16,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.85),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// **AiMascotCompanion**: Interactive 3D Mascot Character with live floating physics,
/// continuous articulated arm waving, digital visor emotes, and 4-character switcher.
class AiMascotCompanion extends StatefulWidget {
  const AiMascotCompanion({
    this.size = 80,
    this.showSpeechBubble = true,
    this.showSwitcherBadge = true,
    this.isAppBarMode = false,
    this.onTap,
    this.heroTag,
    super.key,
  });

  final double size;
  final bool showSpeechBubble;
  final bool showSwitcherBadge;
  final bool isAppBarMode;
  final VoidCallback? onTap;
  final String? heroTag;

  @override
  State<AiMascotCompanion> createState() => _AiMascotCompanionState();
}

class _AiMascotCompanionState extends State<AiMascotCompanion>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _waveController;
  late AnimationController _bubbleController;
  late AnimationController _pulseController;
  late AnimationController _bounceController;

  late Animation<double> _floatAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _waveRotation;
  late Animation<double> _waveScale;
  late Animation<double> _bubbleFade;
  late Animation<Offset> _bubbleSlide;
  late Animation<double> _pulseScale;
  late Animation<double> _bounceScale;

  AiMascotStyle _selectedMascot = AiMascotStyle.classic;
  bool _pressed = false;
  String _currentGreeting = 'Hi! Aero AI here ⚡';
  Timer? _greetingTimer;
  int _greetingIndex = 0;
  int _emoteCycleIndex = 0;

  static const List<String> _digitalEmotes = [
    '^ ‿ ^',
    '★ ‿ ★',
    '♥ ‿ ♥',
    '• ‿ •',
    '^ ‿ ~',
    'o ‿ o',
    '✦ ‿ ✦',
  ];

  @override
  void initState() {
    super.initState();
    _loadMascotPreference();
    MascotChangeNotifier.instance.addListener(_handleExternalMascotChange);

    // 0. Bouncy Entry & Interaction Spring Physics (650ms elasticOut)
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _bounceScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    _bounceController.forward();

    // 1. Dual-Harmonic Floating Physics (Slower, gentle 3800ms hover loop)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    _glowAnim = Tween<double>(begin: 0.45, end: 0.95).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    // 2. Active Articulated Robotic Arm Waving Animation (Gentle, organic 2200ms wave)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _waveRotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.42), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 0.42, end: -0.20), weight: 35),
      TweenSequenceItem(tween: Tween(begin: -0.20, end: -0.12), weight: 20),
    ]).animate(CurvedAnimation(parent: _waveController, curve: Curves.easeInOutSine));

    _waveScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.04), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _waveController, curve: Curves.easeInOut));

    // 3. Pulse Aura Controller (3000ms)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 4. Speech Bubble Intro/Outro Animation
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _bubbleFade = CurvedAnimation(parent: _bubbleController, curve: Curves.easeOut);
    _bubbleSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _bubbleController, curve: Curves.easeOutBack));

    if (!widget.isAppBarMode) {
      // Initial greeting after 1.5s & recurring wave greeting every 8s
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _triggerEmoteWave();
      });

      _greetingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
        if (mounted) _triggerEmoteWave();
      });
    }
  }

  void _handleExternalMascotChange() {
    if (!mounted) return;
    setState(() {
      _selectedMascot = MascotChangeNotifier.instance.currentStyle;
      _currentGreeting = _selectedMascot.greetings.first;
    });
    _bounceController.forward(from: 0.0);
    _triggerEmoteWave();
  }

  void _triggerEmoteWave() {
    final greetings = _selectedMascot.greetings;
    _greetingIndex = (_greetingIndex + 1) % greetings.length;
    _emoteCycleIndex = (_emoteCycleIndex + 1) % _digitalEmotes.length;

    if (mounted) {
      setState(() {
        _currentGreeting = greetings[_greetingIndex];
      });
    }

    _bounceController.forward(from: 0.0);
    _waveController.forward(from: 0.0);
    if (widget.showSpeechBubble && !widget.isAppBarMode) {
      _bubbleController.forward(from: 0.0);
      Future.delayed(const Duration(milliseconds: 3200), () {
        if (mounted) {
          _bubbleController.reverse();
        }
      });
    }
  }

  Future<void> _loadMascotPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('selected_ai_mascot_style') ?? 0;
    if (savedIndex >= 0 && savedIndex < AiMascotStyle.values.length) {
      if (mounted) {
        setState(() {
          _selectedMascot = AiMascotStyle.values[savedIndex];
          _currentGreeting = _selectedMascot.greetings.first;
        });
        MascotChangeNotifier.instance.currentStyle = _selectedMascot;
      }
    }
  }

  Future<void> _setMascot(AiMascotStyle style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_ai_mascot_style', style.index);
    if (mounted) {
      setState(() {
        _selectedMascot = style;
        _currentGreeting = style.greetings.first;
      });
      MascotChangeNotifier.instance.notifyStyleChanged(style);
      unawaited(_bounceController.forward(from: 0.0));
      _triggerEmoteWave();
    }
  }

  void _openSwitcher() {
    showAiMascotSwitcherModal(
      context,
      currentStyle: _selectedMascot,
      onSelect: _setMascot,
    );
  }

  @override
  void dispose() {
    MascotChangeNotifier.instance.removeListener(_handleExternalMascotChange);
    _greetingTimer?.cancel();
    _bounceController.dispose();
    _floatController.dispose();
    _waveController.dispose();
    _bubbleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = _selectedMascot.glowColor;
    final currentEmote = _digitalEmotes[_emoteCycleIndex % _digitalEmotes.length];
    final size = widget.size;

    // In AppBar mode: lightweight compact rendering
    if (widget.isAppBarMode) {
      return AnimatedBuilder(
        animation: Listenable.merge([_floatController, _waveController]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnim.value * 0.4),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _triggerEmoteWave();
                widget.onTap?.call();
              },
              child: ScaleTransition(
                scale: _bounceScale,
                child: FreestandingBotCharacter(
                  size: size,
                  style: _selectedMascot,
                  glowColor: glowColor,
                  waveRotation: _waveRotation.value * 1.8,
                  glowValue: _glowAnim.value,
                  emote: currentEmote,
                  isCompact: true,
                ),
              ),
            ),
          );
        },
      );
    }

    return SizedBox(
      width: size + 40,
      height: size * 1.4 + 40,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // ── Speech Bubble Balloon ──────────────────────────────────
          if (widget.showSpeechBubble)
            Positioned(
              top: 0,
              right: 2,
              child: FadeTransition(
                opacity: _bubbleFade,
                child: SlideTransition(
                  position: _bubbleSlide,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    constraints: const BoxConstraints(maxWidth: 160),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.94),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(2),
                      ),
                      border: Border.all(
                        color: glowColor.withValues(alpha: 0.7),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.35),
                          blurRadius: 10,
                        ),
                        const BoxShadow(
                          color: Colors.black54,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      _currentGreeting,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),

          // ── Mascot Character Body with Smooth Floating Animation ────
          Positioned(
            bottom: 6,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _floatController,
                _waveController,
                _pulseController,
              ]),
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatAnim.value),
                  child: GestureDetector(
                    onLongPress: _openSwitcher,
                    onDoubleTap: _openSwitcher,
                    onTapDown: (_) => setState(() => _pressed = true),
                    onTapUp: (_) => setState(() => _pressed = false),
                    onTapCancel: () => setState(() => _pressed = false),
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      _triggerEmoteWave();
                      widget.onTap?.call();
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Soft Ambient Ground Glow Shadow
                        Positioned(
                          bottom: -8,
                          child: Container(
                            width: size * 0.65,
                            height: 12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: glowColor.withValues(alpha: _glowAnim.value * 0.45),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                                const BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Subtle Pulsing Halo Ring
                        Transform.scale(
                          scale: _pulseScale.value,
                          child: Container(
                            width: size * 0.95,
                            height: size * 0.95,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: glowColor.withValues(alpha: _glowAnim.value * 0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: glowColor.withValues(alpha: _glowAnim.value * 0.25),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Freestanding 3D Mascot Character Widget
                        Hero(
                          tag: widget.heroTag ?? 'ai-mascot-avatar-hero',
                          child: ScaleTransition(
                            scale: _bounceScale,
                            child: Transform.scale(
                              scale: _pressed ? 0.92 : _waveScale.value,
                              child: FreestandingBotCharacter(
                                size: size,
                                style: _selectedMascot,
                                glowColor: glowColor,
                                waveRotation: _waveRotation.value * 2.8,
                                glowValue: _glowAnim.value,
                                emote: currentEmote,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

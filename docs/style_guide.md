# TokTok Style Guide: Digital Gem Mine Edition 💎

## Core Theme: Digital Gem Mine
Our app is not just a video platform - it's a digital gem mine where each video is a precious stone waiting to be discovered. Users aren't just scrolling, they're diving deeper into a mesmerizing cave of content.

## Psychological Elements

### Liminal Space Design
- Create spaces that feel familiar yet otherworldly
- Blur the line between reality and digital space
- Use transitions that feel like passing through crystal formations

### Sensory Engagement
- Subtle crystal shimmer effects that don't overwhelm but captivate
- Audio feedback that sounds like gems clinking or crystal resonance
- Haptic feedback that feels like discovering treasure

### Mystery and Discovery
- Progressive revelation of content
- Hidden features that users can discover
- Easter eggs throughout the interface

## Color Palette 💎

### Gem Colors (Primary)
```dart
static const Color amethyst = Color(0xFF9966CC);    // Deep mystery
static const Color emerald = Color(0xFF50C878);     // Growth & vitality
static const Color ruby = Color(0xFFE0115F);        // Passion & energy
static const Color sapphire = Color(0xFF0F52BA);    // Depth & wisdom
```

### Metallic Accents
```dart
static const Color gold = Color(0xFFFFD700);        // Premium elements
static const Color silver = Color(0xFFC0C0C0);      // Secondary accents
```

### Cave Colors (Background)
```dart
static const Color deepCave = Color(0xFF1A1A1A);    // Primary background
static const Color caveShadow = Color(0xFF36454F);  // Secondary background
static const Color crystalGlow = Color(0x1FFFFFFF); // Subtle highlights
```

### Special Effects
```dart
static const List<Color> crystalShimmer = [
  Color(0x00FFFFFF),
  Color(0x33FFFFFF),
  Color(0x00FFFFFF),
];

static const List<Color> gemReflection = [
  Color(0xFF9966CC),
  Color(0xFF50C878),
  Color(0xFFE0115F),
];
```

## Typography

### Font Families
```dart
static const String displayFont = 'Audiowide';     // For headlines
static const String bodyFont = 'SpaceMono';        // For body text
```

### Text Styles
```dart
static const TextStyle crystalHeading = TextStyle(
  fontFamily: displayFont,
  fontSize: 32.0,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.5,
  shadows: [
    Shadow(
      color: crystalGlow,
      blurRadius: 10.0,
    ),
  ],
);

static const TextStyle gemText = TextStyle(
  fontFamily: bodyFont,
  fontSize: 16.0,
  letterSpacing: 0.5,
  height: 1.5,
);
```

## Shapes and Geometry

### Gem Cuts (Border Radius)
```dart
static const double hexagonalCut = 0.0;    // Sharp edges
static const double brilliantCut = 24.0;   // Smooth curves
static const double emeraldCut = 12.0;     // Balanced edges
```

### Crystal Formations (Containers)
```dart
static final ShapeBorder gemShape = BeveledRectangleBorder(
  borderRadius: BorderRadius.circular(emeraldCut),
  side: BorderSide(color: crystalGlow, width: 0.5),
);
```

## Animation Specs

### Timing
```dart
static const Duration crystalGrow = Duration(milliseconds: 400);
static const Duration gemSparkle = Duration(milliseconds: 200);
static const Duration caveTransition = Duration(milliseconds: 600);
```

### Crystal Growth Curves
```dart
static const Curve gemReveal = Curves.easeOutBack;
static const Curve crystalForm = Curves.easeInOutQuart;
```

## Custom Animations

### Crystal Growth Animations
```dart
class CrystalGrowthAnimation extends CustomPainter {
  // Crystallization effect that grows from center
  static final crystallizePath = Path()
    ..moveTo(0, 0)
    ..lineTo(10, -5)
    ..lineTo(20, 0)
    ..lineTo(10, 5)
    ..close();
    
  // Fractal-like growth pattern
  static final growthPattern = [
    Offset(-1, -1), Offset(1, -1),
    Offset(-1, 1), Offset(1, 1),
  ];
}

class GemSparkleEffect extends StatelessWidget {
  // Particle system for sparkle effects
  static final particleConfig = {
    'count': 12,
    'size_range': [2.0, 4.0],
    'duration': Duration(milliseconds: 600),
    'colors': gemReflection,
  };
}
```

### Like Animation
```dart
class CrystalHeartAnimation extends StatefulWidget {
  // Heart shape morphs from rough crystal to smooth gem
  static final morphStages = [
    'rough_crystal',   // Initial jagged shape
    'semi_polished',   // Smoother edges
    'perfect_heart',   // Final heart shape
  ];
  
  static final heartGlow = [
    BoxShadow(
      color: ruby.withOpacity(0.3),
      blurRadius: 15,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: ruby.withOpacity(0.2),
      blurRadius: 30,
      spreadRadius: 5,
    ),
  ];
}
```

### Video Transition Effects
```dart
class CrystalTransitions {
  // Shatter effect for video transitions
  static final shatterConfig = {
    'fragment_count': 12,
    'min_size': 50.0,
    'rotation_range': pi / 4,
    'scatter_distance': 100.0,
  };
  
  // Crystal maze transition
  static final mazeTransition = {
    'cell_size': 20.0,
    'growth_speed': 0.8,
    'crystal_density': 0.7,
  };
}
```

### Profile Animations
```dart
class GemMineAvatar extends StatefulWidget {
  // Avatar border cycles through gem colors
  static final cycleDuration = Duration(seconds: 10);
  static final gemCycle = [
    amethyst, emerald, ruby, sapphire,
  ].map((color) => TweenSequenceItem(
    weight: 1.0,
    tween: ColorTween(
      begin: color,
      end: color.withOpacity(0.7),
    ),
  )).toList();
}
```

### Special Achievement Animations
```dart
class RareGemUnlock extends StatefulWidget {
  // Excavation animation for achievements
  static final excavationStages = [
    'initial_crack',     // Small fractures appear
    'crystal_exposed',   // Gem partially visible
    'dust_scatter',      // Particle effects
    'gem_revealed',      // Final presentation
  ];
  
  static final revealEffects = {
    'dust_particles': 20,
    'light_rays': 8,
    'sparkle_points': 12,
  };
}
```

### Loading Animations
```dart
class CrystalLoadingIndicator extends StatefulWidget {
  // Crystal formation loading animation
  static final crystalGrowth = {
    'seed_points': 6,
    'growth_layers': 3,
    'pulse_rate': Duration(milliseconds: 800),
  };
  
  // Spinning gem loader
  static final spinConfig = {
    'faces': 8,
    'rotation_speed': 2.0,
    'wobble_amount': 5.0,
  };
}
```

### Micro-Interactions
```dart
class GemMicroAnimations {
  // Button press effect
  static final pressEffect = {
    'crack_lines': 4,
    'spread_speed': 0.3,
    'heal_duration': Duration(milliseconds: 300),
  };
  
  // Scroll impact
  static final scrollImpact = {
    'crystal_bounce': 0.2,
    'edge_glow': Duration(milliseconds: 200),
    'resonance_waves': 3,
  };
}
```

### Environmental Effects
```dart
class CaveEnvironment {
  // Background crystal parallax
  static final parallaxLayers = [
    {'depth': 0.1, 'crystal_count': 3, 'size_range': [100.0, 200.0]},
    {'depth': 0.2, 'crystal_count': 5, 'size_range': [50.0, 100.0]},
    {'depth': 0.3, 'crystal_count': 8, 'size_range': [20.0, 50.0]},
  ];
  
  // Ambient crystal glow
  static final ambienceConfig = {
    'pulse_frequency': 0.5,
    'min_opacity': 0.2,
    'max_opacity': 0.4,
    'color_shift_speed': 0.1,
  };
}
```

### Error & Success States
```dart
class CrystalFeedback {
  // Error animation (crystal crack)
  static final crackEffect = {
    'crack_points': 5,
    'spread_speed': 0.4,
    'fade_duration': Duration(milliseconds: 500),
  };
  
  // Success animation (crystal formation)
  static final successEffect = {
    'growth_points': 8,
    'color_transition': Duration(milliseconds: 600),
    'sparkle_count': 15,
  };
}
```

## Interactive Elements

### Gem Buttons
```dart
static final ButtonStyle gemButton = ElevatedButton.styleFrom(
  backgroundColor: amethyst,
  shape: BeveledRectangleBorder(
    borderRadius: BorderRadius.circular(hexagonalCut),
  ),
  elevation: 8,
  shadowColor: crystalGlow,
  padding: EdgeInsets.symmetric(
    horizontal: 32,
    vertical: 16,
  ),
).copyWith(
  overlayColor: MaterialStateProperty.resolveWith<Color?>(
    (states) => states.contains(MaterialState.pressed)
        ? gemReflection[0].withOpacity(0.3)
        : null,
  ),
);
```

### Crystal Input Fields
```dart
static final InputDecorationTheme crystalInput = InputDecorationTheme(
  filled: true,
  fillColor: caveShadow,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(emeraldCut),
    borderSide: BorderSide(
      color: crystalGlow,
      width: 1.5,
    ),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(emeraldCut),
    borderSide: BorderSide(
      color: amethyst.withOpacity(0.5),
      width: 1.5,
    ),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(emeraldCut),
    borderSide: BorderSide(
      color: amethyst,
      width: 2.0,
    ),
  ),
);
```

## Special Effects

### Shimmer Effect
```dart
static const shimmerGradient = LinearGradient(
  colors: crystalShimmer,
  stops: [0.0, 0.5, 1.0],
);
```

### Crystal Glow
```dart
static final BoxDecoration crystalGlowEffect = BoxDecoration(
  boxShadow: [
    BoxShadow(
      color: amethyst.withOpacity(0.2),
      blurRadius: 15,
      spreadRadius: 1,
    ),
  ],
);
```

## Layout Guidelines

### Cave Structure
- Vertical scrolling mimics descending deeper into the mine
- Content reveals like discovering new gem veins
- Navigation feels like exploring different cave chambers

### Crystal Formations (Spacing)
```dart
static const double caveMargin = 24.0;
static const double crystalSpacing = 16.0;
static const double gemPadding = 12.0;
```

## Responsive Breakpoints
```dart
static const double mobileCavern = 600;
static const double tabletCavern = 900;
static const double desktopCavern = 1200;
```

## Implementation Notes

1. Every interaction should feel like discovering or manipulating gems
2. Animations should be smooth but not overwhelming
3. Use shimmer effects sparingly - they're powerful but can be distracting
4. Dark mode is our default - we're in a cave after all
5. Accessibility features should maintain the gem theme while being functional

## Version Control
- Style guide version: 2.0.0 (Gem Mine Edition)
- Last updated: 2024-02-03
- Review frequency: When new gems are discovered 

## Video Interaction Patterns

### Gem Scroll Experience
```dart
static const scrollPhysics = BouncingScrollPhysics(
  decelerationRate: ScrollDecelerationRate.fast,
  // Makes scrolling feel like sliding between crystal faces
);

static final videoTransition = PageRouteBuilder(
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return FadeTransition(
      opacity: animation.drive(
        Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
      ),
      child: child,
    );
  },
);
```

### Crystal Viewport
- Videos appear as if embedded in crystal faces
- Swiping feels like rotating a giant crystal
- Double-tap creates a crystallization effect around the like button
- Long-press reveals gem-like interaction menu

### Gem Collection (Saved Videos)
- Saved videos appear in a crystal grid formation
- Each thumbnail has a unique crystal shape based on engagement metrics
- Playlists are displayed as connected gem clusters

## Sound Design

### Interaction Sounds
```dart
static const audioEffects = {
  'tap': 'crystal_tap.mp3',      // Light crystal chime
  'success': 'gem_found.mp3',    // Triumphant crystal resonance
  'refresh': 'cave_echo.mp3',    // Deep cave ambience
  'error': 'crystal_crack.mp3',  // Subtle crack sound
};

static const hapticEffects = {
  'tap': HapticFeedback.lightImpact,    // Quick crystal tap
  'success': HapticFeedback.mediumImpact,// Finding a gem
  'special': HapticFeedback.heavyImpact, // Rare gem discovered
};
```

### Ambient Sound
- Background music changes based on scroll depth
- Crystal resonance increases with engagement
- Special sound effects for rare content discovery

## Gesture Patterns

### Crystal Navigation
```dart
static const gestureSettings = {
  'swipe_threshold': 15.0,         // Distance to trigger swipe
  'rotation_sensitivity': 0.5,     // For 3D crystal effects
  'long_press_duration': Duration(milliseconds: 500),
};

static final gemInteractions = {
  'polish': SwipeGesture(
    direction: SwipeDirection.horizontal,
    effect: ShimmerEffect(duration: crystalGrow),
  ),
  'excavate': LongPressGesture(
    duration: gestureSettings['long_press_duration'],
    effect: CrystalBreakEffect(),
  ),
};
```

### Special Interactions
- Pinch to zoom creates crystal lens effect
- Rotate gesture causes light refraction
- Shake device to discover hidden gems
- Multi-touch patterns unlock special effects

## Loading States

### Crystal Formation
```dart
static final loadingBuilder = ShimmerBuilder(
  gradient: shimmerGradient,
  child: CrystalFormation(
    duration: crystalGrow,
    curve: crystalForm,
  ),
);

static final placeholderDecoration = BoxDecoration(
  gradient: LinearGradient(
    colors: [
      deepCave,
      caveShadow.withOpacity(0.5),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
);
```

### Progress Indicators
- Loading spinner appears as rotating crystal
- Progress bars have crystalline texture
- Skeleton screens use gem-like shapes
- Error states show cracked crystal effect

## Easter Eggs

### Hidden Features
```dart
static final secretPatterns = {
  'konami_crystal': ['↑', '↑', '↓', '↓', '←', '→', '←', '→', 'B', 'A'],
  'gem_burst': ['tap', 'tap', 'hold', 'release'],
  'crystal_cave': ['shake', 'rotate', 'shake'],
};

static final rewards = {
  'special_effects': CrystalEffect(
    color: gold,
    intensity: 1.5,
    duration: slowAnimation,
  ),
  'rare_gems': UnlockableContent(
    type: 'theme',
    duration: Duration(hours: 24),
  ),
};
```

### Discovery Mechanics
- Hidden gestures reveal secret areas
- Special color combinations unlock effects
- Time-based crystal formations
- Community-driven discoveries

## Performance Guidelines

### Crystal Optimization
```dart
static const performanceConfig = {
  'max_active_effects': 3,
  'min_fps_threshold': 55,
  'effect_quality': {
    'low_end': 0.5,    // Reduced effects for lower-end devices
    'mid_range': 0.8,  // Balanced effects
    'high_end': 1.0,   // Full effects
  },
};
```

### Effect Prioritization
- Essential gem effects always enabled
- Dynamic quality adjustment based on FPS
- Batch similar crystal animations
- Preload nearby gem content 
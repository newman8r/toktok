import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// Manages the app's sound design system, including binaural beats,
/// ethereal sounds, and interaction feedback.
class SoundTheme {
  // Binaural Beat Frequencies
  static const double sacredFrequency = 432.0;
  static const double loveFrequency = 528.0;
  static const double problemSolvingFrequency = 741.0;

  // Volume Levels
  static const double binauralBaseVolume = 0.15;
  static const double etherealBaseVolume = 0.3;
  static const double interactionBaseVolume = 0.5;

  // Durations
  static const Duration shortSound = Duration(milliseconds: 200);
  static const Duration mediumSound = Duration(milliseconds: 500);
  static const Duration longSound = Duration(milliseconds: 800);

  // Asset Paths
  static const String _audioPath = 'assets/audio';
  
  // Ethereal Sounds
  static final Map<String, String> etherealSounds = {
    'windChimes': '$_audioPath/wind_chimes.mp3',
    'waterFlow': '$_audioPath/water_flow.mp3',
    'crystalEcho': '$_audioPath/crystal_echo.mp3',
    'mysticalWhisper': '$_audioPath/mystical_whisper.mp3',
  };

  // Interaction Sounds
  static final Map<String, String> interactionSounds = {
    'gemClick': '$_audioPath/gem_click.mp3',
    'crystalChime': '$_audioPath/crystal_chime.mp3',
    'deepEcho': '$_audioPath/deep_echo.mp3',
    'magicalComplete': '$_audioPath/magical_complete.mp3',
  };

  // Scroll Sounds
  static final Map<String, String> scrollSounds = {
    'gemShimmer': '$_audioPath/gem_shimmer.mp3',
    'crystalSlide': '$_audioPath/crystal_slide.mp3',
  };

  // Voice Command Sounds
  static final Map<String, String> voiceCommandSounds = {
    'magicStart': '$_audioPath/magic_start.mp3',
    'magicEnd': '$_audioPath/magic_end.mp3',
  };

  // Content Creation Sounds
  static final Map<String, String> creationSounds = {
    'startCreating': '$_audioPath/start_creating.mp3',
    'finishCreating': '$_audioPath/finish_creating.mp3',
  };

  // Singleton instance
  static final SoundTheme _instance = SoundTheme._internal();
  factory SoundTheme() => _instance;
  SoundTheme._internal();

  // Audio players
  late AudioPlayer binauralPlayer;
  late AudioPlayer etherealPlayer;
  late AudioPlayer effectsPlayer;

  // User preferences
  bool _isSoundEnabled = true;
  bool _isBinauralEnabled = true;
  double _masterVolume = 0.7;

  // Initialize the sound system
  Future<void> initialize() async {
    binauralPlayer = AudioPlayer();
    etherealPlayer = AudioPlayer();
    effectsPlayer = AudioPlayer();
    
    // Load and prepare binaural beats
    await _prepareBinauralBeats();
  }

  // Prepare binaural beats with specified frequencies
  Future<void> _prepareBinauralBeats() async {
    // TODO: Implement binaural beat generation using specified frequencies
    // This will require a custom audio source that generates the beats
  }

  // Play interaction sound
  Future<void> playInteractionSound(String soundKey) async {
    if (!_isSoundEnabled) return;
    
    final soundPath = interactionSounds[soundKey];
    if (soundPath != null) {
      await effectsPlayer.setAsset(soundPath);
      await effectsPlayer.setVolume(interactionBaseVolume * _masterVolume);
      await effectsPlayer.play();
    }
  }

  // Start ambient ethereal sounds
  Future<void> startEtherealAmbience() async {
    if (!_isSoundEnabled) return;
    
    await etherealPlayer.setAsset(etherealSounds['waterFlow']!);
    await etherealPlayer.setVolume(etherealBaseVolume * _masterVolume);
    await etherealPlayer.setLoopMode(LoopMode.one);
    await etherealPlayer.play();
  }

  // Toggle binaural beats
  void toggleBinauralBeats() {
    _isBinauralEnabled = !_isBinauralEnabled;
    if (_isBinauralEnabled) {
      binauralPlayer.play();
    } else {
      binauralPlayer.pause();
    }
  }

  // Set master volume
  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
    _updateAllVolumes();
  }

  // Update volumes for all players
  void _updateAllVolumes() {
    if (_isSoundEnabled) {
      binauralPlayer.setVolume(binauralBaseVolume * _masterVolume);
      etherealPlayer.setVolume(etherealBaseVolume * _masterVolume);
      effectsPlayer.setVolume(interactionBaseVolume * _masterVolume);
    }
  }

  // Toggle all sounds
  void toggleSound() {
    _isSoundEnabled = !_isSoundEnabled;
    if (!_isSoundEnabled) {
      binauralPlayer.pause();
      etherealPlayer.pause();
      effectsPlayer.pause();
    } else {
      if (_isBinauralEnabled) binauralPlayer.play();
      etherealPlayer.play();
    }
  }

  // Dispose of audio resources
  void dispose() {
    binauralPlayer.dispose();
    etherealPlayer.dispose();
    effectsPlayer.dispose();
  }
} 
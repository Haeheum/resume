import 'dart:async';
import 'dart:collection';
import 'dart:developer' as dev;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../util/global_constants.dart';
import '../../util/global_methods.dart';
import 'background_music.dart';

class WidgetAudioController extends StatefulWidget {
  const WidgetAudioController({super.key, required this.child});

  final Widget child;

  static WidgetAudioControllerState of(BuildContext context) {
    return context.findAncestorStateOfType<WidgetAudioControllerState>()!;
  }

  @override
  State<WidgetAudioController> createState() => WidgetAudioControllerState();
}

class WidgetAudioControllerState extends State<WidgetAudioController> {
  static const _bgmPlayerId = 'bgmPlayer';

  late final AppLifecycleListener _appLifecycleListener;
  late final AudioPlayer _bgmPlayer;
  late Queue<BackgroundMusic> _bgmPlaylist;

  bool shouldPlay = false;
  ValueNotifier<String> artistName = ValueNotifier('');
  ValueNotifier<String> musicName = ValueNotifier('');
  ValueNotifier<double> volume = ValueNotifier(kDefaultVolume);

  bool _isRunning = false;
  Timer? _debounceTimer;

  void attachLifecycleChangeHandler() {
    _appLifecycleListener = AppLifecycleListener(
      onResume: () {
        if (shouldPlay) {
          _bgmPlayer.resume();
        }
      },
      onInactive: () {
        if (_bgmPlayer.state == PlayerState.playing) {
          _bgmPlayer.pause();
        }
      },
    );
  }

  void initializeAudio() async {
    AudioCache(prefix: '');
    List<String> loadList = backgroundMusics
        .map((music) => 'sounds/bgm/${music.filename}')
        .toList();

    for (String fileName in loadList) {
      AudioCache.instance.loadPath(fileName).whenComplete(() {
        debugPrint('$fileName loaded');
      });
    }

    _bgmPlayer = AudioPlayer(playerId: _bgmPlayerId)..setVolume(kDefaultVolume);
    _bgmPlaylist =
        Queue.of(List<BackgroundMusic>.of(backgroundMusics)..shuffle());

    artistName.value = _bgmPlaylist.first.artistName;
    musicName.value = _bgmPlaylist.first.musicName;

    _bgmPlayer.onPlayerComplete.listen(nextBgm);
  }

  @override
  void initState() {
    super.initState();
    attachLifecycleChangeHandler();
    initializeAudio();
  }

  @override
  void dispose() {
    _appLifecycleListener.dispose();
    _bgmPlayer.dispose();
    super.dispose();
  }

  Future<void> _playFirstBgm(String filename) async {
    if (!_isRunning) {
      _isRunning = true;
      shouldPlay = true;
      await _bgmPlayer
          .play(AssetSource('sounds/bgm/$filename'))
          .whenComplete(() {
        _isRunning = false;
        if (_bgmPlaylist.first.filename != filename) {
          _playFirstBgm(_bgmPlaylist.first.filename);
        }
      });
    }
  }

  void nextBgm(void _) {
    _bgmPlayer.stop();

    _bgmPlaylist.addLast(_bgmPlaylist.removeFirst());
    artistName.value = _bgmPlaylist.first.artistName;
    musicName.value = _bgmPlaylist.first.musicName;

    if (shouldPlay) {
      kDebounce(
          action: () {
            _playFirstBgm(_bgmPlaylist.first.filename);
          },
          debounceTimer: _debounceTimer);
    }
  }

  void previousBgm() async {
    Duration? currentPosition = await _bgmPlayer.getCurrentPosition();
    _bgmPlayer.stop();

    if (currentPosition == null ||
        currentPosition.compareTo(const Duration(seconds: 2)) <= 0) {
      _bgmPlaylist.addFirst(_bgmPlaylist.removeLast());
      artistName.value = _bgmPlaylist.first.artistName;
      musicName.value = _bgmPlaylist.first.musicName;
    }

    if (shouldPlay) {
      kDebounce(
          action: () {
            _playFirstBgm(_bgmPlaylist.first.filename);
          },
          debounceTimer: _debounceTimer);
    }
  }

  void pauseBgm() {
    if (_bgmPlayer.state == PlayerState.playing) {
      _bgmPlayer.pause();
    }
    shouldPlay = false;
  }

  Future<void> playBgm() async {
    switch (_bgmPlayer.state) {
      case PlayerState.paused:
        try {
          await _bgmPlayer.resume();
          shouldPlay = true;
        } catch (e) {
          dev.log(name: 'AudioError', 'Failed to resume bgm');
          kDebounce(
              action: () {
                _playFirstBgm(_bgmPlaylist.first.filename);
              },
              debounceTimer: _debounceTimer);
        }
        break;
      case PlayerState.stopped:
      case PlayerState.completed:
        kDebounce(
            action: () {
              _playFirstBgm(_bgmPlaylist.first.filename);
            },
            debounceTimer: _debounceTimer);
        break;
      case PlayerState.playing:
      case PlayerState.disposed:
        dev.log(name: 'AudioError', 'Bad audio player state');
        break;
    }
  }

  Future<void> setBgmVolume(double newVolume) async {
    volume.value = newVolume;
    if (!_isRunning) {
      _isRunning = true;
      await _bgmPlayer.setVolume(newVolume).whenComplete(() {
        _isRunning = false;
        if (volume.value != newVolume) {
          setBgmVolume(volume.value);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

import 'dart:convert';
import 'package:http/http.dart' as htp;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../domain/audio_metadata.dart';
import './player_buttons.dart';
import './playlist.dart';

/// An audio player.
///
/// At the bottom of the page there is [PlayerButtons], while the rest of the
/// page is filled with a [PLaylist] widget.
class Player extends StatefulWidget {
  static var currentIndex = 0;
  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<QuranSurah> surahList = [];

  Future<void> fetchSurahList() async {
    final response = await htp
        .get(Uri.parse('https://www.mp3quran.net/api/v3/suwar?language=ar'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final surahData = data['suwar'];
      setState(() {
        surahList = surahData
            .map<QuranSurah>((json) => QuranSurah.fromJson(json))
            .toList();
        _audioPlayer
            .setAudioSource(ConcatenatingAudioSource(children: [
              for (var i = 1; i <= 114; i++)
                AudioSource.uri(
                  Uri.parse(
                      "https://server11.mp3quran.net/a_jbr/${i.toString().padLeft(3, '0')}.mp3"),
                  tag: AudioMetadata(
                    title: "سورة ${surahList[i - 1].name}",
                    artwork: "assets/ali_jaber.jpg",
                  ),
                ),
            ]))
            .onError((error, stackTrace) => null);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSurahList();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void callback(int currentIndex) {
    setState(() {
      Player.currentIndex = currentIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المصحف كامل بصوت علي جابر'),
        centerTitle: true,
      ),
      body: Center(
        child: SafeArea(
          child: surahList.isEmpty
              ? const Center(
                  child: Center(
                      child: CircularProgressIndicator(
                    color: Colors.deepOrangeAccent,
                    semanticsLabel: 'جاري التحميل...',
                  )),
                )
              : Column(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0.0),
                      ),
                      margin: const EdgeInsets.only(
                          left: 38, right: 38, top: 18, bottom: 18),
                      child: Image.asset(
                        height: MediaQuery.of(context).size.height * 0.3,
                        "assets/ali_jaber.jpg",
                        fit: BoxFit.cover,
                      ),
                    ),
                    Text(
                      surahList.isNotEmpty
                          ? "سورة ${surahList[Player.currentIndex].name}"
                          : '',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    PlayerButtons(_audioPlayer),
                    Expanded(child: Playlist(_audioPlayer, callback)),
                  ],
                ),
        ),
      ),
    );
  }
}

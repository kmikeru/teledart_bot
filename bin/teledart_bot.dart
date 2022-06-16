import 'dart:async';
import 'dart:io' show Platform, exit;
import 'package:meshtastic_proto/MeshInterface.dart';
import 'package:meshtastic_proto/util.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart';
import 'package:meshtastic_proto/TCPInterface.dart';

const String helpMessage = '''Доступные команды:
/nodes - список узлов с SNR и временем последнего принятого пакета
/lastmessage - последнее принятое текстовое сообщение
''';
void main() async {
  Map<String, String> envVars = Platform.environment;
  final token = envVars['BOT_TOKEN'];
  final host = envVars['BOT_HOST'];
  final int timerSec = int.tryParse(envVars['BOT_TIMER'] ?? '') ?? 60;
  final int timerDelay = int.tryParse(envVars['BOT_DELAY'] ?? '') ?? 300;
  print('Timer interval:$timerSec');
  print('Timer delay:$timerDelay');

  if (token == null) {
    print('BOT_TOKEN is not set');
    exit(-1);
  }

  if (host == null) {
    print('BOT_HOST is not set');
    exit(-1);
  }
  var telegram = Telegram(token);

  var iface = TCPInterface(hostname: host);
  iface.enableDebug = true;
  iface.connect();
  runBot(telegram, iface);

  Timer.periodic(Duration(seconds: timerSec), (timer) {
    int diff = DateTime.now().difference(iface.lastPacketReceived).inSeconds;
    print('Timer diff: $diff');
    if (diff > timerDelay) {
      print('No packets recently, reconnecting');
      iface.close();
      Future.delayed(Duration(seconds: 1), () {
        iface.connect();
        print('reconnected');
      });
    }
  });
}

runBot(Telegram telegram, MeshInterface iface) async {
  var event = Event((await telegram.getMe()).username!);
  TeleDart(telegram, event)
    ..start()
    ..onMessage(entityType: 'bot_command', keyword: 'start').listen((message) {
      print(formatDate(DateTime.now()) + ' hello from ${message.from?.first_name}');
      telegram.sendMessage(message.chat.id, helpMessage);
    })
    ..onMessage(entityType: 'bot_command', keyword: 'nodes').listen((message) {
      print(formatDate(DateTime.now()) + ' nodes command from ${message.from?.first_name}');
      if (iface.configComplete) {
        String text = '';
        iface.nodemap.forEach((key, value) {
          String pos = value.user.longName;
          if (value.position.latitudeI != 0 && value.position.longitudeI != 0) {
            String lat = (value.position.latitudeI / 1e7).toStringAsFixed(3);
            String lon = (value.position.longitudeI / 1e7).toStringAsFixed(3);
            pos = '<a href="https://www.openstreetmap.org/?mlat=$lat&mlon=$lon#map=12/$lat/$lon">${value.user.longName}</a>';
          }

          String hops = '';
          if (iface.hoplimit[key] != null) {
            hops = ' hoplimit: ' + iface.hoplimit[key].toString();
          }
          text += pos +
              '\t' +
              formatDate(DateTime.fromMillisecondsSinceEpoch(value.lastHeard * 1000)) +
              '\tSNR:' +
              value.snr.toStringAsPrecision(2) +
              hops +
              '\n';
        });
        telegram.sendMessage(message.chat.id, text, parse_mode: 'HTML');
      } else {
        telegram.sendMessage(message.chat.id, 'config not complete');
      }
    })
    ..onMessage(entityType: 'bot_command', keyword: 'lastmessage').listen((message) {
      print(formatDate(DateTime.now()) + ' lastmessage from ${message.from?.first_name}');
      if (iface.lastMessage.length > 0) {
        telegram.sendMessage(message.chat.id, iface.lastMessage);
      } else {
        telegram.sendMessage(message.chat.id, 'Ещё ничего не принято.');
      }
    })
    ..onMessage().listen((message) {
      telegram.sendMessage(message.chat.id, helpMessage);
    });
}

import 'dart:io' show Platform, exit;
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

  if (token == null) {
    print('BOT_TOKEN is not set');
    exit(-1);
  }

  if (host == null) {
    print('BOT_HOST is not set');
    exit(-1);
  }
  var telegram = Telegram(token);
  var event = Event((await telegram.getMe()).username!);

  var iface = TCPInterface(hostname: host);
  iface.connect();

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
          String hops = '';
          if (iface.hoplimit[key] != null) {
            hops = ' hoplimit: ' + iface.hoplimit[key].toString();
          }
          text += value.user.longName +
              '\t' +
              formatDate(DateTime.fromMillisecondsSinceEpoch(value.lastHeard * 1000)) +
              '\tSNR:' +
              value.snr.toStringAsPrecision(2) +
              hops +
              '\n';
        });
        telegram.sendMessage(message.chat.id, text);
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

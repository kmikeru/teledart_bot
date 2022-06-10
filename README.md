Простейший телеграм-бот для Meshtastic.
Проверено с Meshtastic 1.2.64 и Dart 2.15.
Нужна библиотека для работы с Meshtastic - meshtastic_proto

Доступные команды:
/nodes - список узлов с SNR и временем последнего принятого пакета
/lastmessage - последнее принятое текстовое сообщение

Как запустить:
BOT_TOKEN="..." BOT_HOST="..." dart bin/teledart_bot.dart

Simple telegram bot for Meshtastic.
Tested with Meshtastic 1.2.64 and Dart 2.15.
meshtastic_proto library required.

Known commands:
/nodes
/lastmessage

How to run:
BOT_TOKEN="..." BOT_HOST="..." dart bin/teledart_bot.dart

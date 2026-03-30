// ignore: avoid_web_libraries_in_dart
import 'dart:html' as html;

void showWebNotification(String title, String body) {
  if (html.Notification.permission == 'granted') {
    html.Notification(title, body: body);
  }
}

Future<void> requestWebNotificationPermission() async {
  if (html.Notification.permission == 'default') {
    await html.Notification.requestPermission();
  }
}

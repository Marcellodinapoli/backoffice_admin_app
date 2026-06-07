import 'dart:html';

String? bkLocalStorageGet(String key) => window.localStorage[key];

void bkLocalStorageSet(String key, String value) {
  window.localStorage[key] = value;
}

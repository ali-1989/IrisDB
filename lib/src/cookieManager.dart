import 'dart:html';

class CookieManager {
  /*static CookieManager? _manager;

  static getInstance() {
    if (_manager == null) {
      _manager = CookieManager();
    }

    return _manager;
  }*/

  static void addCookie(String key, String value) {
    /// this command add or replace a cookie to cookies
    document.cookie = '$key="$value"; max-age=2147483647; path=/;';
  }

  static String getCookie(String key) {
    /// when do get cookies, only key/value returned and [max-age, ...] is hidden

    final cookies = document.cookie?? '';
    final pairs = cookies.isNotEmpty ? cookies.split(';') : [];

    for (final item in pairs) {
      final kv = item.split('=');
      final _key = kv[0].trim();

      if (key == _key) {
        if(kv.length > 1){
          return kv[1];
        }

        return '';
      }
    }

    return '';
  }

  static void clear(String key) {
    final cookies = document.cookie?? '';
    final pairs = cookies.isNotEmpty ? cookies.split(';') : [];

    for (final item in pairs) {
      final kv = item.split('=');
      final _key = kv[0].trim();

      if (key == _key) {
        document.cookie = '$key=0; max-age=0;';
        break;
      }
    }
  }

  static void clearAll(){
    final cookies = document.cookie?? '';
    final pairs = cookies.isNotEmpty ? cookies.split(';') : [];

    for (final item in pairs) {
      final kv = item.split('=');
      final key = kv[0].trim();

      document.cookie = '$key=0; max-age=0;';
    }

    // final d = window.location.hostname?.split(".")?? [];
  }
}
import 'dart:io';

import 'package:path/path.dart' as p;

class PathHelper{
  PathHelper._();

  // dir/f.js  >> f.js
  static String getFileName(String path) {
    return p.basename(path);
  }

  // return with {.}  >> .jpg |  >> ''
  static String getDotExtension(String path) {
    return p.extension(path);
  }

  static String getDotExtensionForce(String path, String replace) {
    var f = p.extension(path);

    if(f.isEmpty || !f.contains(RegExp(r'\.'))) {
      f = replace;
    }

    return f;
  }

  static String getNameDotExtensionForce(String path, String dotExtension) {
    var n = p.basenameWithoutExtension(path);
    return n + getDotExtensionForce(path, dotExtension);
  }

  static String getParentDirPath(String path) {
    return p.dirname(resolvePath(path)!);
  }

  static List<String> splitDir(String path) {
    return p.split(path);
  }

  //  /  or  c:\  or  http:://x.com  or  ''
  static String getRootPrefix(String path) {
    return p.rootPrefix(path);
  }

  // file:///path/to/foo'  --> '/path/to/foo
  static String uriToPath(String uri) {
    return p.fromUri(uri);
  }

  static bool isWithin(String parent, String child) {
    return p.isWithin(parent, child);
  }

  //win: K:\Programming\DartProjects\IrisDB\
  //android: /
  static String getCurrentPath() {
    return p.current;
  }

  static String getSeparator() {
    return p.separator;
  }

  static String? resolveEndSeparator(String? path) {
    if(path == null) {
      return null;
    }

    return path.replaceAll(RegExp(r'(\\{2,})$'), r'\').replaceAll(RegExp('(/{2,})\$'), '/');
  }

  static String? resolvePath(String? path) {
    if(path == null) {
      return null;
    }

    try {
      if (Platform.isWindows) {
        path = path.replaceAll(RegExp(r'/'), r'\');
        path = path.replaceAll(RegExp(r'^(\\+)'), ''); //.replaceAll(RegExp('^(/+)'), '');
        path = path.replaceAll(RegExp(r'(?<!:)\\{2,}'), r'\');
      }
      else {
        path = path.replaceAll(RegExp(r'\\'), '/');
        path = path.replaceAll(RegExp('(?<!:)/{2,}'), '/');
      }
    }
    catch (e){ // on Web
      path = path!.replaceAll(RegExp(r'\\'), '/');
      path = path.replaceAll(RegExp('(?<!:)/{2,}'), '/');
    }

    return path;
  }

  /// change multi / or \ to one
  /// remove end / or \
  static String? normalize(String? path) {
    if(path == null) {
      return null;
    }

    var res = p.normalize(path);

    try {
      if (Platform.isWindows && res.startsWith(RegExp(r'\\'))) {
        return res.substring(1);
      }
    }
    catch (e){}

    return res;
  }

  static String? canonicalize(String? path) {
    if(path == null) {
      return null;
    }

    return p.canonicalize(path);
  }

  static String? joinWindows(String path1, String path2) {
    final context = p.Context(style: p.Style.windows);
    return context.join(path1, path2);
  }

  static String? joinMacLinux(String path1, String path2) {
    final context = p.Context(style: p.Style.posix);
    return context.join(path1, path2);
  }

  static String? join(String path1, String path2) {
    final context = p.Context(style: p.Style.platform);
    return context.join(path1, path2);
  }
}
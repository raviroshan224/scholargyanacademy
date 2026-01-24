enum Flavor {
  production,
  dev,
}

class F {
  static late final Flavor appFlavor;

  static String get name => appFlavor.name;

  static String get title {
    switch (appFlavor) {
      case Flavor.production:
        return 'production';
      case Flavor.dev:
        return 'dev';
    }
  }
}

import 'dart:io' show Platform;

// ignore_for_file: non_constant_identifier_names

enum Env { LOCAL, DEV, STAGING, PROD }

class Config {
  static late Map<String, dynamic> _conf;

  static void setEnvironment({Env env = Env.DEV}) {
    switch (env) {
      case Env.LOCAL:
        _conf = _Config.localConf;
        break;
      case Env.DEV:
        _conf = _Config.debugConf;
        break;
      case Env.STAGING:
        _conf = _Config.stagingConf;
        break;
      case Env.PROD:
        _conf = _Config.productionConf;
        break;
      default:
        _conf = _Config.productionConf;
        break;
    }
  }

  static get ENVIRONMENT => _conf[_Config.ENVIRONMENT];
  static get OLP_SERVER => _conf[_Config.OLP_SERVER];
}

class _Config {
  static const ENVIRONMENT = "ENVIRONMENT";
  static const OLP_SERVER = "OLP_SERVER";
  // static const STITCHES_SERVER = "STITCHES_SERVER";

  /// 10.0.2.2 - Special alias to your host loopback interface
  /// (i.e., 127.0.0.1 on your development machine)

  static var localEmulator5000 =
      Platform.isAndroid ? 'http://192.168.1.4:5000' : 'http://localhost:5000';
  static var localEmulator8000 =
      Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://localhost:8000';

  static Map<String, dynamic> localConf = {
    ENVIRONMENT: 'local',
    OLP_SERVER: localEmulator5000,
  };

  static Map<String, dynamic> debugConf = {
    ENVIRONMENT: 'debug',
    OLP_SERVER: 'http://scholargyan.onecloudlab.com/api/v1/',
  };

  static Map<String, dynamic> stagingConf = {
    ENVIRONMENT: 'staging',
    OLP_SERVER: 'http://scholargyan.onecloudlab.com/api/v1/',
  };

  static Map<String, dynamic> productionConf = {
    ENVIRONMENT: 'production',
    // MANPOWER_SERVER: 'https://erp-tunnel.kalodhunga.com/api/v1/',
    OLP_SERVER: "http://scholargyan.onecloudlab.com/api/v1/"
  };
}

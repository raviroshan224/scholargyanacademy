import 'error_string.dart';
import 'enum.dart';
import 'error.dart';

extension DataSourceExtension on DataSource {
  // Get the appropriate ApiFailure object based on the type of DataSource.
  ApiFailure getFailure() {
    switch (this) {
      case DataSource.SUCCESS:
        return ApiFailure(ResponseCode.SUCCESS, ResponseMessage.SUCCESS);
      case DataSource.NO_CONTENT:
        return ApiFailure(ResponseCode.NO_CONTENT, ResponseMessage.NO_CONTENT);
      case DataSource.BAD_REQUEST:
        return ApiFailure(
            ResponseCode.BAD_REQUEST, ResponseMessage.BAD_REQUEST);
      case DataSource.FORBIDDEN:
        return ApiFailure(ResponseCode.FORBIDDEN, ResponseMessage.FORBIDDEN);
      case DataSource.UNAUTORISED:
        return ApiFailure(
            ResponseCode.UNAUTORISED, ResponseMessage.UNAUTORISED);
      case DataSource.NOT_FOUND:
        return ApiFailure(ResponseCode.NOT_FOUND, ResponseMessage.NOT_FOUND);
      case DataSource.INTERNAL_SERVER_ERROR:
        return ApiFailure(ResponseCode.INTERNAL_SERVER_ERROR,
            ResponseMessage.INTERNAL_SERVER_ERROR);
      case DataSource.CONNECT_TIMEOUT:
        return ApiFailure(
            ResponseCode.CONNECT_TIMEOUT, ResponseMessage.CONNECT_TIMEOUT);
      case DataSource.CANCEL:
        return ApiFailure(ResponseCode.CANCEL, ResponseMessage.CANCEL);
      case DataSource.RECIEVE_TIMEOUT:
        return ApiFailure(
            ResponseCode.RECIEVE_TIMEOUT, ResponseMessage.RECIEVE_TIMEOUT);
      case DataSource.SEND_TIMEOUT:
        return ApiFailure(
            ResponseCode.SEND_TIMEOUT, ResponseMessage.SEND_TIMEOUT);
      case DataSource.CACHE_ERROR:
        return ApiFailure(
            ResponseCode.CACHE_ERROR, ResponseMessage.CACHE_ERROR);
      case DataSource.NO_INTERNET_CONNECTION:
        return ApiFailure(ResponseCode.NO_INTERNET_CONNECTION,
            ResponseMessage.NO_INTERNET_CONNECTION);
      case DataSource.DEFAULT:
        return ApiFailure(ResponseCode.DEFAULT, ResponseMessage.DEFAULT);
    }
  }
}

class ResponseCode {
  static const int SUCCESS = 200; // success with data
  static const int NO_CONTENT = 201; // success with no data (no content)
  static const int BAD_REQUEST = 400; // failure, API rejected request
  static const int UNAUTORISED = 401; // failure, user is not authorised
  static const int FORBIDDEN = 403; //  failure, API rejected request
  static const int INTERNAL_SERVER_ERROR = 500; // failure, crash in server side
  static const int NOT_FOUND = 404; // failure, not found

  // local status code
  static const int CONNECT_TIMEOUT = -1;
  static const int CANCEL = -2;
  static const int RECIEVE_TIMEOUT = -3;
  static const int SEND_TIMEOUT = -4;
  static const int CACHE_ERROR = -5;
  static const int NO_INTERNET_CONNECTION = -6;
  static const int DEFAULT = -7;
}

class ResponseMessage {
  static const String SUCCESS = ErrorStrings.success; // success with data
  static const String NO_CONTENT =
      ErrorStrings.success; // success with no data (no content)
  static const String BAD_REQUEST =
      ErrorStrings.strBadRequestError; // failure, API rejected request
  static const String UNAUTORISED =
      ErrorStrings.strUnauthorizedError; // failure, user is not authorised
  static const String FORBIDDEN =
      ErrorStrings.strForbiddenError; //  failure, API rejected request
  static const String INTERNAL_SERVER_ERROR =
      ErrorStrings.strInternalServerError; // failure, crash in server side
  static const String NOT_FOUND =
      ErrorStrings.strNotFoundError; // failure, crash in server side

  // local status code
  static const String CONNECT_TIMEOUT = ErrorStrings.strTimeoutError;
  static const String CANCEL = ErrorStrings.strDefaultError;
  static const String RECIEVE_TIMEOUT = ErrorStrings.strTimeoutError;
  static const String SEND_TIMEOUT = ErrorStrings.strTimeoutError;
  static const String CACHE_ERROR = ErrorStrings.strCacheError;
  static const String NO_INTERNET_CONNECTION = ErrorStrings.strNoInternetError;
  static const String DEFAULT = ErrorStrings.strDefaultError;
}

class ApiInternalStatus {
  static const int SUCCESS = 200;
  static const int FAILURE = 400;
}

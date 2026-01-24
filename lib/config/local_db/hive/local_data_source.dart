
abstract class LocalDataSource {

  /* check first installed*/
  Future<bool> isFirstInstalled();
  /* update first installed value*/
  Future<bool> updateFirstInstalled(bool value);

  // Future<CachedUser?> saveLoggedUserData(CachedUser response);
  // Future<CachedUser?> getLoggedUserData();

  Future<void> clearDb();

  /* clear access token after expired*/
  Future<void> clearAccessToken();
  Future<void> clearRefreshToken();
  Future<String> updateAccessToken(String token);
  Future<String> updateRefreshToken(String token);
  Future<String> getAccessToken();
  Future<String> getRefreshToken();
}

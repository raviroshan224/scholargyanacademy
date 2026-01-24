class ApiEndPoints {
  static const String baseUrl = 'https://scholargyan.onecloudlab.com/api/v1/';

  /// Home Endpoints
  static const String homepage = 'homepage';
  static const String homepageLatestCategory = 'homepage/latest-category';

  /// Authentication Endpoints
  static const String userSignUpUrl = 'auth/email/register';
  static const String userLoginUrl = 'auth/email/login';
  static const String emailConfirmUrl = 'auth/email/confirm';
  static const String emailConfirmNewUrl = 'auth/email/confirm/new';
  static const String sendEmailVerificationOtpUrl =
      'auth/email/send-verification';
  static const String verifyEmailOtpUrl = 'auth/email/verify-otp';
  static const String forgetPassword = 'auth/forgot/password';
  static const String verifyOTP = 'auth/verify/otp';
  static const String resetPassword = 'auth/reset/password';
  static const String refreshTokenUrl = 'auth/refresh';
  static const String logout = 'auth/logout';

  /// Payments Endpoints
  static const String paymentsInitiate = 'payments/initiate';
  static const String paymentsVerify = 'payments/verify';

  /// User Profile Endpoints
  static const String getCurrentUser = 'auth/me';
  static const String updateProfile = 'auth/me';
  static const String deleteAccount = 'auth/me';
  static const String changePassword = 'auth/me/password';
  static const String uploadProfilePicture = 'auth/me/upload-profile-picture';

  /// Additional Auth Endpoints
  static const String loginRegisterOTPVerify = 'auth/email/verify-otp';
  static const String resendOTP = 'auth/email/send-verification';
  static const String oauthLogin = 'auth/oauth/login';
  static const String socialLogin = 'auth/social/login';

  /// Account Endpoints
  static const String userProfile = 'user';
  static const String userRole = 'user/role';
  static const String professionList = 'profession';
  static const String expertiseList = 'experties';
  static const String verifyDocuments = 'user-app/account/verify-document';
  static const String suggestions = 'user-app/account/suggestions';
  static const String articlesAnalytics = 'user-app/account/articles/analytics';
  static const String topArticles = 'user-app/account/articles/top';
  static const String savedArticles = 'user-app/account/articles/saved';
  static const String myArticles = 'user-app/account/articles/my';
  static const String statements = 'user-app/account/statements';
  static const String notifications = 'user-app/account/notifications';
  static const String readAllNotifications =
      'user-app/account/notifications/read-all';
  static const String readNotification = 'user-app/account/notifications/read';
  static const String articleEditSuggestions =
      'user-app/account/articles/edit-suggestions';
  static const String redeemPoints = 'user-app/account/points/redeem';
  static const String subscriberList = 'user-app/account/subscribers';

  /// Explore Endpoints
  static const String users = 'user-app/users';
  static const String articlesByCategory = 'posts/articles/category';

  /// Courses Endpoints (Public)
  static const String courses = 'courses';
  static const String coursesByCategory =
      'courses/category'; // + '/{categoryId}'
  static const String courseBySlug = 'courses/slug'; // + '/{slug}'
  static const String courseById = 'courses'; // + '/{id}'
  static const String courseDetails = 'courses'; // + '/{id}/details'
  static const String courseSave = 'courses'; // + '/{id}/save'
  static const String courseSavedMine = 'courses/saved/my-courses';
  static const String courseIsSaved = 'courses'; // + '/{id}/is-saved'
  static const String subjectsByCourse = 'subjects/course'; // + '/{courseId}'
  static const String subjectById = 'subjects'; // + '/{id}'
  static const String lecturersByCourse = 'lecturers/course'; // + '/{courseId}'
  static const String lecturerById = 'lecturers'; // + '/{id}'
  static const String courseMaterialsByCourse =
      'course-materials/course'; // + '/{courseId}'
  static const String courseMaterialsBySubject =
      'course-materials/subject'; // + '/{subjectId}'
  static const String courseMaterialsByChapter =
      'course-materials/chapter'; // + '/{chapterId}'
  static const String courseMaterialById = 'course-materials'; // + '/{id}'
  static const String courseMaterialDownload =
      'course-materials'; // + '/{id}/download'
  static const String mockTestsByCourse =
      'mock-tests/courses'; // + '/{courseId}'
  static const String mockTestsByCourseWithAttempts =
      'mock-tests/courses'; // + '/{courseId}/with-attempts'

  /// Exams Endpoints
  static const String exams = 'exams';
  static const String examById = 'exams'; // + '/{id}'

  /// Test Sessions Endpoints
  static const String testSessions = 'test-sessions';
  static const String testSessionsStart = 'test-sessions/start';
  static const String testSessionsHistoryMe = 'test-sessions/history/me';

  /// App Info Endpoints
  static const String appInfoAbout = 'app-info/about';
  static const String appInfoTerms = 'app-info/terms';
  static const String appInfoFaqs = 'app-info/faqs';
  // Enrollment Endpoints
  static const String enrollmentsMyCourses = 'enrollments/my-courses';
  static const String enrollmentsById = 'enrollments'; // + '/{id}'
  static const String enrollmentsCourseDetails =
      'enrollments/courses'; // + '/{courseId}/details'
  static const String liveClassesMyClasses = 'live-classes/my-classes';
  static const String lectures = 'lectures'; // + '/{id}'
  static const String lecturesFree = 'lectures/free';
  static const String lecturesBySubject =
      'lectures/subject'; // + '/{subjectId}'
  static const String lectureAdminPreview =
      'lectures/admin'; // + '/{id}/preview'

  /// Message Endpoints
  static const String conversations = 'message-app/conversations';
  static const String groups = 'message-app/groups';

  /// Posts Endpoints
  static const String postPublish = 'article';
  static const String reportArticle = 'article';
  static const String articleList = 'articles';
  static const String myArticleList = 'my-articles';
  static const String savedArticleList = 'bookmarks';
  static const String categoryList = 'article-categories';
  static const String tagList = 'article-tags';
  static const String contentType = 'posts/content-types';
  static const String publisherList = 'posts/publishers';
  static const String comments = 'article';
  static const String editArticle = 'article';
  static const String rating = 'article';
  static const String postSave = 'article';
  static const String deleteComment = 'comment';
  static const String reportComment = 'comment';
  static const String updateComment = 'comment';
  static const String articleById = 'article';
  static const String deleteArticle = 'article';

  /// Category Endpoints
  static const String categoryHierarchy = 'categories/hierarchy';
  static const String favoriteCategories =
      'user-preferences/favorite-categories';

  ///suggestions
  static const String suggestionList = 'article';
  static const String createChatUrl = '/chat';
  static const String getChatListUrl = '/chats';
  static const String sendMsgForChatUrl = '/chat/';
  static const String getMsgForChatUrl = '/chat/';
  static const String getChatLastMsgUrl = '/chat/{chatId}/last-message';
  static const String markMsgReadUrl = '/message/{messageId}/read';
  static const String deleteMsgUrl = '/message/{messageId}';
  static const String editMsgUrl = '/message/{messageId}';
  // api/chat/6888a7deb40fe28399d89b11/messages?page=1&limit=50
}

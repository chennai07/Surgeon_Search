import 'package:get/get.dart';
import 'package:doc/utils/session_manager.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final isLoggedIn = false.obs;
  final userRole = ''.obs;
  final profileId = ''.obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    restoreSession();
  }

  /// 🔄 Restore session from local storage on app start
  Future<void> restoreSession() async {
    isLoading.value = true;
    try {
      final loggedIn = await SessionManager.isLoggedIn();
      if (loggedIn) {
        isLoggedIn.value = true;
        userRole.value = (await SessionManager.getRole()) ?? '';
        profileId.value = (await SessionManager.getProfileId()) ?? (await SessionManager.getUserId()) ?? '';
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ Update state after a successful login
  void loginSuccess({required String role, required String id}) {
    isLoggedIn.value = true;
    userRole.value = role;
    profileId.value = id;
  }

  /// 🚪 Logout and clear states
  Future<void> logout() async {
    await SessionManager.clearAll();
    isLoggedIn.value = false;
    userRole.value = '';
    profileId.value = '';
  }
}

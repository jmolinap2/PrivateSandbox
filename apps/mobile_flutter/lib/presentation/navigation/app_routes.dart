class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const pinSetup = '/pin-setup';
  static const pinUnlock = '/pin-unlock';
  static const gallery = '/gallery';
  static const settings = '/settings';
  static const viewer = '/viewer';

  static String viewerFor(String fileId) => '$viewer/$fileId';
}

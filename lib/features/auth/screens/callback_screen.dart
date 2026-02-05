/// OAuth callback screen - platform-specific implementation
/// Uses web version on web, stub on mobile
export 'callback_screen_stub.dart'
    if (dart.library.html) 'callback_screen_web.dart';

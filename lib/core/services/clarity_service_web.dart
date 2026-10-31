import 'dart:js_interop';

@JS('clarity')
external void _clarity(JSString action, [JSAny? arg1, JSAny? arg2]);

void initClarityPlatform(String projectId) {
  try {
    _clarity('set'.toJS, 'app_platform'.toJS, 'flutter_web'.toJS);
  } catch (_) {}
}

void clarityIdentifyPlatform(String userId, [Map<String, dynamic>? properties]) {
  try {
    _clarity('identify'.toJS, userId.toJS);
    if (properties != null) {
      properties.forEach((k, v) {
        if (v != null) {
          _clarity('set'.toJS, k.toJS, v.toString().toJS);
        }
      });
    }
  } catch (_) {}
}

void claritySetPlatform(String key, String value) {
  try {
    _clarity('set'.toJS, key.toJS, value.toJS);
  } catch (_) {}
}

void clarityEventPlatform(String eventName) {
  try {
    _clarity('event'.toJS, eventName.toJS);
  } catch (_) {}
}

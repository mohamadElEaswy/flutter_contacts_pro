import 'package:flutter/services.dart';
import 'package:jni/jni.dart';

import '../errors/contacts_exception.dart';
import '../models/permission_status.dart';
import 'android_contact_columns.dart';
import 'bindings/contacts_android.g.dart' as android;

/// Permission helpers using JNIGEN checks + thin MethodChannel for requests.
class AndroidPermissions {
  AndroidPermissions({
    MethodChannel? channel,
  }) : _channel = channel ??
            const MethodChannel('flutter_contacts_pro/permissions');

  final MethodChannel _channel;

  android.Context _context() {
    return android.Context.fromReference(Jni.getCachedApplicationContext());
  }

  Future<PermissionStatus> getStatus({
    PermissionMode mode = PermissionMode.read,
  }) async {
    final ctx = _context();
    try {
      final read = android.ContextCompat.checkSelfPermission(
        ctx,
        AndroidContactColumns.permissionRead.toJString(),
      );
      final readOk = read == android.PackageManager.PERMISSION_GRANTED;
      if (!readOk) return PermissionStatus.denied;

      if (mode == PermissionMode.readWrite) {
        final write = android.ContextCompat.checkSelfPermission(
          ctx,
          AndroidContactColumns.permissionWrite.toJString(),
        );
        if (write != android.PackageManager.PERMISSION_GRANTED) {
          return PermissionStatus.denied;
        }
      }
      return PermissionStatus.granted;
    } on JniException catch (e) {
      throw PlatformContactsException('PERMISSION_CHECK', e.toString());
    } finally {
      ctx.release();
    }
  }

  Future<PermissionStatus> request({
    PermissionMode mode = PermissionMode.read,
  }) async {
    final current = await getStatus(mode: mode);
    if (current == PermissionStatus.granted) return current;

    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'requestPermission',
        <String, Object?>{'write': mode == PermissionMode.readWrite},
      );
      final status = result?['status']?.toString();
      return switch (status) {
        'granted' => PermissionStatus.granted,
        'permanentlyDenied' => PermissionStatus.permanentlyDenied,
        'denied' => PermissionStatus.denied,
        _ => PermissionStatus.unknown,
      };
    } on PlatformException catch (e) {
      throw PlatformContactsException(
        e.code,
        e.message ?? 'Permission request failed',
        details: e.details,
      );
    }
  }

  Future<bool> openSettings() async {
    final ctx = _context();
    try {
      final pkg = ctx.getPackageName();
      if (pkg == null) return false;
      final uri = android.Uri.parse('package:${pkg.toDartString()}'.toJString());
      final action =
          android.Settings.ACTION_APPLICATION_DETAILS_SETTINGS ??
              'android.settings.APPLICATION_DETAILS_SETTINGS'.toJString();
      final intent = android.Intent.new$4(action, uri);
      intent.addFlags(android.Intent.FLAG_ACTIVITY_NEW_TASK);
      ctx.startActivity(intent);
      intent.release();
      uri?.release();
      pkg.release();
      return true;
    } on JniException {
      return false;
    } finally {
      ctx.release();
    }
  }
}

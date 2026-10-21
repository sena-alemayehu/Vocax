import '../models/device_contact.dart';
import 'device_service.dart';
import 'fuzzy_match.dart';

/// Looks up people in the phone's contacts.
class ContactService {
  ContactService(this._device);

  final DeviceService _device;

  /// Asks for permission to read contacts. True when allowed.
  Future<bool> ensurePermission() => _device.requestPermissions(['contacts']);

  Future<List<DeviceContact>> all() => _device.listContacts();

  /// The contact whose name is closest to [name], or null.
  DeviceContact? match(String name, List<DeviceContact> contacts) {
    return bestMatch<DeviceContact>(name, contacts, (c) => c.name);
  }

  /// Like [match], but also returns how good the match is.
  Scored<DeviceContact>? matchScored(
    String name,
    List<DeviceContact> contacts,
  ) {
    return bestMatchScored<DeviceContact>(name, contacts, (c) => c.name);
  }
}

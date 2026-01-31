/// Web-safe exports from data package
/// Does not include Isar models which are incompatible with JavaScript
library data_web;

export 'repositories/auth_repository.dart';
export 'repositories/dashboard_repository.dart';
// Note: sync_repository uses Isar, so it's excluded for web
// Note: local_asset and local_event models use Isar, so they're excluded for web

import "package:idb_shim/idb_browser.dart";

/// Brauzerda - haqiqiy IndexedDB.
IdbFactory openIdbFactory() => idbFactoryBrowser;

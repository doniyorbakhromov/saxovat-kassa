import "package:idb_shim/idb_client.dart";
import "package:idb_shim/idb_client_memory.dart";

/// Web bo'lmagan muhit (testlar) uchun - xotiradagi baza.
IdbFactory openIdbFactory() => newIdbFactoryMemory();

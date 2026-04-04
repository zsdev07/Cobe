// ffi_bridge.dart — Dart ↔ C++ low-latency FFI bridge
import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef _InitN = Int32 Function(Pointer<Utf8>, Pointer<Utf8>,
    Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>);
typedef _InitD = int Function(Pointer<Utf8>, Pointer<Utf8>,
    Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>);
typedef _SetKeyN = Void Function(Int32, Pointer<Utf8>);
typedef _SetKeyD = void Function(int, Pointer<Utf8>);
typedef _VoidN   = Void Function();
typedef _VoidD   = void Function();
typedef _Str1N   = Void Function(Pointer<Utf8>);
typedef _Str1D   = void Function(Pointer<Utf8>);
typedef _RequestN = Void Function(
    Pointer<Utf8>, Pointer<Utf8>, Int32,
    Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>,
    Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>);
typedef _RequestD = void Function(
    Pointer<Utf8>, Pointer<Utf8>, int,
    Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>,
    Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>);
typedef _QCtxN = Void Function(Pointer<Utf8>, Int32,
    Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>);
typedef _QCtxD = void Function(Pointer<Utf8>, int,
    Pointer<NativeFunction<Void Function(Pointer<Utf8>)>>);
typedef _ReadN = Void Function(Pointer<Utf8>,
    Pointer<NativeFunction<Void Function(Pointer<Utf8>, Int32)>>);
typedef _ReadD = void Function(Pointer<Utf8>,
    Pointer<NativeFunction<Void Function(Pointer<Utf8>, Int32)>>);
typedef _WriteN = Void Function(Pointer<Utf8>, Pointer<Utf8>, Int32);
typedef _WriteD = void Function(Pointer<Utf8>, Pointer<Utf8>, int);

class CobeFfiBridge {
  CobeFfiBridge._();
  static final instance = CobeFfiBridge._();

  late final DynamicLibrary _lib;
  late final _InitD      _init;
  late final _SetKeyD    _setKey;
  late final _VoidD      _panic, _poke;
  late final _Str1D      _scan;
  late final _RequestD   _request;
  late final _QCtxD      _queryCtx;
  late final _ReadD      _readFile;
  late final _WriteD     _writeFile;

  bool _ready = false;
  bool get isReady => _ready;

  final _statusCtrl = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusCtrl.stream;
  static CobeFfiBridge? _self;

  void load() {
    _lib = Platform.isAndroid
        ? DynamicLibrary.open('libcobe_engine.so')
        : DynamicLibrary.process();

    _init      = _lib.lookupFunction<_InitN,     _InitD>('cobe_init');
    _setKey    = _lib.lookupFunction<_SetKeyN,   _SetKeyD>('cobe_set_key');
    _panic     = _lib.lookupFunction<_VoidN,     _VoidD>('cobe_panic');
    _poke      = _lib.lookupFunction<_VoidN,     _VoidD>('cobe_poke');
    _scan      = _lib.lookupFunction<_Str1N,     _Str1D>('cobe_scan');
    _request   = _lib.lookupFunction<_RequestN,  _RequestD>('cobe_request');
    _queryCtx  = _lib.lookupFunction<_QCtxN,     _QCtxD>('cobe_query_context');
    _readFile  = _lib.lookupFunction<_ReadN,     _ReadD>('cobe_read_file');
    _writeFile = _lib.lookupFunction<_WriteN,    _WriteD>('cobe_write_file');

    _self = this;
    _ready = true;
  }

  static void _onStatus(Pointer<Utf8> msg) =>
      _self?._statusCtrl.add(msg.toDartString());

  bool init(String dbPath, String passphrase) {
    final a = dbPath.toNativeUtf8();
    final b = passphrase.toNativeUtf8();
    final cb = NativeCallable<Void Function(Pointer<Utf8>)>.listener(_onStatus);
    final r = _init(a, b, cb.nativeFunction);
    calloc.free(a); calloc.free(b);
    return r == 1;
  }

  void setProviderKey(int provider, String key) {
    final p = key.toNativeUtf8();
    _setKey(provider, p);
    calloc.free(p);
  }

  void panic() => _panic();
  void poke()  => _poke();

  void scanProject(String root) {
    final p = root.toNativeUtf8();
    _scan(p);
    calloc.free(p);
  }

  Future<String> request({
    required String prompt,
    String system = '',
    int provider = 0,
  }) {
    final c  = Completer<String>();
    final pp = prompt.toNativeUtf8();
    final ps = system.toNativeUtf8();
    late NativeCallable<Void Function(Pointer<Utf8>)> ok, err;
    ok = NativeCallable.listener((Pointer<Utf8> r) {
      c.complete(r.toDartString());
      ok.close(); err.close(); calloc.free(pp); calloc.free(ps);
    });
    err = NativeCallable.listener((Pointer<Utf8> e) {
      c.completeError(e.toDartString());
      ok.close(); err.close(); calloc.free(pp); calloc.free(ps);
    });
    _request(pp, ps, provider, ok.nativeFunction, err.nativeFunction);
    return c.future;
  }

  Future<String> queryContext(String text, {int topK = 5}) {
    final c = Completer<String>();
    final p = text.toNativeUtf8();
    late NativeCallable<Void Function(Pointer<Utf8>)> cb;
    cb = NativeCallable.listener((Pointer<Utf8> j) {
      c.complete(j.toDartString()); cb.close(); calloc.free(p);
    });
    _queryCtx(p, topK, cb.nativeFunction);
    return c.future;
  }

  Future<String> readFile(String path) {
    final c = Completer<String>();
    final p = path.toNativeUtf8();
    late NativeCallable<Void Function(Pointer<Utf8>, Int32)> cb;
    cb = NativeCallable.listener((Pointer<Utf8> d, int len) {
      c.complete(len > 0 ? d.toDartString() : '');
      cb.close(); calloc.free(p);
    });
    _readFile(p, cb.nativeFunction);
    return c.future;
  }

  void writeFile(String path, String content) {
    final pp = path.toNativeUtf8();
    final pd = content.toNativeUtf8();
    _writeFile(pp, pd, content.length);
    calloc.free(pp); calloc.free(pd);
  }
}

final ffi = CobeFfiBridge.instance;

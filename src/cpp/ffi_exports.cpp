// ffi_exports.cpp — C linkage shim → Dart FFI
#include "engine.h"
#include <string>

using namespace cobe;

static cobe_status_cb g_status_cb = nullptr;

#if defined(_WIN32)
  #define COBE_EXPORT extern "C" __declspec(dllexport)
#else
  #define COBE_EXPORT extern "C" __attribute__((visibility("default")))
#endif

COBE_EXPORT int cobe_init(const char* dbPath, const char* passphrase, cobe_status_cb cb) {
    g_status_cb = cb;
    return Engine::instance()->init(
        std::string(dbPath),
        std::string(passphrase),
        [](const std::string& s) {
            if (g_status_cb) g_status_cb(s.c_str());
        }
    ) ? 1 : 0;
}

COBE_EXPORT void cobe_set_key(int provider, const char* key) {
    Engine::instance()->setProviderKey(provider, key);
}

COBE_EXPORT void cobe_panic() {
    Engine::instance()->panicFlush();
}

COBE_EXPORT void cobe_poke() {
    Engine::instance()->pokeActivity();
}

COBE_EXPORT void cobe_scan(const char* root) {
    Engine::instance()->scanProject(root);
}

COBE_EXPORT void cobe_request(
    const char* prompt,
    const char* system,
    int provider,
    cobe_response_cb onSuccess,
    cobe_error_cb onError
) {
    Engine::instance()->enqueueRequest(
        prompt,
        system,
        provider,
        [onSuccess](const char* r) {
            if (onSuccess) onSuccess(r);
        },
        [onError](const char* e) {
            if (onError) onError(e);
        }
    );
}

COBE_EXPORT void cobe_query_context(const char* text, int topK, cobe_context_cb cb) {
    Engine::instance()->queryContext(
        text,
        topK,
        [cb](const char* json) {
            if (cb) cb(json);
        }
    );
}

COBE_EXPORT void cobe_read_file(const char* path, cobe_file_cb cb) {
    Engine::instance()->readFile(
        path,
        [cb](const char* data, int len) {
            if (cb) cb(data, len);
        }
    );
}

COBE_EXPORT void cobe_write_file(const char* path, const char* data, int len) {
    Engine::instance()->writeFile(path, data, len);
}

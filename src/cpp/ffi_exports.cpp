// ffi_exports.cpp — C linkage shim → Dart FFI
#include "engine.h"
#include <string>

using namespace cobe;

static cobe_status_cb g_status_cb = nullptr;

extern "C" {

int cobe_init(const char* dbPath, const char* passphrase, cobe_status_cb cb) {
    g_status_cb = cb;
    return Engine::instance()->init(
        std::string(dbPath),
        std::string(passphrase),
        [](const std::string& s) { if (g_status_cb) g_status_cb(s.c_str()); }
    ) ? 1 : 0;
}

void cobe_set_key(int provider, const char* key) {
    Engine::instance()->setProviderKey(provider, key);
}

void cobe_panic() { Engine::instance()->panicFlush(); }
void cobe_poke()  { Engine::instance()->pokeActivity(); }

void cobe_scan(const char* root) {
    Engine::instance()->scanProject(root);
}

void cobe_request(const char* prompt, const char* system,
                  int provider,
                  cobe_response_cb onSuccess, cobe_error_cb onError) {
    Engine::instance()->enqueueRequest(prompt, system, provider,
        [onSuccess](const char* r) { onSuccess(r); },
        [onError](const char* e)   { onError(e);   });
}

void cobe_query_context(const char* text, int topK, cobe_context_cb cb) {
    Engine::instance()->queryContext(text, topK,
        [cb](const char* json) { cb(json); });
}

void cobe_read_file(const char* path, cobe_file_cb cb) {
    Engine::instance()->readFile(path,
        [cb](const char* data, int len) { cb(data, len); });
}

void cobe_write_file(const char* path, const char* data, int len) {
    Engine::instance()->writeFile(path, data, len);
}

} // extern "C"

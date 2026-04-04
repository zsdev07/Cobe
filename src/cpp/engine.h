#pragma once
// engine.h — Cobe C++20 Engine Public API
#include <functional>
#include <memory>
#include <string>

namespace cobe {

using StatusCallback   = std::function<void(const std::string&)>;
using ResponseCallback = std::function<void(const char*)>;
using ErrorCallback    = std::function<void(const char*)>;
using ContextCallback  = std::function<void(const char*)>;
using FileCallback     = std::function<void(const char*, int)>;

class Engine {
public:
    Engine();
    ~Engine();

    static Engine* instance();

    bool init(const std::string& dbPath,
              const std::string& passphrase,
              StatusCallback cb);

    // Provider index: 0=GroqLarge,1=GroqSmall,2=OpenAI,3=Claude,4=Gemini
    void setProviderKey(int provider, const char* key);

    void panicFlush();
    void pokeActivity();
    void scanProject(const char* root);

    void enqueueRequest(const char* prompt, const char* system,
                        int provider,
                        ResponseCallback onSuccess,
                        ErrorCallback onError);

    void queryContext(const char* text, int topK, ContextCallback cb);
    void readFile(const char* path, FileCallback cb);
    void writeFile(const char* path, const char* data, int len);

private:
    struct Impl;
    std::unique_ptr<Impl> impl;
};

} // namespace cobe

// ── C-linkage exports for Dart FFI ─────────────────────────────────────────
extern "C" {

typedef void (*cobe_status_cb)(const char*);
typedef void (*cobe_response_cb)(const char*);
typedef void (*cobe_error_cb)(const char*);
typedef void (*cobe_context_cb)(const char*);
typedef void (*cobe_file_cb)(const char*, int);

int  cobe_init(const char* dbPath, const char* passphrase, cobe_status_cb cb);
void cobe_set_key(int provider, const char* key);
void cobe_panic();
void cobe_poke();
void cobe_scan(const char* root);
void cobe_request(const char* prompt, const char* system,
                  int provider,
                  cobe_response_cb onSuccess, cobe_error_cb onError);
void cobe_query_context(const char* text, int topK, cobe_context_cb cb);
void cobe_read_file(const char* path, cobe_file_cb cb);
void cobe_write_file(const char* path, const char* data, int len);

} // extern "C"

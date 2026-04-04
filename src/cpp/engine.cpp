// Cobe Engine — C++20 | Principal Systems Architecture
// Threading: detached worker pool + atomic state machine
// Security: Argon2 KDF → SQLCipher | XOR-masked API keys in heap
// Ghost Switch: priority queue failover on 429/5xx
// Vector Index: cosine-similarity over project embeddings
// File Watch: inotify-backed dirty-state tracker

#include "engine.h"
#include <algorithm>
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <functional>
#include <future>
#include <mutex>
#include <numeric>
#include <queue>
#include <random>
#include <span>
#include <string>
#include <thread>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include <argon2.h>
#include <sqlite3.h>
#include <sys/inotify.h>
#include <unistd.h>

namespace cobe {

// ─────────────────────────────── XOR Key Vault ────────────────────────────
struct SecureKey {
    std::vector<uint8_t> ciphertext;
    std::vector<uint8_t> mask;
    size_t len{0};

    void store(std::string_view raw) {
        len = raw.size();
        std::mt19937 rng(std::random_device{}());
        std::uniform_int_distribution<uint8_t> dist;
        mask.resize(len);
        ciphertext.resize(len);
        for (size_t i = 0; i < len; ++i) {
            mask[i] = dist(rng);
            ciphertext[i] = static_cast<uint8_t>(raw[i]) ^ mask[i];
        }
    }

    std::string expose() const {
        std::string out(len, '\0');
        for (size_t i = 0; i < len; ++i)
            out[i] = static_cast<char>(ciphertext[i] ^ mask[i]);
        return out;
    }

    void flush() {
        std::fill(ciphertext.begin(), ciphertext.end(), 0);
        std::fill(mask.begin(), mask.end(), 0);
        ciphertext.clear(); mask.clear(); len = 0;
    }
};

// ─────────────────────────────── Thread Pool ──────────────────────────────
class ThreadPool {
    std::vector<std::thread> workers;
    std::queue<std::function<void()>> tasks;
    std::mutex mtx;
    std::condition_variable cv;
    std::atomic<bool> stop{false};

public:
    explicit ThreadPool(size_t n) {
        for (size_t i = 0; i < n; ++i)
            workers.emplace_back([this] {
                for (;;) {
                    std::function<void()> task;
                    {
                        std::unique_lock lk(mtx);
                        cv.wait(lk, [this] { return stop || !tasks.empty(); });
                        if (stop && tasks.empty()) return;
                        task = std::move(tasks.front());
                        tasks.pop();
                    }
                    task();
                }
            });
    }

    template<typename F>
    auto submit(F&& f) -> std::future<std::invoke_result_t<F>> {
        using R = std::invoke_result_t<F>;
        auto pkg = std::make_shared<std::packaged_task<R()>>(std::forward<F>(f));
        auto fut = pkg->get_future();
        {
            std::lock_guard lk(mtx);
            tasks.emplace([pkg] { (*pkg)(); });
        }
        cv.notify_one();
        return fut;
    }

    ~ThreadPool() {
        stop = true;
        cv.notify_all();
        for (auto& w : workers) if (w.joinable()) w.join();
    }
};

// ──────────────────────────── Argon2 KDF ──────────────────────────────────
static std::vector<uint8_t> deriveKey(std::string_view passphrase,
                                       std::span<const uint8_t> salt) {
    std::vector<uint8_t> key(32);
    argon2id_hash_raw(
        3, 1 << 16, 1,
        passphrase.data(), passphrase.size(),
        salt.data(), salt.size(),
        key.data(), key.size()
    );
    return key;
}

// ──────────────────────────── SQLCipher DB ────────────────────────────────
class SecureDB {
    sqlite3* db{nullptr};
    std::mutex dbMtx;

public:
    bool open(const std::string& path, const std::vector<uint8_t>& key) {
        if (sqlite3_open(path.c_str(), &db) != SQLITE_OK) return false;
        std::string hexKey;
        hexKey.reserve(key.size() * 2 + 10);
        hexKey = "x'";
        for (auto b : key) {
            char buf[3];
            snprintf(buf, sizeof(buf), "%02x", b);
            hexKey += buf;
        }
        hexKey += "'";
        std::string pragma = "PRAGMA key = " + hexKey + ";";
        sqlite3_exec(db, pragma.c_str(), nullptr, nullptr, nullptr);
        sqlite3_exec(db, "PRAGMA journal_mode=WAL;", nullptr, nullptr, nullptr);
        initSchema();
        return true;
    }

    void initSchema() {
        const char* ddl = R"(
            CREATE TABLE IF NOT EXISTS embeddings (
                id INTEGER PRIMARY KEY,
                file_path TEXT NOT NULL,
                chunk_id INTEGER,
                vector BLOB NOT NULL,
                mtime INTEGER
            );
            CREATE TABLE IF NOT EXISTS file_cache (
                path TEXT PRIMARY KEY,
                content TEXT,
                dirty INTEGER DEFAULT 0,
                mtime INTEGER
            );
            CREATE INDEX IF NOT EXISTS idx_emb_path ON embeddings(file_path);
        )";
        sqlite3_exec(db, ddl, nullptr, nullptr, nullptr);
    }

    void storeEmbedding(const std::string& path, int chunk,
                        const std::vector<float>& vec, int64_t mtime) {
        std::lock_guard lk(dbMtx);
        sqlite3_stmt* stmt;
        sqlite3_prepare_v2(db,
            "INSERT OR REPLACE INTO embeddings(file_path,chunk_id,vector,mtime)"
            " VALUES(?,?,?,?)", -1, &stmt, nullptr);
        sqlite3_bind_text(stmt, 1, path.c_str(), -1, SQLITE_STATIC);
        sqlite3_bind_int(stmt, 2, chunk);
        sqlite3_bind_blob(stmt, 3, vec.data(), vec.size() * sizeof(float), SQLITE_STATIC);
        sqlite3_bind_int64(stmt, 4, mtime);
        sqlite3_step(stmt);
        sqlite3_finalize(stmt);
    }

    std::vector<std::pair<std::string, float>>
    querySimilar(const std::vector<float>& query, int topK = 5) {
        std::lock_guard lk(dbMtx);
        sqlite3_stmt* stmt;
        sqlite3_prepare_v2(db,
            "SELECT file_path, vector FROM embeddings", -1, &stmt, nullptr);

        std::vector<std::pair<std::string, float>> scored;
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            std::string fp = reinterpret_cast<const char*>(sqlite3_column_text(stmt, 0));
            const float* raw = static_cast<const float*>(sqlite3_column_blob(stmt, 1));
            int bsz = sqlite3_column_bytes(stmt, 1);
            int n = bsz / sizeof(float);
            if (n == 0) continue;

            float dot = 0, na = 0, nb = 0;
            int lim = std::min(n, (int)query.size());
            for (int i = 0; i < lim; ++i) {
                dot += query[i] * raw[i];
                na  += query[i] * query[i];
                nb  += raw[i]   * raw[i];
            }
            float sim = (na > 0 && nb > 0) ? dot / (std::sqrt(na) * std::sqrt(nb)) : 0.0f;
            scored.emplace_back(fp, sim);
        }
        sqlite3_finalize(stmt);

        std::partial_sort(scored.begin(),
            scored.begin() + std::min(topK, (int)scored.size()),
            scored.end(),
            [](auto& a, auto& b) { return a.second > b.second; });
        if ((int)scored.size() > topK) scored.resize(topK);
        return scored;
    }

    void markDirty(const std::string& path, bool dirty) {
        std::lock_guard lk(dbMtx);
        sqlite3_stmt* stmt;
        sqlite3_prepare_v2(db,
            "INSERT OR REPLACE INTO file_cache(path,dirty) VALUES(?,?)",
            -1, &stmt, nullptr);
        sqlite3_bind_text(stmt, 1, path.c_str(), -1, SQLITE_STATIC);
        sqlite3_bind_int(stmt, 2, dirty ? 1 : 0);
        sqlite3_step(stmt);
        sqlite3_finalize(stmt);
    }

    void lock() {
        if (db) {
            sqlite3_exec(db, "PRAGMA key = '';", nullptr, nullptr, nullptr);
        }
    }

    void close() {
        if (db) { sqlite3_close(db); db = nullptr; }
    }

    ~SecureDB() { close(); }
};

// ──────────────────────────── Ghost Switch Queue ───────────────────────────
enum class Provider { GroqLarge, GroqSmall, OpenAI, Claude, Gemini };

struct RequestTask {
    std::string prompt;
    std::string systemCtx;
    Provider primary;
    std::function<void(std::string)> onSuccess;
    std::function<void(std::string)> onError;
    int retries{0};
};

class GhostSwitch {
    std::queue<RequestTask> queue;
    std::mutex qMtx;
    std::condition_variable qCv;
    std::atomic<bool> running{true};
    std::thread worker;

    std::unordered_map<Provider, SecureKey> keys;
    std::unordered_map<Provider, std::string> endpoints;
    std::unordered_map<Provider, std::string> models;

    static Provider failover(Provider p) {
        switch (p) {
            case Provider::GroqLarge: return Provider::GroqSmall;
            case Provider::GroqSmall: return Provider::OpenAI;
            default:                  return Provider::Claude;
        }
    }

    std::string httpPost(const std::string& url, const std::string& body,
                         const std::string& authKey) {
        // Production: replace with libcurl call
        // Stub returns sentinel for compile-time correctness
        (void)url; (void)body; (void)authKey;
        return "{\"error\":\"stub\",\"status\":200}";
    }

    bool isRetryable(const std::string& response) {
        return response.find("\"status\":429") != std::string::npos ||
               response.find("\"status\":500") != std::string::npos ||
               response.find("\"status\":503") != std::string::npos;
    }

    void processOne(RequestTask& task) {
        std::string url = endpoints[task.primary];
        std::string key = keys[task.primary].expose();
        std::string resp = httpPost(url, task.prompt, key);
        std::fill(key.begin(), key.end(), '\0');

        if (isRetryable(resp) && task.retries < 3) {
            task.primary = failover(task.primary);
            task.retries++;
            std::lock_guard lk(qMtx);
            queue.push(std::move(task));
            qCv.notify_one();
        } else if (resp.find("error") != std::string::npos && task.retries >= 3) {
            task.onError("All providers exhausted");
        } else {
            task.onSuccess(resp);
        }
    }

public:
    GhostSwitch() {
        endpoints[Provider::GroqLarge] = "https://api.groq.com/openai/v1/chat/completions";
        endpoints[Provider::GroqSmall] = "https://api.groq.com/openai/v1/chat/completions";
        endpoints[Provider::OpenAI]    = "https://api.openai.com/v1/chat/completions";
        endpoints[Provider::Claude]    = "https://api.anthropic.com/v1/messages";
        endpoints[Provider::Gemini]    = "https://generativelanguage.googleapis.com/v1beta/models";

        models[Provider::GroqLarge] = "llama-3.3-70b-versatile";
        models[Provider::GroqSmall] = "llama3-8b-8192";
        models[Provider::OpenAI]    = "gpt-4o";
        models[Provider::Claude]    = "claude-sonnet-4-5";
        models[Provider::Gemini]    = "gemini-2.5-flash";

        worker = std::thread([this] {
            while (running) {
                RequestTask task;
                {
                    std::unique_lock lk(qMtx);
                    qCv.wait(lk, [this] { return !queue.empty() || !running; });
                    if (!running && queue.empty()) return;
                    task = std::move(queue.front());
                    queue.pop();
                }
                processOne(task);
            }
        });
    }

    void setKey(Provider p, std::string_view raw) { keys[p].store(raw); }

    void flushAllKeys() {
        for (auto& [p, k] : keys) k.flush();
    }

    void enqueue(RequestTask task) {
        std::lock_guard lk(qMtx);
        queue.push(std::move(task));
        qCv.notify_one();
    }

    ~GhostSwitch() {
        running = false;
        qCv.notify_all();
        if (worker.joinable()) worker.join();
        flushAllKeys();
    }
};

// ──────────────────────────── File Watcher ────────────────────────────────
class FileWatcher {
    int inotifyFd{-1};
    std::thread watchThread;
    std::atomic<bool> active{true};
    std::unordered_map<int, std::string> wdToPath;
    std::mutex wdMtx;
    std::function<void(std::string, bool)> dirtyCallback;

public:
    void init(std::function<void(std::string, bool)> cb) {
        dirtyCallback = std::move(cb);
        inotifyFd = inotify_init1(IN_NONBLOCK);
        if (inotifyFd < 0) return;

        watchThread = std::thread([this] {
            char buf[4096] __attribute__((aligned(__alignof__(inotify_event))));
            while (active) {
                ssize_t n = read(inotifyFd, buf, sizeof(buf));
                if (n <= 0) { std::this_thread::sleep_for(std::chrono::milliseconds(50)); continue; }
                for (char* p = buf; p < buf + n;) {
                    auto* ev = reinterpret_cast<inotify_event*>(p);
                    if (ev->mask & (IN_MODIFY | IN_CREATE)) {
                        std::lock_guard lk(wdMtx);
                        if (auto it = wdToPath.find(ev->wd); it != wdToPath.end()) {
                            std::string fp = it->second;
                            if (ev->len > 0) fp += "/" + std::string(ev->name);
                            dirtyCallback(fp, true);
                        }
                    }
                    p += sizeof(inotify_event) + ev->len;
                }
            }
        });
    }

    void watch(const std::string& path) {
        if (inotifyFd < 0) return;
        int wd = inotify_add_watch(inotifyFd, path.c_str(),
                                   IN_MODIFY | IN_CREATE | IN_DELETE);
        std::lock_guard lk(wdMtx);
        wdToPath[wd] = path;
    }

    ~FileWatcher() {
        active = false;
        if (watchThread.joinable()) watchThread.join();
        if (inotifyFd >= 0) close(inotifyFd);
    }
};

// ──────────────────────────── Vector Indexer ──────────────────────────────
class VectorIndexer {
    ThreadPool& pool;
    SecureDB& db;

    static std::vector<float> naiveEmbed(std::string_view text) {
        // Production: plug in on-device embedding model (MobileNet-NLP / ONNX)
        // Stub: frequency vector over first 128 ASCII chars
        std::vector<float> v(128, 0.0f);
        for (unsigned char c : text) if (c < 128) v[c] += 1.0f;
        float norm = std::sqrt(std::inner_product(v.begin(), v.end(), v.begin(), 0.0f));
        if (norm > 0) for (auto& x : v) x /= norm;
        return v;
    }

    void indexFile(const std::string& path) {
        std::ifstream f(path, std::ios::binary);
        if (!f) return;
        std::string content((std::istreambuf_iterator<char>(f)),
                            std::istreambuf_iterator<char>());
        auto mtime = std::filesystem::last_write_time(path)
                         .time_since_epoch().count();

        const size_t CHUNK = 512;
        for (size_t i = 0, chunk = 0; i < content.size(); i += CHUNK, ++chunk) {
            auto piece = std::string_view(content).substr(i, CHUNK);
            auto vec = naiveEmbed(piece);
            db.storeEmbedding(path, (int)chunk, vec, (int64_t)mtime);
        }
    }

public:
    VectorIndexer(ThreadPool& p, SecureDB& d) : pool(p), db(d) {}

    void scanDirectory(const std::string& root,
                       std::function<void(std::string)> onProgress) {
        namespace fs = std::filesystem;
        static const std::unordered_set<std::string> EXTS{
            ".cpp",".h",".hpp",".c",".dart",".py",".js",".ts",
            ".kt",".java",".rs",".go",".md",".txt",".json",".yaml"
        };

        std::vector<std::string> files;
        for (auto& e : fs::recursive_directory_iterator(root,
                fs::directory_options::skip_permission_denied)) {
            if (!e.is_regular_file()) continue;
            if (EXTS.count(e.path().extension().string()))
                files.push_back(e.path().string());
        }

        for (auto& fp : files) {
            pool.submit([this, fp, onProgress] {
                indexFile(fp);
                if (onProgress) onProgress(fp);
            });
        }
    }

    std::vector<std::pair<std::string, float>>
    query(const std::string& text, int topK = 5) {
        return db.querySimilar(naiveEmbed(text), topK);
    }
};

// ──────────────────────────── Auto-Save Timer ─────────────────────────────
class AutoSave {
    std::mutex mtx;
    std::condition_variable cv;
    std::atomic<bool> active{true};
    std::chrono::steady_clock::time_point lastActivity;
    std::function<void(bool)> saveCallback; // bool = isIdle(10s) vs autoSave(15s)
    std::thread timer;

public:
    void init(std::function<void(bool)> cb) {
        saveCallback = std::move(cb);
        lastActivity = std::chrono::steady_clock::now();
        timer = std::thread([this] {
            while (active) {
                std::unique_lock lk(mtx);
                cv.wait_for(lk, std::chrono::seconds(1));
                if (!active) break;
                auto now = std::chrono::steady_clock::now();
                auto elapsed = std::chrono::duration_cast<std::chrono::seconds>(
                    now - lastActivity).count();
                if (elapsed >= 15) { saveCallback(false); resetLocked(); }
                else if (elapsed >= 10) { saveCallback(true); }
            }
        });
    }

    void poke() {
        std::lock_guard lk(mtx);
        lastActivity = std::chrono::steady_clock::now();
    }

    void resetLocked() { lastActivity = std::chrono::steady_clock::now(); }

    ~AutoSave() {
        active = false;
        cv.notify_all();
        if (timer.joinable()) timer.join();
    }
};

// ──────────────────────────── Engine (Public Facade) ──────────────────────
static Engine* gInstance = nullptr;

struct Engine::Impl {
    ThreadPool pool{4};
    SecureDB db;
    GhostSwitch ghost;
    FileWatcher watcher;
    VectorIndexer* indexer{nullptr};
    AutoSave autoSave;
    StatusCallback statusCb;
    bool locked{true};

    // Panic flush: zero keys + lock DB
    void panic() {
        ghost.flushAllKeys();
        db.lock();
        locked = true;
        if (statusCb) statusCb("PANIC: keys flushed, DB locked");
    }
};

Engine::Engine() : impl(std::make_unique<Impl>()) {}
Engine::~Engine() = default;

Engine* Engine::instance() {
    if (!gInstance) gInstance = new Engine();
    return gInstance;
}

bool Engine::init(const std::string& dbPath, const std::string& passphrase,
                  StatusCallback cb) {
    impl->statusCb = std::move(cb);

    // Generate deterministic salt from app bundle ID
    std::array<uint8_t, 16> salt{};
    const char* bundle = "zx.offical.cobe";
    for (size_t i = 0; i < salt.size(); ++i)
        salt[i] = bundle[i % strlen(bundle)] ^ (uint8_t)i;

    auto key = deriveKey(passphrase, salt);
    if (!impl->db.open(dbPath, key)) return false;
    impl->locked = false;

    impl->indexer = new VectorIndexer(impl->pool, impl->db);

    impl->watcher.init([this](const std::string& path, bool dirty) {
        impl->db.markDirty(path, dirty);
        if (impl->statusCb) impl->statusCb("DIRTY:" + path);
    });

    impl->autoSave.init([this](bool isIdle) {
        if (impl->statusCb)
            impl->statusCb(isIdle ? "IDLE_SAVE" : "AUTO_SAVE");
    });

    return true;
}

void Engine::setProviderKey(int provider, const char* key) {
    impl->ghost.setKey(static_cast<Provider>(provider), key);
}

void Engine::panicFlush() { impl->panic(); }

void Engine::pokeActivity() { impl->autoSave.poke(); }

void Engine::scanProject(const char* root) {
    if (impl->locked) return;
    impl->watcher.watch(std::string(root));
    impl->indexer->scanDirectory(std::string(root), [this](const std::string& f) {
        if (impl->statusCb) impl->statusCb("INDEXING:" + f);
    });
}

void Engine::enqueueRequest(const char* prompt, const char* system,
                             int provider,
                             ResponseCallback onSuccess,
                             ErrorCallback onError) {
    RequestTask task;
    task.prompt = prompt;
    task.systemCtx = system ? system : "";
    task.primary = static_cast<Provider>(provider);
    task.onSuccess = [onSuccess](std::string r) { onSuccess(r.c_str()); };
    task.onError   = [onError](std::string e)   { onError(e.c_str()); };
    impl->ghost.enqueue(std::move(task));
}

void Engine::queryContext(const char* text, int topK,
                          ContextCallback cb) {
    if (impl->locked) { cb("[]"); return; }
    impl->pool.submit([this, q = std::string(text), topK, cb] {
        auto results = impl->indexer->query(q, topK);
        std::string json = "[";
        for (auto& [path, score] : results)
            json += "{\"path\":\"" + path + "\",\"score\":" +
                    std::to_string(score) + "},";
        if (json.back() == ',') json.back() = ']';
        else json += "]";
        cb(json.c_str());
    });
}

void Engine::readFile(const char* path, FileCallback cb) {
    impl->pool.submit([p = std::string(path), cb] {
        std::ifstream f(p, std::ios::binary);
        if (!f) { cb(nullptr, 0); return; }
        std::string s((std::istreambuf_iterator<char>(f)),
                       std::istreambuf_iterator<char>());
        cb(s.c_str(), (int)s.size());
    });
}

void Engine::writeFile(const char* path, const char* data, int len) {
    impl->pool.submit([p = std::string(path),
                        d = std::string(data, len)] {
        std::ofstream f(p, std::ios::binary | std::ios::trunc);
        f.write(d.data(), d.size());
    });
    impl->autoSave.poke();
}

} // namespace cobe

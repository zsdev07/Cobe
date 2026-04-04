cmake_minimum_required(VERSION 3.22.1)
project(cobe_engine VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# ── Optimization flags ─────────────────────────────────────────────────────
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    add_compile_options(-O3 -flto -fvisibility=hidden -fvisibility-inlines-hidden)
    add_link_options(-flto)
endif()

# ── Paths ──────────────────────────────────────────────────────────────────
# CMAKE_SOURCE_DIR here is already: .../src/cpp
set(THIRD_PARTY_DIR "${CMAKE_SOURCE_DIR}/third_party")

# ── SQLCipher (pre-built .a for Android ABI) ───────────────────────────────
add_library(sqlcipher STATIC IMPORTED)
set_target_properties(sqlcipher PROPERTIES
    IMPORTED_LOCATION "${THIRD_PARTY_DIR}/sqlcipher/${ANDROID_ABI}/libsqlcipher.a"
)
target_include_directories(sqlcipher INTERFACE
    "${THIRD_PARTY_DIR}/sqlcipher/include"
)

# ── OpenSSL libcrypto (required by current SQLCipher static builds) ────────
add_library(crypto STATIC IMPORTED)
set_target_properties(crypto PROPERTIES
    IMPORTED_LOCATION "${THIRD_PARTY_DIR}/openssl/${ANDROID_ABI}/libcrypto.a"
)

# ── Argon2 ─────────────────────────────────────────────────────────────────
add_library(argon2 STATIC IMPORTED)
set_target_properties(argon2 PROPERTIES
    IMPORTED_LOCATION "${THIRD_PARTY_DIR}/argon2/${ANDROID_ABI}/libargon2.a"
)
target_include_directories(argon2 INTERFACE
    "${THIRD_PARTY_DIR}/argon2/include"
)

# ── fmt (header-only) ──────────────────────────────────────────────────────
add_library(fmt INTERFACE)
target_include_directories(fmt INTERFACE
    "${THIRD_PARTY_DIR}/fmt/include"
)

# ── Engine shared library ──────────────────────────────────────────────────
add_library(cobe_engine SHARED
    engine.cpp
    ffi_exports.cpp
)

target_include_directories(cobe_engine PRIVATE
    "${CMAKE_SOURCE_DIR}"
)

target_compile_definitions(cobe_engine PRIVATE
    SQLITE_HAS_CODEC
    SQLITE_TEMP_STORE=2
)

target_link_libraries(cobe_engine PRIVATE
    sqlcipher
    crypto
    argon2
    fmt
    android
    log
)

set_target_properties(cobe_engine PROPERTIES
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON
)

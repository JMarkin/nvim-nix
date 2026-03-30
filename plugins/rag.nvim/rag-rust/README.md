# RAG for Neovim - Rust Implementation

A Rust-based implementation of the RAG (Retrieval-Augmented Generation) plugin for Neovim, rewritten from Lua to leverage Rust's performance and type safety.

## Features

- ✅ Rust-powered backend for better performance
- ✅ SQLite-based vector database for efficient storage
- ✅ C API for seamless Neovim integration
- ✅ Embedding caching for faster searches
- ✅ Project-based file management
- ✅ Automatic file indexing on write

## Architecture

The implementation follows the structure of `juan-logs.nvim`:

```
rag-rust/
├── Cargo.toml
├── build.lua
├── src/
│   ├── lib.rs          - Main library entry point
│   ├── models.rs       - Data structures
│   ├── database.rs     - SQLite operations
│   ├── embedding.rs    - Embedding client
│   ├── cache.rs        - Caching layer
│   ├── config.rs       - Configuration management
│   ├── index.rs        - Core indexing logic
│   └── c_api.rs        - C API for Neovim
└── lib/
    └── librag.so       - Compiled shared library
```

## Components

### 1. Database Layer (`database.rs`)
- SQLite-based storage with blob embeddings
- Cosine similarity for vector search
- Efficient chunk storage and retrieval

### 2. Embedding Client (`embedding.rs`)
- HTTP client for API-based embeddings
- Placeholder implementation for development

### 3. Caching Layer (`cache.rs`)
- JSON-based embedding cache
- Atomic file updates

### 4. C API (`c_api.rs`)
- `rag_engine_new()` - Initialize engine
- `rag_engine_index_file()` - Index a single file
- `rag_engine_reindex()` - Full reindex
- `rag_engine_search()` - Search for chunks
- `rag_engine_update_on_write()` - Update on file save
- `rag_engine_free()` - Cleanup

## Building

### Using the build script
```bash
lua build.lua
```

This will:
1. Download pre-compiled binaries if available
2. Fall back to `cargo build` if download fails

### Manual build
```bash
cd rag-rust
cargo build
cp target/debug/librag.so ../lib/
```

## Configuration

Configure via Neovim setup:

```lua
require("rag").setup({
  base_url = "http://localhost:8012",
  api_key = "",
  org_id = "",
  embedding_model = "embeddings-code",
  db_path = vim.fn.stdpath("data") .. "/rag_index.db",
  cache_path = vim.fn.stdpath("data") .. "/rag_emb_cache.json",
  max_file_size = 10 * 1024 * 1024,
  chunk_size = 250,
  overlap = 50,
  workers = 4,
  repo_detection_depth = 2,
})
```

## Usage

### Commands
- `:RagIndex` - Index all files in project
- `:RagReindex` - Full reindex
- `:RagSearch <query>` - Search for code

### Automatic Updates
- Files are automatically indexed on write
- Project detection works with git repositories

## Comparison with Lua Implementation

### Performance Advantages
- ✅ Rust provides better performance for CPU-intensive operations
- ✅ Type safety reduces runtime errors
- ✅ Better memory management
- ✅ Faster indexing for large codebases

### Code Organization
- ✅ Modular architecture
- ✅ Separation of concerns (database, embedding, cache)
- ✅ Clear C API boundary

### Limitations
- ⚠️ HTTP client currently has placeholder implementation
- ⚠️ Requires pre-compiled binaries or manual compilation
- ⚠️ More complex build process

## Development

### Adding HTTP Support
To enable real HTTP requests, modify `embedding.rs`:

```rust
use reqwest::blocking::Client;

pub fn embed(&self, text: &str) -> Result<Option<Vec<f32>>, anyhow::Error> {
    let client = Client::new();
    
    let response = client
        .post(&format!("{}/v1/embeddings", self.config.base_url))
        .header("Authorization", format!("Bearer {}", self.config.api_key))
        .header("Content-Type", "application/json")
        .json(&EmbeddingRequest {
            model: self.config.embedding_model.clone(),
            input: text.to_string(),
            encoding_format: "float".to_string(),
        })
        .send()
        .map_err(|e| anyhow::anyhow!("HTTP request failed: {}", e))?;
    
    if !response.status().is_success() {
        anyhow::bail!("HTTP request failed with status: {}", response.status());
    }
    
    let embedding_response: EmbeddingResponse = response.json()
        .map_err(|e| anyhow::anyhow!("Failed to parse response: {}", e))?;
    
    if embedding_response.data.is_empty() {
        return Ok(None);
    }
    
    Ok(Some(embedding_response.data[0].embedding.clone()))
}
```

## License

Same as original RAG plugin implementation.
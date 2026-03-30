use std::env;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub base_url: String,
    pub api_key: String,
    pub org_id: String,
    pub embedding_model: String,
    pub db_path: String,
    pub cache_path: String,
    pub max_file_size: usize,
    pub chunk_size: usize,
    pub overlap: usize,
    pub workers: usize,
    pub repo_detection_depth: usize,
}

impl Default for Config {
    fn default() -> Self {
        let path = env::current_dir().expect("Failed to get current directory");
        Config {
            base_url: "http://localhost:8012".to_string(),
            api_key: String::new(),
            org_id: String::new(),
            embedding_model: "embeddings-code".to_string(),
            db_path: ".rag/rag_index.db",
            cache_path: std::env::var("XDG_CACHE_HOME")
                .unwrap_or_else(|_| std::env::var("HOME").unwrap_or_else(|_| ".".to_string()))
                + "/rag_emb_cache.json",
            max_file_size: 10 * 1024 * 1024,
            chunk_size: 400,
            overlap: 50,
            workers: 2,
            repo_detection_depth: 2,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Embedding {
    pub embedding: Vec<f32>,
    pub model: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Chunk {
    pub id: i64,
    pub file_path: String,
    pub chunk_text: String,
    pub line_no: i32,
    pub project_id: String,
    pub embedding: Vec<f32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchResult {
    pub file_path: String,
    pub id: i64,
    pub chunk_text: String,
    pub line_no: i32,
    pub distance: f64,
}

#[derive(Debug, Clone)]
pub struct ProjectInfo {
    pub path: String,
    pub root: String,
}

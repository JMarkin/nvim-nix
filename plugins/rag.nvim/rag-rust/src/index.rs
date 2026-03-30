use crate::cache::CacheManager;
use crate::config::ConfigManager;
use crate::database::Database;
use crate::embedding::EmbeddingClient;
use crate::models::{Chunk, Config, SearchResult};
use std::collections::HashMap;
use std::path::Path;
use std::sync::Arc;
use sha2::{Digest, Sha256};

pub struct RagEngine {
    config_manager: ConfigManager,
    database: Database,
    cache: CacheManager,
    embedding_client: EmbeddingClient,
}

impl RagEngine {
    pub fn new(config_json: Option<serde_json::Value>) -> Result<Self, anyhow::Error> {
        let mut config_manager = ConfigManager::new();
        config_manager.setup(config_json)?;
        
        let config = config_manager.get_config().clone();
        
        let database = Database::new(&config)?;
        let cache = CacheManager::new(&config)?;
        let embedding_client = EmbeddingClient::new(Arc::new(config.clone()));
        
        Ok(RagEngine {
            config_manager,
            database,
            cache,
            embedding_client,
        })
    }

    pub fn config(&self) -> &Config {
        self.config_manager.get_config()
    }

    pub fn index_file(&self, file_path: &str, project_id: Option<String>) -> Result<(), anyhow::Error> {
        let config = self.config();
        
        let path = Path::new(file_path);
        let metadata = path.metadata()?;
        
        if metadata.len() > config.max_file_size as u64 {
            eprintln!("RAG: skipping {} (size > max)", file_path);
            return Ok(());
        }
        
        let content = std::fs::read_to_string(file_path)?;
        
        let chunks = self.chunk_text(&content, file_path)?;
        
        for (id, chunk) in chunks.iter().enumerate() {
            let embedding = self.get_embedding(chunk)?;
            if let Some(embedding) = embedding {
                let chunk = Chunk {
                    id: 0,
                    file_path: file_path.to_string(),
                    chunk_text: chunk.clone(),
                    line_no: (id * config.chunk_size - config.overlap + 1) as i32,
                    project_id: project_id.clone().unwrap_or_default(),
                    embedding,
                };
                
                self.database.store_chunk(&chunk)?;
            }
        }
        
        println!("RAG: indexed [{}] {}", project_id.as_deref().unwrap_or("none"), file_path);
        
        Ok(())
    }

    pub fn index_project(&self, project_root: &str, recursive: bool) -> Result<(), anyhow::Error> {
        let config = self.config();
        
        let pattern = if recursive {
            "**/*.rs"
        } else {
            "*.rs"
        };
        
        let files = self.find_files(project_root, pattern)?;
        
        let mut total = files.len();
        let mut processed = 0;
        
        let project_id = Some(project_root.to_string());
        
        for file_path in files {
            self.index_file(&file_path, project_id.clone())?;
            
            processed += 1;
            let pct = (processed as f64 / total as f64 * 100.0) as u32;
            println!("RAG: {}/{} files processed ({}%)", processed, total, pct);
        }
        
        Ok(())
    }

    pub fn reindex(&self) -> Result<(), anyhow::Error> {
        self.database.delete_all_chunks()?;
        self.index_project(&self.config().db_path, false)
    }

    pub fn search(&self, query: &str, limit: usize) -> Result<Vec<SearchResult>, anyhow::Error> {
        let config = self.config();
        
        let query_embedding = self.get_embedding(query)?;
        
        if query_embedding.is_none() {
            return Ok(Vec::new());
        }
        
        let query_embedding = query_embedding.unwrap();
        
        let results = self.database.search_chunks(&query_embedding, limit)?;
        
        println!("RAG: {} results shown", results.len());
        
        Ok(results)
    }

    pub fn update_on_write(&self, file_path: &str) -> Result<(), anyhow::Error> {
        let project_id = self.detect_project_id(file_path)?;
        
        self.index_file(file_path, project_id)?;
        
        Ok(())
    }

    fn chunk_text(&self, text: &str, file_name: &str) -> Result<Vec<String>, anyhow::Error> {
        let config = self.config();
        
        let mut chunks = Vec::new();
        let mut start = 0;
        let chunk_size = config.chunk_size;
        let overlap = config.overlap;
        
        while start < text.len() {
            let stop = std::cmp::min(start + chunk_size, text.len());
            let chunk = text[start..stop].to_string();
            chunks.push(chunk);
            
            start = stop - overlap;
        }
        
        Ok(chunks)
    }

    fn get_embedding(&self, text: &str) -> Result<Option<Vec<f32>>, anyhow::Error> {
        let hash = format!("{:x}", Sha256::digest(text));
        
        if let Some(cached) = self.cache.get(&hash) {
            return Ok(Some(cached));
        }
        
        let embedding = self.embedding_client.embed(text)?;
        
        if let Some(embedding) = embedding {
            self.cache.set(&hash, embedding.clone())?;
            Ok(Some(embedding))
        } else {
            Ok(None)
        }
    }

    fn find_files(&self, path: &str, pattern: &str) -> Result<Vec<String>, anyhow::Error> {
        let output = std::process::Command::new("rg")
            .args(&["--files", "-g", pattern, path])
            .output()?;
        
        if !output.status.success() {
            eprintln!("RAG: rg failed - {:?}", output.stderr);
            return Ok(Vec::new());
        }
        
        let stdout = String::from_utf8_lossy(&output.stdout);
        let files: Vec<String> = stdout
            .lines()
            .filter(|line| !line.is_empty())
            .map(|line| line.to_string())
            .collect();
        
        Ok(files)
    }

    fn detect_project_id(&self, file_path: &str) -> Result<Option<String>, anyhow::Error> {
        let config = self.config();
        let mut dir = Path::new(file_path).to_path_buf();
        
        for _ in 0..config.repo_detection_depth {
            let git_path = dir.join(".git");
            if git_path.exists() {
                let mut root = dir.clone();
                loop {
                    let parent = root.parent().unwrap_or(&dir);
                    if parent == &root {
                        break;
                    }
                    if parent.join(".git").exists() {
                        root = parent.to_path_buf();
                    } else {
                        break;
                    }
                }
                return Ok(Some(root.to_string_lossy().to_string()));
            }
            
            if let Some(new_dir) = dir.parent() {
                if new_dir == dir {
                    break;
                }
                dir = new_dir.to_path_buf();
            } else {
                break;
            }
        }
        
        Ok(None)
    }

    pub fn close(self) {}
}
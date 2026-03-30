use crate::models::Config;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::sync::{Arc, Mutex};

#[derive(Debug, Serialize, Deserialize)]
struct CacheEntry {
    embedding: Vec<f32>,
}

pub struct CacheManager {
    cache: Arc<Mutex<HashMap<String, Vec<f32>>>>,
    path: String,
}

impl CacheManager {
    pub fn new(config: &Config) -> Result<Self, anyhow::Error> {
        let path = config.cache_path.clone();
        
        let cache = Arc::new(Mutex::new(HashMap::new()));
        
        if let Ok(data) = fs::read_to_string(&path) {
            let entries: HashMap<String, CacheEntry> = serde_json::from_str(&data)
                .unwrap_or_default();
            
            for (key, entry) in entries {
                let embedding: Vec<f32> = serde_json::from_value(serde_json::to_value(&entry.embedding)?)
                    .unwrap_or_default();
                cache.lock().unwrap().insert(key, embedding);
            }
        }
        
        Ok(CacheManager { cache, path })
    }

    pub fn get(&self, hash: &str) -> Option<Vec<f32>> {
        self.cache.lock().unwrap().get(hash).cloned()
    }

    pub fn set(&self, hash: &str, embedding: Vec<f32>) -> Result<(), anyhow::Error> {
        self.cache.lock().unwrap().insert(hash.to_string(), embedding.clone());
        
        self.save()?;
        
        Ok(())
    }

    fn save(&self) -> Result<(), anyhow::Error> {
        let entries = self.cache.lock().unwrap();
        
        let cache_data: HashMap<String, CacheEntry> = entries
            .iter()
            .map(|(key, embedding)| {
                let entry = CacheEntry {
                    embedding: embedding.clone(),
                };
                (key.clone(), entry)
            })
            .collect();
        
        let json_str = serde_json::to_string_pretty(&cache_data)?;
        
        let temp_path = format!("{}.tmp", self.path);
        fs::write(&temp_path, &json_str)?;
        
        fs::rename(&temp_path, &self.path)?;
        
        Ok(())
    }

    pub fn clear(&self) {
        self.cache.lock().unwrap().clear();
    }
}
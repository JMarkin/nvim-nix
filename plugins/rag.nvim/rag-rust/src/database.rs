use crate::models::{Chunk, Config, SearchResult};
use rusqlite::{ffi::sqlite3_auto_extension,Connection};
use sqlite_vec::sqlite3_vec_init;

pub struct Database {
    conn: Connection,
    config: Config,
}

impl Database {
    pub fn new(config: &Config) -> Result<Self, anyhow::Error> {
        unsafe {
            sqlite3_auto_extension(Some(std::mem::transmute(sqlite3_vec_init as *const ())));
        }
        
        let conn = Connection::open(&config.db_path)?;
        
        let db = Database {
            conn,
            config: config.clone(),
        };
        
        db.migrate()?;
        Ok(db)
    }

    fn migrate(&self) -> Result<(), anyhow::Error> {
        self.conn.execute(
            "create virtual table if not exists chunks (
                id integer primary key autoincrement,
                project_id int partition key,

                file_path text,
                chunk_text text,
                line_no int,
                embedding float[512]
            )",
            [],
        )?;
        
        Ok(())
    }

    pub fn store_chunk(&self, chunk: &Chunk) -> Result<(), anyhow::Error> {
        let embedding_bytes = serde_json::to_vec(&chunk.embedding)
            .map_err(|e| anyhow::anyhow!("Failed to serialize embedding: {}", e))?;
        
        self.conn.execute(
            "INSERT INTO chunks (file_path, chunk_text, line_no, project_id, embedding)
             VALUES (?1, ?2, ?3, ?4, ?5)",
            (
                &chunk.file_path,
                &chunk.chunk_text,
                chunk.line_no,
                &chunk.project_id,
                embedding_bytes,
            ),
        )?;
        
        Ok(())
    }

    pub fn delete_all_chunks(&self) -> Result<(), anyhow::Error> {
        self.conn.execute("DELETE FROM chunks", [])?;
        Ok(())
    }

    pub fn search_chunks(
        &self,
        query_embedding: &[f32],
        limit: usize,
    ) -> Result<Vec<SearchResult>, anyhow::Error> {
        let mut stmt = self.conn.prepare(
            "SELECT file_path, id, chunk_text, line_no, embedding
             FROM chunks
             ORDER BY embedding <-> ?
             LIMIT ?"
        )?;

        let mut results = Vec::new();
        
        let embedding_bytes = serde_json::to_vec(query_embedding)
            .map_err(|e| anyhow::anyhow!("Failed to serialize embedding: {}", e))?;
        
        let mut rows = stmt.query((embedding_bytes.as_slice(), limit))?;
        
        while let Some(row) = rows.next()? {
            let file_path: String = row.get(0)?;
            let id: i64 = row.get(1)?;
            let chunk_text: String = row.get(2)?;
            let line_no: i32 = row.get(3)?;
            let embedding_bytes: Vec<u8> = row.get(4)?;
            let embedding: Vec<f32> = serde_json::from_slice(&embedding_bytes)
                .map_err(|e| anyhow::anyhow!("Failed to deserialize embedding: {}", e))?;
            
            let distance = self.compute_distance(&embedding, query_embedding);
            
            results.push(SearchResult {
                file_path,
                id,
                chunk_text,
                line_no,
                distance,
            });
        }
        
        Ok(results)
    }

    fn compute_distance(&self, a: &[f32], b: &[f32]) -> f64 {
        if a.len() != b.len() {
            return f64::MAX;
        }
        
        let mut dot_product = 0.0;
        let mut norm_a = 0.0;
        let mut norm_b = 0.0;
        
        for (&ai, &bi) in a.iter().zip(b.iter()) {
            dot_product += ai * bi;
            norm_a += ai * ai;
            norm_b += bi * bi;
        }
        
        if norm_a == 0.0 || norm_b == 0.0 {
            return f64::MAX;
        }
        
        (dot_product as f64) / ((norm_a as f64 * norm_b as f64).sqrt())
    }

    pub fn get_chunks_by_file(&self, file_path: &str) -> Result<Vec<Chunk>, anyhow::Error> {
        let mut stmt = self.conn.prepare(
            "SELECT id, file_path, chunk_text, line_no, project_id, embedding
             FROM chunks
             WHERE file_path = ?
             ORDER BY line_no"
        )?;

        let mut chunks = Vec::new();
        
        let mut rows = stmt.query((file_path,))?;
        
        while let Some(row) = rows.next()? {
            let id: i64 = row.get(0)?;
            let file_path: String = row.get(1)?;
            let chunk_text: String = row.get(2)?;
            let line_no: i32 = row.get(3)?;
            let project_id: Option<String> = row.get(4)?;
            let embedding_bytes: Vec<u8> = row.get(5)?;
            let embedding: Vec<f32> = serde_json::from_slice(&embedding_bytes)
                .map_err(|e| anyhow::anyhow!("Failed to deserialize embedding: {}", e))?;
            
            chunks.push(Chunk {
                id,
                file_path,
                chunk_text,
                line_no,
                project_id: project_id.unwrap_or_default(),
                embedding,
            });
        }
        
        Ok(chunks)
    }

    pub fn close(self) {}
}

use crate::models::Config;
use serde::{Serialize, Deserialize};
use ureq::http::Response;
use std::sync::Arc;

pub struct EmbeddingClient {
    config: Arc<Config>,
}

#[derive(Serialize)]
struct EmbeddingRequest<'a> {
    model: String,
    input: &'a str,
}

/// Main response struct from OpenAI embeddings API
#[derive(Debug, Deserialize, Serialize)]
pub struct EmbeddingResponse {
    pub object: String,
    pub data: Vec<EmbeddingItem>,
    pub usage: Usage,
    pub model: String,
}

/// Individual embedding item
#[derive(Debug, Deserialize, Serialize)]
pub struct EmbeddingItem {
    pub object: String,
    pub index: usize,
    pub embedding: Vec<f32>,
}

/// Token usage information
#[derive(Debug, Deserialize, Serialize)]
pub struct Usage {
    pub prompt_tokens: usize,
    pub total_tokens: usize,
}

impl EmbeddingClient {
    pub fn new(config: Arc<Config>) -> Self {
        EmbeddingClient { config }
    }

    pub fn embed(&self, text: &str) -> Result<Option<Vec<f32>>, anyhow::Error> {
        let url = format!("{}/v1/embeddings", self.config.base_url);
        let body =  EmbeddingRequest{
            model: self.config.embedding_model,
            input: text,
        };

        let response: Response<> = ureq::post(url)
            .header("Authorization", format!("Bearer {}", self.config.api_key))
            .header("Content-Type", "application/json")
            .send_json(&body)?;


        let status = response.;
        if !status.is_success() {
            let error_text = response.text().unwrap_or_else(|_| "Unknown error".to_string());
            return Err(anyhow::anyhow!("API request failed: {}", error_text));
        }

        let api_response: serde_json::Value = response.json()?;
        let embedding_data = api_response
            .get("data")
            .and_then(|arr: &serde_json::Value| arr.get(0))
            .and_then(|obj: &serde_json::Value| obj.get("embedding")) as Option<&serde_json::Value>;

        match embedding_data {
            Some(vec_val) => {
                if let Ok(embedding) = serde_json::from_value::<Vec<f32>>(vec_val.clone()) {
                    return Ok(Some(embedding));
                }
            }
            None => {
                return Err(anyhow::anyhow!("No embedding in API response"));
            }
        }

        Err(anyhow::anyhow!("Failed to parse embedding from API response"))
    }
}

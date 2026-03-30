use std::sync::Arc;
use rag::{Config, EmbeddingClient};

#[test]
fn test_embed_makes_http_request_to_openai_compatible_api() {
    // Тест проверяет, что embed() делает реальный HTTP запрос к OpenAI-совместимому API
    // Вместо placeholder реализации

    let config = Arc::new(Config::default());

    let client = EmbeddingClient::new(config);

    let test_text = "Test text for embedding";

    // Должен сделать HTTP запрос, а не возвращать фиктивный результат
    match client.embed(test_text) {
        Ok(Some(embedding)) => {
            // Проверяем, что получили вектор размером 1536 (стандартный размер embeddings OpenAI)
            assert_eq!(embedding.len(), 1536);

            // Проверяем, что элементы не все нули (placeholder вернул бы все нули)
            let has_non_zero: bool = embedding.iter().any(|&x| x.abs() > 0.0001);
            assert!(
                has_non_zero,
                "Expected non-zero embeddings from real API call"
            );
        }
        Ok(None) => {
            panic!("Expected Some(embedding), got None");
        }
        Err(e) => {
            panic!("Unexpected error: {}", e);
        }
    }
}

#[test]
fn test_embed_handles_empty_text() {
    let config = Arc::new(Config::default());
    let client = EmbeddingClient::new(config);

    // Empty text должен обработаться корректно
    match client.embed("") {
        Ok(Some(embedding)) => {
            assert_eq!(embedding.len(), 1536);
        }
        result => {
            panic!("Expected Some(embedding) for empty text, got {:?}", result);
        }
    }
}

#[test]
fn test_embed_handles_special_characters() {
    let config = Arc::new(Config::default());
    let client = EmbeddingClient::new(config);

    let special_text = "Hello world! 🌍 Test @#$%^&*()";

    match client.embed(special_text) {
        Ok(Some(embedding)) => {
            assert_eq!(embedding.len(), 1536);
            let has_non_zero: bool = embedding.iter().any(|&x| x.abs() > 0.0001);
            assert!(has_non_zero);
        }
        result => {
            panic!("Expected Some(embedding) for special characters, got {:?}", result);
        }
    }
}
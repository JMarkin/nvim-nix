use crate::models::Config;

pub struct ConfigManager {
    config: Config,
}

impl ConfigManager {
    pub fn new() -> Self {
        ConfigManager {
            config: Config::default(),
        }
    }

    pub fn setup(&mut self, opts: Option<serde_json::Value>) -> Result<(), anyhow::Error> {
        if let Some(opts) = opts {
            let merged = serde_json::from_value::<Config>(opts)
                .unwrap_or_else(|_| Config::default());
            self.config = merged;
        }
        Ok(())
    }

    pub fn get_config(&self) -> &Config {
        &self.config
    }
}
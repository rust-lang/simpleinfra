use fastly::log::Endpoint;
use log::{LevelFilter, Log, Metadata, Record};
use std::io::Write;

const MAX_LEVEL: LevelFilter = LevelFilter::Debug;

/// Writes service logs, i.e. the records of the `log` macros, to a Fastly logging endpoint
pub struct ServiceLogger {
    endpoint: Endpoint,
}

impl ServiceLogger {
    pub fn new(endpoint: &str) -> Self {
        let endpoint = Endpoint::from_name(endpoint);
        Self { endpoint }
    }

    /// Installs the logger as the global logger of the `log` crate
    pub fn init(self) {
        log::set_boxed_logger(Box::new(self)).expect("failed to initialize logger");
        log::set_max_level(MAX_LEVEL);
    }
}

impl Log for ServiceLogger {
    fn enabled(&self, metadata: &Metadata) -> bool {
        metadata.level() <= MAX_LEVEL
    }

    fn log(&self, record: &Record) {
        if !self.enabled(record.metadata()) {
            return;
        }

        let message = record.args().to_string();
        let _ = self.endpoint.clone().write(message.as_bytes());
        // Show service logs in `fastly log-tail`
        println!("{message}");
    }

    fn flush(&self) {}
}

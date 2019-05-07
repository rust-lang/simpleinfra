use reqwest::{
    header::{HeaderName, HeaderValue, AUTHORIZATION, USER_AGENT},
    Client, Method, RequestBuilder, StatusCode,
};
use std::error::Error;

pub struct TravisCI {
    client: Client,
    token: String,
}

impl TravisCI {
    pub fn new(token: &str) -> Self {
        TravisCI {
            client: Client::new(),
            token: token.into(),
        }
    }

    pub fn repo(&self, repo: &str) -> Result<Option<Repository>, Box<Error>> {
        let mut resp = self
            .request(Method::GET, &format!("repo/{}", self.encode_repo(repo)))?
            .send()?;
        match resp.status() {
            StatusCode::OK => return Ok(Some(resp.json()?)),
            StatusCode::NOT_FOUND => {}
            _ => {
                resp.error_for_status()?;
            }
        }
        Ok(None)
    }

    pub fn add_env_var(
        &self,
        repo: &str,
        key: &str,
        value: &str,
        public: bool,
    ) -> Result<(), Box<Error>> {
        self.request(
            Method::POST,
            &format!("repo/{}/env_vars", self.encode_repo(repo)),
        )?
        .json(&serde_json::json!({
            "env_var.name": key,
            "env_var.value": value,
            "env_var.public": public,
        }))
        .send()?
        .error_for_status()?;
        Ok(())
    }

    fn request(&self, method: Method, url: &str) -> Result<RequestBuilder, Box<Error>> {
        Ok(self
            .client
            .request(method, &format!("https://api.travis-ci.com/{}", url))
            .header(
                USER_AGENT,
                HeaderValue::from_static("rust-lang/simpleinfra"),
            )
            .header(
                AUTHORIZATION,
                HeaderValue::from_str(&format!("token {}", self.token))?,
            )
            .header(
                HeaderName::from_static("travis-api-version"),
                HeaderValue::from_static("3"),
            ))
    }

    fn encode_repo(&self, repo: &str) -> String {
        repo.replace('/', "%2F")
    }
}

#[derive(serde::Deserialize)]
pub struct Repository {
    pub active: bool,
}

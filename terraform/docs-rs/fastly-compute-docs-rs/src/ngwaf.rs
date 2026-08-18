use fastly::{ConfigStore, Request, Response, http::StatusCode, security};

pub(crate) struct NgWaf {
    corp: String,
    workspace: String,
}

impl NgWaf {
    pub(crate) fn load(config: &ConfigStore) -> Option<Self> {
        let corp = config.get(super::NGWAF_CORP_KEY);
        let workspace = config.get(super::NGWAF_WORKSPACE_KEY);

        let (Some(corp), Some(workspace)) = (corp, workspace) else {
            return None;
        };

        Some(Self { corp, workspace })
    }

    /// Inspect an incoming request using the signal sciences firewall.
    ///
    /// Just hands back the original request, or an error response that should
    /// be returned to the client.
    ///
    /// see
    /// https://www.fastly.com/documentation/solutions/tutorials/next-gen-waf-compute/
    #[allow(clippy::result_large_err)]
    pub(crate) fn inspect(&self, req: Request) -> Result<Request, Response> {
        let config = security::InspectConfig::from_request(&req)
            .corp(&self.corp)
            .workspace(&self.workspace);

        // NOTE: we could later return error status codes for other `InspectVerdict`
        // options, for now we go the safe way, so we don't break anything.

        match security::inspect(config) {
            Ok(resp) => match resp.verdict() {
                security::InspectVerdict::Block => {
                    let status = u16::try_from(resp.status())
                        .ok()
                        .and_then(|status| StatusCode::from_u16(status).ok())
                        .unwrap_or(StatusCode::NOT_ACCEPTABLE);

                    return Err(Response::from_status(status));
                }
                security::InspectVerdict::Allow => {}
                security::InspectVerdict::Unauthorized => {
                    eprintln!("The service is not authorized to inspect the request");
                }
                security::InspectVerdict::Other(name) => {
                    eprintln!("unable to inspect request: {}", name);
                }
            },
            Err(err) => {
                eprintln!("error inspecting request: {:?}", err);
            }
        }

        Ok(req)
    }
}

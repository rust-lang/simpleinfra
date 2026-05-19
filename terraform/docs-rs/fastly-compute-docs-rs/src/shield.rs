use fastly::{
    Backend, ConfigStore, Request, SecretStore,
    error::{Error, anyhow},
    shielding::Shield,
};

/// represents the state of origin shielding for a request/response.
#[derive(Default)]
pub enum State {
    /// shield is disabled or failed initializing
    #[default]
    Disabled,
    /// we're on the Edge POP node, request goes to shield
    OnEdge(fastly::Backend),
    /// we're on the shield POP node, request goes to origin
    OnShield,
}

pub struct Context {
    pub shield: State,
    request_came_from_edge: Option<bool>,
    pub origin_backend: fastly::Backend,
}

impl Default for Context {
    /// Default shielding settings = disabled
    /// means: every POP sends requests directly to the origin.
    fn default() -> Self {
        Context {
            origin_backend: Backend::from_name(super::DOCS_RS_BACKEND)
                .expect("we know the name is valid, and ::from_name just validates that"),
            request_came_from_edge: None,
            shield: State::Disabled,
        }
    }
}

impl Context {
    pub fn load(
        config: &ConfigStore,
        secrets: &SecretStore,
        req: &mut Request,
    ) -> Result<Self, Error> {
        let Some(shield_pop) = config.get(super::SHIELD_POP_KEY) else {
            // no shield configured, disable origin shielding
            return Ok(Context::default());
        };

        let origin_auth = secrets
            .get(super::ORIGIN_AUTH_KEY)
            .expect("failed to get origin auth from secret store")
            .plaintext();
        // Only the exact secret marks a request as having come from an edge POP.
        // Missing or incorrect values are treated as untrusted client input.
        let request_came_from_edge = req
            .get_header(super::X_ORIGIN_AUTH)
            .map(|value| value.as_bytes() == origin_auth.as_ref())
            .unwrap_or(false);

        // Never trust or forward caller-supplied internal auth headers.
        // This makes spoofed values harmless on both edge and shield POPs.
        req.remove_header(super::X_ORIGIN_AUTH);

        let shield = match Shield::new(&shield_pop) {
            Ok(shield) => shield,
            Err(e) => {
                eprintln!(
                    "Could not find shield '{}', Disabling the origin shielding.\n {:?}",
                    shield_pop, e
                );
                // we only log an error here for the case we have a typo in the shield pop name.
                // In this case we should fall back to normal CDN mode, not fail the request entirely.
                return Ok(Context::default());
            }
        };

        let mut ctx = Context {
            request_came_from_edge: Some(request_came_from_edge),
            ..Default::default()
        };

        // shielding is configured with a valid shield
        if shield.running_on() {
            // and we're running on the shield POP node.
            // -> our target for the request is always the origin
            // -> our client can be a user, or fastly edge POP node.
            // Invalid auth has already fallen back to "client request" above.
            ctx.shield = State::OnShield;
        } else {
            // we're running on an edge POP node, so the request should go to the shield node.
            // -> our client is the user
            // -> our target is the shield POP
            ctx.shield = State::OnEdge(shield.encrypted_backend().map_err(|err| {
                anyhow!(
                    "Could not create backend for shield pop '{:?}'.\n {:?}",
                    shield_pop,
                    err
                )
            })?);

            // Edge POPs always overwrite any inbound value with the configured secret
            // before forwarding to the shield.
            req.set_header(super::X_ORIGIN_AUTH, origin_auth.as_ref());
        };

        Ok(ctx)
    }

    /// will the request be sent to the origin or the shield?
    pub fn target_is_origin(&self) -> bool {
        match self.shield {
            State::OnShield | State::Disabled => true,
            State::OnEdge(_) => false,
        }
    }

    /// does the request come from the actual client? Or just the fastly edge POP node?
    pub fn response_is_for_client(&self) -> bool {
        match self.shield {
            State::OnShield => {
                // On the shield node, a valid internal origin auth header means the request
                // arrived from an edge POP rather than directly from the client.
                !self
                    .request_came_from_edge
                    .expect("we always have checked this when the shield is not disabled")
            }
            State::OnEdge(_) | State::Disabled => true,
        }
    }

    /// where the request should be sent to
    pub fn target_backend(&self) -> &fastly::Backend {
        match &self.shield {
            State::OnEdge(shield_backend) => shield_backend,
            State::OnShield | State::Disabled => &self.origin_backend,
        }
    }
}

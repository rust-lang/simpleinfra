use fastly::{
    Backend, ConfigStore,
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
    pub origin_backend: fastly::Backend,
}

impl Default for Context {
    /// Default shielding settings = disabled
    /// means: every POP sends requests directly to the origin.
    fn default() -> Self {
        Context {
            origin_backend: Backend::from_name(super::DOCS_RS_BACKEND)
                .expect("we know the name is valid, and ::from_name just validates that"),
            shield: State::Disabled,
        }
    }
}

impl Context {
    pub fn load(config: &ConfigStore) -> Result<Self, Error> {
        let Some(shield_pop) = config.get(super::SHIELD_POP_KEY) else {
            // no shield configured, disable origin shielding
            return Ok(Context::default());
        };

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

        let mut ctx = Context::default();

        // shielding is configured with a valid shield
        if shield.running_on() {
            // and we're running on the shield POP node.
            // -> our client is the fastly edge POP node.
            // -> our target for the request is the origin
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
            State::OnShield => false,
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

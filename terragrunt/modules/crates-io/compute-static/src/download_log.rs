//! Edge-filtered download log for the crates.io download counter
//!
//! The filter rules mirror `crates_io_cdn_logs` in the crates.io repository, which counts the
//! lines written here. Unlike crates.io, the version is not parsed as semver. A `200 OK` response
//! means that the crate file exists, so its version is valid.

use fastly::Request;
use fastly::http::Method;
use percent_encoding::percent_decode_str;
use time::Date;

/// A crate download request, before the response status is known
#[derive(Debug, PartialEq)]
pub struct CrateDownload {
    date: Date,
    name: String,
    version: String,
}

impl CrateDownload {
    /// Returns the download if the request would be counted by crates.io given a `200 OK`
    /// response
    pub fn from_request(request: &Request, date: Date) -> Option<Self> {
        let user_agent = request.get_header("User-Agent")?.to_str().ok()?;
        if request.get_method() != Method::GET || !should_count_user_agent(user_agent) {
            return None;
        }

        let url = percent_decode_str(request.get_url_str()).decode_utf8_lossy();
        let (name, version) = parse_path(&url)?;

        Some(Self {
            date,
            name: name.to_owned(),
            version: version.to_owned(),
        })
    }

    /// Formats the download as a `{date}\t{name}\t{version}` line
    pub fn log_line(&self) -> String {
        format!("{}\t{}\t{}", self.date, self.name, self.version)
    }
}

/// Mirrors `should_count_user_agent()` in `crates_io_cdn_logs`
fn should_count_user_agent(user_agent: &str) -> bool {
    user_agent.starts_with("cargo/") || user_agent.starts_with("cargo ")
}

/// Mirrors `parse_path()` in `crates_io_cdn_logs`, without the semver parse
fn parse_path(path: &str) -> Option<(&str, &str)> {
    let path = path.split_once('?').map_or(path, |(path, _query)| path);
    let (_, path) = path.split_once("/crates/")?;

    let (krate, rest) = path.split_once('/')?;
    let version = rest.strip_suffix("/download").or_else(|| {
        rest.strip_suffix(".crate")
            .and_then(|rest| rest.strip_prefix(krate))
            .and_then(|rest| rest.strip_prefix('-'))
    })?;

    Some((krate, version))
}

#[cfg(test)]
mod tests {
    use super::*;
    use time::macros::date;

    const DATE: Date = date!(2024 - 01 - 16);
    const CARGO: &str = "cargo/1.88.0 (873a06493 2025-05-10)";
    const URL: &str = "https://static.crates.io/crates/foo/foo-1.2.3.crate";

    fn download(url: &str, user_agent: &str) -> Option<String> {
        let request = Request::get(url).with_header("User-Agent", user_agent);
        CrateDownload::from_request(&request, DATE).map(|download| download.log_line())
    }

    #[test]
    fn test_paths() {
        for (path, expected) in [
            ("/crates/foo/foo-1.2.3.crate", "2024-01-16\tfoo\t1.2.3"),
            ("/crates/foo/1.2.3/download", "2024-01-16\tfoo\t1.2.3"),
            (
                "/crates/foo/foo-1.2.3.crate?param=value",
                "2024-01-16\tfoo\t1.2.3",
            ),
            (
                "/crates/foo-bar/foo-bar-1.0.0-rc.1.crate",
                "2024-01-16\tfoo-bar\t1.0.0-rc.1",
            ),
            (
                "/crates/foo-bar/1.0.0-rc.1/download",
                "2024-01-16\tfoo-bar\t1.0.0-rc.1",
            ),
            (
                "/crates/foo/foo-0.5.2%2B5.3.0.crate",
                "2024-01-16\tfoo\t0.5.2+5.3.0",
            ),
            (
                "/crates/foo/0.5.2+5.3.0/download",
                "2024-01-16\tfoo\t0.5.2+5.3.0",
            ),
        ] {
            let url = format!("https://static.crates.io{path}");
            assert_eq!(download(&url, CARGO).as_deref(), Some(expected), "{path}");
        }

        for path in [
            "/",
            "/?param=value",
            "/crates/",
            "/readmes/foo/foo-1.2.3.crate",
            "/crates/foo-1.2.3.crate",
            "/crates/foo/foo-1.2.3",
            "/crates/foo/foo-1.2.3.html",
            "/crates/foo/bar-1.2.3.crate",
            "/crates/foo/foo@1.2.3.crate",
            "/crates/foo/foo.crate",
        ] {
            let url = format!("https://static.crates.io{path}");
            assert_eq!(download(&url, CARGO), None, "{path}");
        }
    }

    #[test]
    fn test_user_agents() {
        for user_agent in [
            "cargo/1.92.0-nightly (344c4567c 2025-10-21)",
            "cargo/",
            "cargo 1.74.0",
        ] {
            assert!(download(URL, user_agent).is_some(), "{user_agent}");
        }

        for user_agent in [
            "Mozilla/5.0",
            "curl/7.64.1",
            "",
            "Cargo/1.0.0",
            "cargo",
            "cargo-",
        ] {
            assert_eq!(download(URL, user_agent), None, "{user_agent}");
        }

        assert_eq!(CrateDownload::from_request(&Request::get(URL), DATE), None);

        let request = Request::get(URL).with_header("User-Agent", b"cargo/\xff".as_slice());
        assert_eq!(CrateDownload::from_request(&request, DATE), None);
    }

    #[test]
    fn test_methods() {
        assert!(download(URL, CARGO).is_some());

        for method in [
            Method::HEAD,
            Method::POST,
            Method::PUT,
            Method::DELETE,
            Method::OPTIONS,
        ] {
            let request = Request::new(method.clone(), URL).with_header("User-Agent", CARGO);
            assert_eq!(
                CrateDownload::from_request(&request, DATE),
                None,
                "{method}"
            );
        }
    }
}

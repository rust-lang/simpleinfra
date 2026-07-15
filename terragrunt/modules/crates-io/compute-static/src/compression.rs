use fastly::mime::{self, Mime};

pub fn is_compressible_content_type(content_type: &Mime) -> bool {
    content_type.type_() == mime::TEXT
        || matches!(content_type.subtype(), mime::JSON | mime::XML)
        || matches!(content_type.suffix(), Some(mime::JSON | mime::XML))
}

#[cfg(test)]
mod tests {
    use super::is_compressible_content_type;
    use fastly::mime::Mime;

    fn mime(value: &str) -> Mime {
        value.parse().unwrap()
    }

    #[test]
    fn text_and_structured_content_types_are_compressible() {
        for content_type in [
            "text/html; charset=utf-8",
            "text/xml;charset=utf-8",
            "application/json",
            "application/xml",
            "application/rss+xml",
            "application/vnd.api+json",
        ] {
            assert!(
                is_compressible_content_type(&mime(content_type)),
                "expected {content_type} to be compressible"
            );
        }
    }

    #[test]
    fn binary_content_types_are_not_compressible() {
        for content_type in ["application/gzip", "application/zip", "image/png"] {
            assert!(
                !is_compressible_content_type(&mime(content_type)),
                "expected {content_type} not to be compressible"
            );
        }
    }
}

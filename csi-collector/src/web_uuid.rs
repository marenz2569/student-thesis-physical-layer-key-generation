use std::fmt;
use std::ops::Deref;

use serde::de::{self, Visitor, Deserialize, Deserializer};

use uuid::Uuid;

pub struct WebUuid(uuid::Uuid);

struct WebUuidVisitor;

impl<'de> Visitor<'de> for WebUuidVisitor {
    type Value = WebUuid;

    fn expecting(&self, formatter: &mut fmt::Formatter) -> fmt::Result {
        formatter.write_str("an uuid of hexadecimal digits with optional hyphens")
    }

    fn visit_str<E>(self, value: &str) -> Result<Self::Value, E>
    where
        E: de::Error,
    {
        match Uuid::parse_str(&value) {
            Ok(x) => Ok(WebUuid(x)),
            Err(e) => Err(E::custom(e.to_string())),
        }
    }
}

impl<'de> Deserialize<'de> for WebUuid {
    fn deserialize<D>(deserializer: D) -> Result<WebUuid, D::Error>
    where
        D: Deserializer<'de>,
    {
        deserializer.deserialize_str(WebUuidVisitor)
    }
}

impl Deref for WebUuid {
    type Target = Uuid;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

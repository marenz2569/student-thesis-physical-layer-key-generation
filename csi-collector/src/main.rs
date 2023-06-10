extern crate clap;

mod structs;
mod web_uuid;

use structs::Args;
use web_uuid::WebUuid;

use actix_web::{post, web, App, HttpResponse, HttpServer};
use log::{debug, info, warn};
use std::{env, fs};
use std::ops::Deref;
use std::path::Path;
use clap::Parser;
use serde::{Serialize, Deserialize};

struct Config {
    datadir: String,
}

#[derive(Deserialize)]
struct SubmitCSIPath {
    uuid: WebUuid,
    from: String,
    to: String,
}

#[derive(Serialize, Deserialize)]
struct SubmitCSIData {
    data: Vec<u8>,
    // num_tones, nc, nr, (real, imag)
    csi: Vec<Vec<Vec<(i16, i16)>>>,
    timestamp: u32,
    nr: u8,
    nc: u8,
    num_tones: u8,
    rssi: i16,
    noise: u16,
    rate: u8,
    version: String,
    label: String,
}

#[post("/submit/{uuid}/{from}/{to}")]
async fn submit_csi(
    config: web::Data<Config>,
    path: web::Path<SubmitCSIPath>,
    data_str: String,
    // web::Json<SubmitCSIData> didn't work in my case..
) -> HttpResponse {
    // ensure that our payload is well formated
    let data: SubmitCSIData = serde_json::from_str(&data_str).unwrap();

    const VALID_FROM_TO: &'static [&'static str] = &["alice", "bob", "eve"];

    if !VALID_FROM_TO.iter().any(|&s| s == path.from) {
        return HttpResponse::BadRequest()
            .reason("Path from is not valid")
            .finish();
    }

    if !VALID_FROM_TO.iter().any(|&s| s == path.to) {
        return HttpResponse::BadRequest()
            .reason("Path to is not valid")
            .finish();
    }

    if path.from == path.to {
        return HttpResponse::BadRequest()
            .reason("Path from and to may not be equal")
            .finish();
    }

    let dir = Path::new(&config.datadir).join(path.uuid.deref().to_string()).join(path.from.clone()).join(path.to.clone());

    let result_dir = fs::create_dir_all(dir.clone());
    if result_dir.is_err() {
        let err = result_dir.err().unwrap().to_string();
        warn!("Could not create directory {}: {}", dir.to_str().unwrap(), err);
        return HttpResponse::InternalServerError()
            .reason("Could not create directory")
            .finish();
    };

    let filepath = dir.join("data.json");

    let result_write = std::fs::write(
        filepath.clone(),
        data_str,
    );

    if result_write.is_err() {
        let err = result_write.err().unwrap().to_string();
        warn!("Could not write file {}: {}", filepath.to_str().unwrap(), err);
        return HttpResponse::InternalServerError()
            .reason("Could not write file")
            .finish();
    };

    HttpResponse::Ok()
        .finish()
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let args = Args::parse();
    env_logger::init();

    let datadir = env::var("CSI_COLLECTOR_DATADIR").unwrap_or(String::from("/var/lib/csi-collector"));

    info!("Starting CSI Data Collection Server...");
    debug!("Using {} as data directory", datadir);
    let host = args.host.as_str();
    let port = args.port;

    fs::create_dir_all(datadir.clone())?;

    HttpServer::new(move || {
        App::new()
            .app_data(web::Data::new(Config {
                datadir: datadir.clone(),
            }))
            .service(submit_csi)
    })
    .bind((host, port))?
    .run()
    .await
}

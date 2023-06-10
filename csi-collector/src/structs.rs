extern crate clap;

use clap::Parser;

#[derive(Parser, Debug)]
#[clap(name = "csi-collector")]
#[clap(author = "markus.schmidl@mailbox.org")]
#[clap(version = "0.1.0")]
#[clap(about = "web server for channel state information data collection of openwrt access points", long_about = None)]
pub struct Args {
    #[clap(long, default_value_t = String::from("127.0.0.1"))]
    pub host: String,

    #[clap(short, long, default_value_t = 8080)]
    pub port: u16,
}

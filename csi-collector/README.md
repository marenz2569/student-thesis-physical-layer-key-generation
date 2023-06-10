# CSI Data Collection Server

This webserver saves all channel state information data from the access points.

## Command line arguments

```
Usage: csi-collector [OPTIONS]

Options:
      --host <HOST>  [default: 127.0.0.1]
  -p, --port <PORT>  [default: 8080]
  -h, --help         Print help information
  -V, --version      Print version information
```

## Environment variables

Variable                | Description
------------------------|------------
RUST\_LOG               | Set the log level of the application. Log levels are defined by rusts [env\_logger library](https://docs.rs/env_logger/latest/env_logger/).
CSI\_COLLECTOR\_DATADIR | Data directory of the server. All submited channel state measurements are saved here.

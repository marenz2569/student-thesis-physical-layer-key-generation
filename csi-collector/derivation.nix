{ naersk, src, lib }:

naersk.buildPackage {
  pname = "csi-collector";
  version = "0.1.0";

  src = ./.;

  cargoSha256 = lib.fakeSha256;
}

# This file has been generated by node2nix 1.6.0. Do not edit!

{pkgs ? import <nixpkgs> {
    inherit system;
  }, system ? builtins.currentSystem, nodejs ? pkgs."nodejs-6_x"}:

let
  nodeEnv = import ./node-env.nix {
    inherit (pkgs) stdenv buildPackages utillinux runCommand writeTextFile;
    inherit nodejs;
    # inherit (pkgs.buildPackages) utillinux;
    # inherit (pkgs) stdenv buildPackages runCommand writeTextFile;
    # inherit nodejs;
    libtool = if pkgs.stdenv.isDarwin then pkgs.darwin.cctools else null;
  };
in
import ./node-packages-v6.nix {
  inherit (pkgs) fetchurl fetchgit;
  inherit nodeEnv;
}

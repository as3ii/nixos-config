{ lib
, rustPlatform
, fetchFromGitHub
, installShellFiles
, stdenv
, darwin
,
}:

rustPlatform.buildRustPackage rec {
  pname = "joshuto";
  version = "0.9.9-unstable-2025-05-26";

  src = fetchFromGitHub {
    owner = "as3ii";
    repo = "joshuto";
    rev = "e55572b154a6f2dbe995370ac82dc67b3fb4bf98";
    #hash = lib.fakeHash;
    hash = "sha256-BSSJo75aPzPlzIY56izyDp0MnNKeMkiCEMKoGsa2NAQ=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-K/++/NdOLSvhxQ8LBS+jnthCRJxScoOjWSp7pmfHVaQ=";

  nativeBuildInputs = [ installShellFiles ];

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.Foundation
  ];

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd joshuto \
      --bash <($out/bin/joshuto completions bash) \
      --zsh <($out/bin/joshuto completions zsh) \
      --fish <($out/bin/joshuto completions fish)
  '';

  meta = with lib; {
    description = "Ranger-like terminal file manager written in Rust";
    homepage = "https://github.com/as3ii/joshuto";
    changelog = "https://github.com/kamiyaa/joshuto/releases/tag/${src.rev}";
    license = licenses.lgpl3Only;
    maintainers = with maintainers; [
      figsoda
      totoroot
      xrelkd
    ];
    mainProgram = "joshuto";
  };
}

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
  version = "0.9.9-unstable-2026-07-06";

  src = fetchFromGitHub {
    owner = "as3ii";
    repo = "joshuto";
    rev = "7a52969c4091c56eb02ee90ca410958c4d92d482";
    #hash = lib.fakeHash;
    hash = "sha256-E8khqAYAWW0va6/6f+Ix6RejyI3mydr+G5fQuK2GRgw=";
  };

  cargoHash = "sha256-37lXYDKHoaUo3jMfYfxq46pan4OrlTL8MspOymxqAuo=";

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
    mainProgram = "joshuto";
  };
}

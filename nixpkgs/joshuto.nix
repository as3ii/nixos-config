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
  version = "0.9.8-unstable-2025-04-14";

  src = fetchFromGitHub {
    owner = "as3ii";
    repo = "joshuto";
    rev = "87ac379dc8d900a4bd845db6b4d78a62118afe70";
    #hash = lib.fakeHash;
    hash = "sha256-V7siNxNCiiFTSptKWAdGARNTP7YKLg0otBE7K451yPg=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-TRNn7Nd7Gz+rcGqp98jZaOGqhcJv4H+79WDcwslCQOM=";

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

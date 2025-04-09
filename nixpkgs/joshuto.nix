{
  lib,
  rustPlatform,
  fetchFromGitHub,
  installShellFiles,
  stdenv,
  darwin,
}:

rustPlatform.buildRustPackage rec {
  pname = "joshuto";
  version = "0.9.8-unstable-2025-04-09";

  src = fetchFromGitHub {
    owner = "as3ii";
    repo = "joshuto";
    rev = "65e1b9bebaac659603575596530e2cb8b7b69979";
    #hash = lib.fakeHash;
    hash = "sha256-ui3cVl62ba77IgZ2jRSXjzBZ3BlNjV+ezJcoB7wDnWI=";
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

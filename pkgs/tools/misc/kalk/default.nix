{ lib
, fetchFromGitHub
, m4
, rustPlatform
}:
rustPlatform.buildRustPackage rec {
  pname = "kalk";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "PaddiM8";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-1iZvp30/V0bw9NBxiKNiDgOMYJkDsGhTGdBsAPggdEg=";
  };

  cargoSha256 = "sha256-qHXlhKeuDpebpbbGr34Uvwyg//HdCL0UoTqRf9vEfmE=";

  nativeBuildInputs = [ m4 ];

  outputs = [ "out" "lib" ];

  postInstall = ''
    moveToOutput "lib" "$lib"
  '';

  meta = with lib; {
    homepage = "https://kalk.strct.net";
    changelog = "https://github.com/PaddiM8/kalk/releases/tag/v${version}";
    description = "A command line calculator";
    longDescription = ''
      A command line calculator that supports math-like syntax with user-defined
      variables, functions, derivation, integration, and complex numbers
    '';
    license = licenses.mit;
    maintainers = with maintainers; [ lovesegfault ];
  };
}

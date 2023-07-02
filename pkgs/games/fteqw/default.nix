{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  runCommand,
  # required for both
  pkg-config,
  which,
  libjpeg,
  zlib,
  libvorbis,
  cmake,
  gnutls,
  freetype,
  libogg,
  libopus,
  libpng,
  speex,
  speexdsp,
  zip,
  # gl
  libX11,
  libGLU,
  libGL,
  libXpm,
  libXext,
  libXrandr,
  libXcursor,
  libXxf86vm,
  alsa-lib,
  SDL2,
  SDL2_mixer,
  # for variants
  withSDL ? true,
  withOpenGL ? true,
  withServer ? true,
}: let
  variant =
    if withSDL && withServer
    then ""
    else if withSDL
    then "-sdl"
    else if withOpenGL
    then "-gl"
    else if withServer
    then "-sv"
    else "-what-even-am-i";
in {
  fteqw = stdenv.mkDerivation rec {
    pname = "fteqw${variant}";
    version = "6343";
    name = "${pname}-${version}";

    src = fetchFromGitHub {
      owner = "fte-team";
      repo = "fteqw";
      rev = "d76d14294986cabc0dcc626237eb2b8473c8ac0e";
      sha256 = "sha256-JAf+esu2AHVbV1cT5xtBrdB+vFxjqCN8pnKrpjTj5Zs=";
    };

    nativeBuildInputs = [cmake pkg-config zip];
    buildInputs =
      [libjpeg zlib libvorbis libpng gnutls]
      ++ lib.optionals withOpenGL [
        libGL
        libGLU
        libopus.dev
        libX11.dev
        libXcursor
        libXext
        libXpm
        libXrandr
        libXxf86vm
        speex
        SDL2.dev
        SDL2_mixer
      ];

    patches = [./remove-native-flag.patch];

    cmakeFlags =
      ["-DFTE_ENGINE=false" "-DFTE_ENGINE_SERVER_ONLY=false"]
      ++ lib.optionals withOpenGL ["-DFTE_ENGINE=true"]
      ++ lib.optionals withSDL ["-DFTE_USE_SDL=true"]
      ++ lib.optionals withServer ["-DFTE_ENGINE_SERVER_ONLY=true"];

    enableParallelBuilding = true;

    installPhase =
      lib.optionalString withServer
      ''
        install -Dm755 fteqw-sv "$out/bin/fteqw-sv"
      ''
      + lib.optionalString withSDL
      ''
        install -Dm755 fteqw "$out/bin/fteqw-sdl"
      ''
      + lib.optionalString (withOpenGL && !withSDL)
      ''
        install -Dm755 fteqw "$out/bin/fteqw-gl"
      '';

    postFixup =
      lib.optionalString withServer
      ''
        patchelf \
            --add-needed ${gnutls.out}/lib/libgnutls.so \
            $out/bin/fteqw-sv
      ''
      + lib.optionalString withSDL
      ''
        patchelf \
            --add-needed ${gnutls.out}/lib/libgnutls.so \
            $out/bin/fteqw-sdl
      ''
      + lib.optionalString (withOpenGL && !withSDL)
      ''
        patchelf \
            --add-needed ${gnutls.out}/lib/libgnutls.so \
            --add-needed ${libX11}/lib/libX11.so \
            --add-needed ${libGL.out}/lib/libGL.so \
            $out/bin/fteqw-gl
      '';

    meta = {
      description = "";
      longDescription = ''
      '';
      homepage = "https://fteqw.org/";
      license = lib.licenses.gpl2Plus;
      maintainers = [];
      platforms = lib.platforms.linux;
    };
  };
}

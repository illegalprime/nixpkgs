{
  lib,
  maven,
  fetchFromGitHub,
  jdk25,
  makeWrapper,
}:

let
  fileTypes = [
    "eon"
    "seext"
    "selibrary"
    "seplugin"
    "seproject"
    "setheme"
  ];

  mimeType = t: "application/x-strange-eons-${t}";

  mimeXml = builtins.toFile "strange-eons-mime.xml" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
    ${lib.concatMapStrings (t: ''
      <mime-type type="${mimeType t}">
        <comment>Strange Eons ${t} document</comment>
        <glob pattern="*.${t}"/>
        <icon name="strange-eons-${t}"/>
      </mime-type>
    '') fileTypes}
    </mime-info>
  '';

  desktopFile = builtins.toFile "strange-eons.desktop" ''
    [Desktop Entry]
    Type=Application
    Name=Strange Eons
    GenericName=Paper Game Component Designer
    Comment=Design cards, tokens, boards and other paper game components
    Exec=strange-eons %F
    TryExec=strange-eons
    Icon=strange-eons
    Terminal=false
    Categories=Graphics;
    MimeType=${lib.concatMapStringsSep ";" mimeType fileTypes};
    StartupWMClass=ca-cgjennings-apps-arkham-StrangeEons
    Keywords=card;board game;token;printable;layout;
  '';
in
maven.buildMavenPackage rec {
  pname = "strange-eons";
  version = "3.5.1";

  src = fetchFromGitHub {
    owner = "christophercurrie";
    repo = "strange-eons";
    rev = "v${version}";
    hash = "sha256-dpKiQlgziCwOyt19edAEctzTaVo18qqyW4ea0WyZf0c=";
  };

  mvnJdk = jdk25;

  mvnHash = "sha256-/fKk7aigfj5G6jzpHoE7imqzXY4mXF5SOi83MbYV+5s=";

  mvnParameters = lib.concatStringsSep " " [
    "-Pdeploy"
    "-Dapp.major=3"
    "-Dapp.minor=5"
    "-Dapp.patch=1"
    "-Dapp.build=5349"
    "-Dapp.type=GENERAL"
  ];

  nativeBuildInputs = [
    makeWrapper
  ];

  dontConfigure = true;
  doCheck = false;

  postPatch = "patchShebangs deployment/scripts";

  installPhase =
    let
      jarPath = "$out/libexec/strange-eons/strange-eons.jar";
    in
    ''
      install -Dm644 deployment/assembled/strange-eons.jar ${jarPath}

      install -Dm444 deployment/assets/icons/app/48.png \
        $out/share/icons/hicolor/48x48/apps/strange-eons.png
      for t in ${lib.concatStringsSep " " fileTypes}; do
        install -Dm444 deployment/assets/icons/$t/256.png \
          $out/share/icons/hicolor/256x256/apps/strange-eons-$t.png
      done

      install -Dm644 ${mimeXml} $out/share/mime/packages/strange-eons.xml
      install -Dm644 ${desktopFile} $out/share/applications/strange-eons.desktop

      makeWrapper ${jdk25}/bin/java $out/bin/strange-eons \
        --prefix PATH : ${jdk25}/bin \
        --set-default JAVA_HOME ${jdk25} \
        --add-flags -javaagent:${jarPath} \
        --add-flags -cp ${jarPath} \
        --add-flags ca.cgjennings.apps.arkham.StrangeEons

      makeWrapper ${jdk25}/bin/java $out/bin/sedebug \
        --prefix PATH : ${jdk25}/bin \
        --set-default JAVA_HOME ${jdk25} \
        --add-flags -cp ${jarPath} \
        --add-flags "ca.cgjennings.apps.arkham.plugins.debugging.Client"
    '';

  meta = {
    description = "Scriptable card, board and game piece design tool";
    longDescription = ''
      Strange Eons is a tool for creating components for paper-based games
      such as cards, tokens, boards and boxes. Designs are laid out as
      printable decks, and the program is extensible through a built-in
      development environment and debugger for plug-ins written in Java or
      JavaScript.
    '';
    homepage = "https://strangeeons.org/";
    license = lib.licenses.mit;
    mainProgram = "strange-eons";
    platforms = lib.platforms.unix;
  };
}

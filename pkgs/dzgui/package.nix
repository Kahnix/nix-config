{
  fetchFromGitHub,
  glib,
  gobject-introspection,
  gtk3,
  lib,
  makeDesktopItem,
  python313Packages,
  wrapGAppsHook3,
}:

let
  python-a2s = python313Packages.buildPythonPackage {
    pname = "python-a2s";
    version = "1.4.1";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "Yepoleb";
      repo = "python-a2s";
      rev = "b40eb24cdbb06ebd08272f224257fe5a81610e86";
      hash = "sha256-UGzHpU3ara9fAFhMJHJq5dhttHMC/xColR4fGL3JYmA=";
    };

    build-system = [ python313Packages.setuptools ];
  };

  dayzquery = python313Packages.buildPythonPackage {
    pname = "dayzquery";
    version = "1.3.1";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "Yepoleb";
      repo = "dayzquery";
      rev = "07483b88ed096327ebca752f5e177011b604d7fe";
      hash = "sha256-HH8TRnPwWBSkfmG245lbVG3tN6VbsRl/7YEg07Kzptg=";
    };

    build-system = [ python313Packages.setuptools ];
    dependencies = [ python-a2s ];
  };

  desktopItem = makeDesktopItem {
    name = "dzgui";
    desktopName = "DZGUI";
    comment = "DayZ server browser and mod manager";
    exec = "dzgui";
    icon = "dzgui";
    startupNotify = true;
    startupWMClass = "DZGUI";
    categories = [ "Game" ];
  };
in
python313Packages.buildPythonApplication {
  pname = "dzgui";
  version = "7.0.0b24";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "aclist";
    repo = "dztui";
    tag = "7.0.0b24";
    hash = "sha256-f9wptx1XmBPYy4O9xHQn8M9BJ0CcmDrjJahrd3X7csE=";
  };

  postPatch = ''
    substituteInPlace dzgui/const/update.py \
      --replace-fail "ALLOW_UPDATES = True" "ALLOW_UPDATES = False"
  '';

  build-system = with python313Packages; [
    setuptools
    setuptools-scm
  ];

  nativeBuildInputs = [
    gobject-introspection
    wrapGAppsHook3
  ];

  buildInputs = [ gtk3 ];

  dependencies = with python313Packages; [
    dayzquery
    packaging
    psutil
    pygobject3
    python-a2s
    requests
    vdf
  ];

  pythonRelaxDeps = [
    "packaging"
    "psutil"
    "pygobject"
    "requests"
  ];

  postInstall = ''
    install -Dm644 dzgui/data/images/icon.png \
      "$out/share/icons/hicolor/256x256/apps/dzgui.png"
    install -Dm644 ${desktopItem}/share/applications/dzgui.desktop \
      "$out/share/applications/dzgui.desktop"
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ glib ]}
    )
  '';

  meta = {
    description = "DayZ server browser and mod manager for Linux";
    homepage = "https://aclist.github.io/dzgui";
    license = lib.licenses.gpl3Plus;
    mainProgram = "dzgui";
    platforms = [ "x86_64-linux" ];
  };
}

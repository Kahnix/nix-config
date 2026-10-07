{ gparted }:

# GParted's launcher elevates through pkexec, which drops DISPLAY; pass it on
# so the root process can open its window.
gparted.overrideAttrs (oldAttrs: {
  postPatch = (oldAttrs.postPatch or "") + ''
    substituteInPlace gparted.in \
      --replace-fail \
        "@gksuprog@ '@bindir@/gparted' \"\$@\"" \
        "@gksuprog@ env DISPLAY=\"\$DISPLAY\" '@bindir@/gparted' \"\$@\""
  '';
})

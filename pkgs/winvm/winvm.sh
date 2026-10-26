S="${XDG_DATA_HOME:-$HOME/.local/share}/winvm"
C="${XDG_CACHE_HOME:-$HOME/.cache}/winvm"
CPUS="${WINVM_CPUS:-8}"
MEMORY="${WINVM_MEMORY:-8G}"

SSH_PORT=2222
RDP_PORT=3390
GUEST_ST_PORT=22100
HOST_ST_PORT=22101
HOST_ST_GUI=8385

TMPDIRS=()
ARGS=()
ISO=""
NEW_TMP=""
RESOLVED=""
# Persisted in $S/config: synced host folders (realpaths) and the Syncthing pair.
FOLDERS=()
HOST_ST_ID=""
GUEST_ST_ID=""
HOST_ST_KEY=""
GUEST_ST_KEY=""
ST_VERSION=""
# Set by select_project: synced folder for this command, guest root and cwd.
PROJ_NAME=""
PROJ_ROOT=""
PROJ_CWD=""

die() {
  printf 'winvm: %s\n' "$*" >&2
  exit 1
}

warn() {
  printf 'winvm: warning: %s\n' "$*" >&2
}

cleanup() {
  local d
  for d in "${TMPDIRS[@]}"; do
    rm -rf "$d"
  done
}
trap cleanup EXIT

new_tmp() {
  NEW_TMP=$(mktemp -d)
  TMPDIRS+=("$NEW_TMP")
}

usage() {
  cat <<'EOF'
winvm - Windows 11 dev VM (QEMU) with live folder sync

Usage:
  winvm create <host-folder>... [--console]  create + install + provision the VM (~1 h);
                                          each folder syncs to C:\src\<folder name>
  winvm up [--console]                    start VM and host Syncthing
  winvm down                              shut the VM down, stop Syncthing
  winvm status                            VM, SSH and per-folder sync state
  winvm screenshot [file.png]             save a screenshot of the VM display
  winvm destroy --yes                     delete the VM and all its state
  winvm provision                         (re)install the guest toolchain
  winvm sync [list]                       list synced folders
  winvm sync add <host-folder>            sync another folder (VM must be running)
  winvm sync remove <name>                stop syncing a folder (files are kept)
  winvm ssh [args...]                     ssh into the guest (PowerShell)
  winvm exec <ps-command...>              sync, then run a PowerShell command in the
                                          guest copy of the current directory; exit
                                          code is that of the last native command
                                          (1 if the last statement failed without one)
  winvm gui <ps-command...>               same, but on the guest desktop; streams output
  winvm gui-stop                          kill the running gui command
  winvm prepare                           vector: rustup/pnpm install/cargo fetch + LFS
  winvm build [local|dev|test|prod]       vector: build vector-client (default: local)
  winvm rdp                               open an RDP session to the guest desktop
  winvm help                              this text

exec/gui/prepare/build use the synced folder containing $PWD (or the only one);
override with WINVM_PROJECT=<name>.
Env: WINVM_CPUS (8), WINVM_MEMORY (8G), WINVM_ISO (use this ISO, skip hash check)
EOF
}

# ---------- state helpers ----------

vm_running() {
  local pid cmd
  [ -s "$S/qemu.pid" ] || return 1
  pid=$(cat "$S/qemu.pid")
  kill -0 "$pid" 2>/dev/null || return 1
  # QEMU unlinks its pidfile only on a clean exit, so after a SIGKILL or a host
  # crash the PID can belong to something else. Require it to be this VM's qemu
  # before trusting it: cmd_down kills `pid`.
  cmd=$(ps -p "$pid" -o command= 2>/dev/null) || return 1
  case "$cmd" in
    *qemu-system-*) return 0 ;;
  esac
  return 1
}

require_vm() {
  vm_running || die "VM is not running (winvm up)"
}

load_config() {
  [ -f "$S/config" ] || die "no VM found at $S (winvm create <folder>...)"
  # shellcheck source=/dev/null
  . "$S/config"
}

save_config() {
  {
    printf 'FOLDERS=('
    printf ' %q' "${FOLDERS[@]}"
    printf ' )\n'
    printf 'HOST_ST_ID=%q\n' "$HOST_ST_ID"
    printf 'GUEST_ST_ID=%q\n' "$GUEST_ST_ID"
    printf 'HOST_ST_KEY=%q\n' "$HOST_ST_KEY"
    printf 'GUEST_ST_KEY=%q\n' "$GUEST_ST_KEY"
    printf 'ST_VERSION=%q\n' "$ST_VERSION"
  } >"$S/config"
}

# resolve_folder <path>: validate a new synced folder against FOLDERS; sets RESOLVED.
resolve_folder() {
  local p base f
  [ -d "$1" ] || die "not a directory: $1"
  p=$(realpath "$1")
  base=$(basename "$p")
  [[ "$base" =~ ^[A-Za-z0-9._-]+$ ]] || die "folder name '$base' must match [A-Za-z0-9._-]+"
  for f in "${FOLDERS[@]}"; do
    [ "$(basename "$f")" != "$base" ] || die "a synced folder named $base already exists: $f"
    [[ "$p/" != "$f/"* && "$f/" != "$p/"* ]] || die "$p overlaps the synced folder $f"
  done
  RESOLVED=$p
}

# Host side of a synced folder: default .stignore (kept if present) and the marker.
init_folder() {
  if [ ! -e "$1/.stignore" ]; then
    install -m 644 "$WINVM_DATA/stignore" "$1/.stignore"
  fi
  mkdir -p "$1/.stfolder"
}

# PowerShell single-quoted string literal.
ps_quote() {
  local q="'"
  printf "'%s'" "${1//$q/$q$q}"
}

# Pick the synced folder for exec/gui/prepare/build: WINVM_PROJECT=<name>, else the
# folder containing $PWD (cwd maps to the same subdirectory in the guest), else the
# only folder.
select_project() {
  local f here rel="" host=""
  if [ -n "${WINVM_PROJECT:-}" ]; then
    for f in "${FOLDERS[@]}"; do
      [ "$(basename "$f")" != "$WINVM_PROJECT" ] || host=$f
    done
    [ -n "$host" ] || die "WINVM_PROJECT=$WINVM_PROJECT is not a synced folder (winvm sync list)"
  else
    here=$(pwd -P)
    for f in "${FOLDERS[@]}"; do
      if [ "$here" = "$f" ] || [[ "$here" == "$f"/* ]]; then
        host=$f
        rel=${here#"$f"}
      fi
    done
    if [ -z "$host" ]; then
      [ "${#FOLDERS[@]}" -eq 1 ] || die "run inside a synced folder or set WINVM_PROJECT=<name> (winvm sync list)"
      host=${FOLDERS[0]}
    fi
  fi
  PROJ_NAME=$(basename "$host")
  PROJ_ROOT="C:\\src\\$PROJ_NAME"
  PROJ_CWD="$PROJ_ROOT${rel//\//\\}"
}

gssh() {
  ssh -F "$S/ssh_config" winvm "$@"
}

ssh_probe() {
  ssh -F "$S/ssh_config" -o ConnectTimeout=5 -o BatchMode=yes winvm 'exit 0' >/dev/null 2>&1
}

# PowerShell prefix for remote commands: without a console, progress records (e.g.
# "Preparing modules for first use") reach stderr as CLIXML.
PS_INIT="\$ProgressPreference = 'SilentlyContinue'"
# Suffix: exit with the last native exit code, or 1 when the last statement failed
# without one (script blocked/unparsable, cmdlet error).
# shellcheck disable=SC2016
PS_EXIT='$ok = $?; if ($LASTEXITCODE) { exit $LASTEXITCODE }; if (-not $ok) { exit 1 }; exit 0'

gps() {
  gssh "$PS_INIT; $1; $PS_EXIT"
}

hmp() {
  printf '%s\n' "$1" | socat -t 1 - "UNIX-CONNECT:$S/monitor.sock" >/dev/null
}

rand() {
  local x
  x=$(head -c 96 /dev/urandom | base64 -w0 | tr -dc 'A-Za-z0-9')
  printf '%s' "${x:0:$1}"
}

xml_esc() {
  printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g'
}

sed_esc() {
  printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'
}

wait_exit() {
  local pid=$1 secs=$2 i
  for ((i = 0; i < secs; i++)); do
    kill -0 "$pid" 2>/dev/null || return 0
    sleep 1
  done
  return 1
}

# ---------- QEMU ----------

qemu_args() {
  local mode=$1 console=$2
  ARGS=(-name winvm)
  case "$WINVM_GUEST_ARCH" in
    arm64)
      ARGS+=(
        -machine "virt,accel=hvf,highmem=on" -cpu host -smp "$CPUS" -m "$MEMORY"
        -drive "if=pflash,format=raw,readonly=on,file=$WINVM_QEMU_SHARE/edk2-aarch64-code.fd"
        -drive "if=pflash,format=raw,file=$S/efivars.fd"
        # ramfb, not virtio-gpu-pci: EDK2's virtio-gpu GOP is blt-only (framebuffer
        # base 0), and the Windows ARM64 boot manager writes straight to that base
        # and hangs on "starting Boot0001". ramfb gives a linear framebuffer.
        -device ramfb
        -device qemu-xhci -device usb-kbd -device usb-tablet
      )
      ;;
    amd64)
      ARGS+=(
        -machine "q35,accel=kvm"
        -cpu "host,hv_relaxed,hv_vapic,hv_spinlocks=0x1fff,hv_vpindex,hv_runtime,hv_time,hv_synic,hv_stimer,hv_frequencies,hv_tlbflush,hv_ipi"
        -smp "$CPUS" -m "$MEMORY"
        -drive "if=pflash,format=raw,readonly=on,file=$WINVM_QEMU_SHARE/edk2-x86_64-code.fd"
        -drive "if=pflash,format=raw,file=$S/efivars.fd"
        -device virtio-vga -device qemu-xhci -device usb-tablet
      )
      ;;
    *) die "unsupported WINVM_GUEST_ARCH: $WINVM_GUEST_ARCH" ;;
  esac
  ARGS+=(
    -drive "if=none,id=system,format=qcow2,cache=writeback,discard=unmap,detect-zeroes=unmap,file=$S/disk.qcow2"
    -device "nvme,drive=system,serial=WINVM0001,bootindex=1"
    -netdev "user,id=net0,hostfwd=tcp:127.0.0.1:$SSH_PORT-:22,hostfwd=tcp:127.0.0.1:$RDP_PORT-:3389,hostfwd=tcp:127.0.0.1:$GUEST_ST_PORT-:22000"
    -device "virtio-net-pci,netdev=net0"
    -monitor "unix:$S/monitor.sock,server,nowait" -pidfile "$S/qemu.pid"
  )
  if [ "$mode" = install ]; then
    if [ "$WINVM_GUEST_ARCH" = arm64 ]; then
      ARGS+=(
        -drive "if=none,id=installiso,format=raw,readonly=on,media=cdrom,file=$ISO" -device "usb-storage,drive=installiso,bootindex=2"
        -drive "if=none,id=setupiso,format=raw,readonly=on,media=cdrom,file=$S/setup.iso" -device "usb-storage,drive=setupiso"
      )
    else
      ARGS+=(
        -drive "if=none,id=installiso,media=cdrom,readonly=on,file=$ISO" -device "ide-cd,drive=installiso,bus=ide.0,bootindex=2"
        -drive "if=none,id=setupiso,media=cdrom,readonly=on,file=$S/setup.iso" -device "ide-cd,drive=setupiso,bus=ide.1"
      )
    fi
  fi
  if [ "$console" = 1 ]; then
    if [ "$WINVM_GUEST_ARCH" = arm64 ]; then
      ARGS+=(-display cocoa)
    else
      ARGS+=(-display gtk)
    fi
  else
    ARGS+=(-display none)
  fi
}

launch_qemu() {
  local mode=$1 console=$2 qemu i
  if [ "$WINVM_GUEST_ARCH" = arm64 ]; then
    qemu="qemu-system-aarch64"
  else
    qemu="qemu-system-x86_64"
  fi
  qemu_args "$mode" "$console"
  rm -f "$S/qemu.pid" "$S/monitor.sock"
  nohup "$qemu" "${ARGS[@]}" >"$S/qemu.log" 2>&1 &
  for ((i = 0; i < 10; i++)); do
    if vm_running; then
      return 0
    fi
    sleep 1
  done
  tail -n 20 "$S/qemu.log" >&2 || true
  die "qemu failed to start"
}

# ---------- Syncthing ----------

st_key() {
  sed -n 's|.*<apikey>\(.*\)</apikey>.*|\1|p' "$S/syncthing-host/config.xml" | sed -n 1p
}

st_api() {
  local path=$1 key
  shift
  key=$(st_key)
  curl -fsS "$@" -H "X-API-Key: $key" "http://127.0.0.1:$HOST_ST_GUI$path"
}

st_running() {
  [ -s "$S/syncthing.pid" ] && kill -0 "$(cat "$S/syncthing.pid")" 2>/dev/null
}

start_syncthing() {
  local i
  if ! st_running; then
    nohup syncthing serve --home "$S/syncthing-host" --no-browser --no-restart --no-upgrade >"$S/syncthing.log" 2>&1 &
    printf '%s\n' "$!" >"$S/syncthing.pid"
  fi
  for ((i = 0; i < 30; i++)); do
    if curl -fsS "http://127.0.0.1:$HOST_ST_GUI/rest/noauth/health" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  tail -n 20 "$S/syncthing.log" >&2 || true
  die "host syncthing did not become healthy"
}

stop_syncthing() {
  local pid
  [ -s "$S/syncthing.pid" ] || return 0
  pid=$(cat "$S/syncthing.pid")
  if kill -0 "$pid" 2>/dev/null; then
    st_api /rest/system/shutdown -X POST >/dev/null 2>&1 || true
    wait_exit "$pid" 10 || kill "$pid" 2>/dev/null || true
  fi
  rm -f "$S/syncthing.pid"
}

# render_folder <id> <path> <self-id> <peer-id>: one <folder> element on stdout.
render_folder() {
  local path
  path=$(sed_esc "$(xml_esc "$2")")
  sed -e "s|@FOLDER_ID@|$1|g" -e "s|@FOLDER_PATH@|$path|g" -e "s|@SELF_ID@|$3|g" -e "s|@PEER_ID@|$4|g" \
    "$WINVM_DATA/syncthing-folder.xml"
}

# render_st_config <home> <self-id> <peer-id> <folders.xml> <peer-addr> <gui-addr> <listen> <apikey>
render_st_config() {
  sed \
    -e "/@FOLDERS@/{r $4" -e 'd}' \
    -e "s|@VERSION@|$ST_VERSION|g" \
    -e "s|@SELF_ID@|$2|g" \
    -e "s|@PEER_ID@|$3|g" \
    -e "s|@PEER_ADDRESS@|$5|g" \
    -e "s|@GUI_ADDRESS@|$6|g" \
    -e "s|@LISTEN@|$7|g" \
    -e "s|@APIKEY@|$8|g" \
    "$WINVM_DATA/syncthing-config.xml" >"$1/config.xml"
}

# Both config.xml files from FOLDERS; folder id = basename, guest path C:\src\<basename>.
render_st_configs() {
  local f name t
  new_tmp
  t=$NEW_TMP
  : >"$t/host.xml"
  : >"$t/guest.xml"
  for f in "${FOLDERS[@]}"; do
    name=$(basename "$f")
    render_folder "$name" "$f" "$HOST_ST_ID" "$GUEST_ST_ID" >>"$t/host.xml"
    render_folder "$name" "C:\\src\\$name" "$GUEST_ST_ID" "$HOST_ST_ID" >>"$t/guest.xml"
  done
  render_st_config "$S/syncthing-host" "$HOST_ST_ID" "$GUEST_ST_ID" "$t/host.xml" \
    "tcp://127.0.0.1:$GUEST_ST_PORT" "127.0.0.1:$HOST_ST_GUI" "tcp://127.0.0.1:$HOST_ST_PORT" "$HOST_ST_KEY"
  render_st_config "$S/syncthing-guest" "$GUEST_ST_ID" "$HOST_ST_ID" "$t/guest.xml" \
    "tcp://10.0.2.2:$HOST_ST_PORT" "127.0.0.1:8384" "tcp://0.0.0.0:22000" "$GUEST_ST_KEY"
}

setup_syncthing() {
  rm -rf "$S/syncthing-host" "$S/syncthing-guest"
  syncthing generate --home "$S/syncthing-host" --no-port-probing >/dev/null
  syncthing generate --home "$S/syncthing-guest" --no-port-probing >/dev/null
  HOST_ST_ID=$(syncthing device-id --home "$S/syncthing-host")
  GUEST_ST_ID=$(syncthing device-id --home "$S/syncthing-guest")
  ST_VERSION=$(sed -n 's/.*<configuration version="\([0-9]*\)".*/\1/p' "$S/syncthing-host/config.xml" | sed -n 1p)
  [ -n "$ST_VERSION" ] || die "could not read syncthing config version"
  HOST_ST_KEY=$(rand 32)
  GUEST_ST_KEY=$(rand 32)
}

# Guest side of FOLDERS: C:\src\<name>\.stfolder plus each host folder's .stignore.
push_folders() {
  local f paths=""
  for f in "${FOLDERS[@]}"; do
    paths+="${paths:+,}'C:\\src\\$(basename "$f")\\.stfolder'"
  done
  gps "New-Item -ItemType Directory -Force -Path $paths | Out-Null"
  for f in "${FOLDERS[@]}"; do
    scp -F "$S/ssh_config" -q "$f/.stignore" "winvm:C:/src/$(basename "$f")/.stignore"
  done
}

# Push the guest config.xml and restart the guest instance (task registered by provision).
restart_guest_syncthing() {
  scp -F "$S/ssh_config" -q "$S/syncthing-guest/config.xml" "winvm:C:/winvm/syncthing-home/"
  gps "Stop-ScheduledTask -TaskName winvm-syncthing; Get-Process syncthing -ErrorAction SilentlyContinue | Stop-Process -Force; Start-ScheduledTask -TaskName winvm-syncthing"
}

# sync_wait <folder-id>: rescan, then wait until the guest has the folder complete.
sync_wait() {
  local id=$1 i connected comp
  require_vm
  st_api "/rest/db/scan?folder=$id" -X POST >/dev/null 2>&1 || true
  connected=false
  comp=0
  for ((i = 0; i < 300; i++)); do
    connected=$(st_api /rest/system/connections 2>/dev/null |
      jq -r --arg id "$GUEST_ST_ID" '.connections[$id].connected // false' 2>/dev/null) || connected=false
    comp=$(st_api "/rest/db/completion?folder=$id&device=$GUEST_ST_ID" 2>/dev/null |
      jq -r '.completion // 0' 2>/dev/null) || comp=0
    if [ "$connected" = true ] && jq -e -n --argjson c "${comp:-0}" '$c >= 100' >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  die "sync of $id did not settle in 300s (connected=$connected, completion=$comp)"
}

# ---------- lifecycle ----------

fetch_iso() {
  local got
  if [ -n "${WINVM_ISO:-}" ]; then
    [ -f "$WINVM_ISO" ] || die "WINVM_ISO not found: $WINVM_ISO"
    warn "using WINVM_ISO=$WINVM_ISO, skipping hash check"
    ISO=$WINVM_ISO
    return 0
  fi
  ISO="$C/$(basename "$WINVM_ISO_URL")"
  if [ -f "$ISO.ok" ] && [ -f "$ISO" ]; then
    return 0
  fi
  echo "downloading Windows ISO ($WINVM_ISO_SIZE bytes) to $ISO"
  curl -fL --retry 5 -C - -o "$ISO.part" "$WINVM_ISO_URL"
  got=$(sha256sum "$ISO.part")
  got=${got%% *}
  if [ "$got" != "$WINVM_ISO_SHA256" ]; then
    rm -f "$ISO.part"
    die "ISO sha256 mismatch: got $got, expected $WINVM_ISO_SHA256"
  fi
  mv "$ISO.part" "$ISO"
  touch "$ISO.ok"
}

build_setup_iso() {
  local pw
  pw=$(cat "$S/password")
  new_tmp
  local t=$NEW_TMP
  sed -e "s|@ARCH@|$WINVM_GUEST_ARCH|g" -e "s|@PASSWORD@|$pw|g" \
    "$WINVM_DATA/autounattend.xml" >"$t/autounattend.xml"
  cp -RL "$WINVM_DATA/drivers" "$t/drivers"
  mkdir "$t/winvm"
  cp "$WINVM_DATA/guest/bootstrap.cmd" "$WINVM_DATA/guest/bootstrap.ps1" "$t/winvm/"
  cp "$S/id_ed25519.pub" "$t/winvm/authorized_keys"
  chmod -R u+w "$t"
  xorriso -as mkisofs -quiet -J -joliet-long -r -V WINVM_SETUP -o "$S/setup.iso" "$t"
}

cmd_create() {
  local console=0 a avail pw i elapsed folders=()
  for a in "$@"; do
    case "$a" in
      --console) console=1 ;;
      -*) die "unknown option: $a" ;;
      *) folders+=("$a") ;;
    esac
  done
  [ "${#folders[@]}" -gt 0 ] || die "usage: winvm create <host-folder>... [--console]"
  [ ! -e "$S/disk.qcow2" ] || die "VM already exists at $S (winvm destroy --yes first)"
  for a in "${folders[@]}"; do
    resolve_folder "$a"
    FOLDERS+=("$RESOLVED")
  done
  mkdir -p "$S" "$C"
  chmod 700 "$S"
  avail=$(df -Pk "$S" | sed -n 2p | sed -e 's/  */ /g' | cut -d' ' -f4)
  [ "${avail:-0}" -ge $((40 * 1024 * 1024)) ] || die "need at least 40 GiB free on $S"

  if [ "$(uname -s)" = Darwin ]; then
    tmutil addexclusion "$S" "$C" >/dev/null 2>&1 || true
  fi

  fetch_iso

  rm -f "$S/id_ed25519" "$S/id_ed25519.pub" "$S/known_hosts"
  ssh-keygen -q -t ed25519 -N '' -C winvm -f "$S/id_ed25519"
  pw=$(rand 20)
  (umask 077 && printf '%s\n' "$pw" >"$S/password")
  cat >"$S/ssh_config" <<EOF
Host winvm
  HostName 127.0.0.1
  Port $SSH_PORT
  User dev
  IdentityFile $S/id_ed25519
  IdentitiesOnly yes
  UserKnownHostsFile $S/known_hosts
  StrictHostKeyChecking accept-new
  ServerAliveInterval 15
  LogLevel ERROR
EOF

  setup_syncthing
  for a in "${FOLDERS[@]}"; do
    init_folder "$a"
  done
  render_st_configs
  save_config

  build_setup_iso

  qemu-img create -q -f qcow2 "$S/disk.qcow2" 128G
  if [ "$WINVM_GUEST_ARCH" = arm64 ]; then
    cp "$WINVM_QEMU_SHARE/edk2-arm-vars.fd" "$S/efivars.fd"
  else
    cp "$WINVM_QEMU_SHARE/edk2-i386-vars.fd" "$S/efivars.fd"
  fi
  chmod 644 "$S/efivars.fd"

  echo "starting unattended install (this takes a while)"
  launch_qemu install "$console"
  # Pass the CD's "Press any key to boot from CD or DVD". Down, not Enter: Setup's
  # first focused control is the Cancel button, which Enter would press.
  for ((i = 0; i < 60; i++)); do
    hmp 'sendkey down' || true
    sleep 1
  done
  for ((i = 0; i < 300; i++)); do
    if ssh -F "$S/ssh_config" -o ConnectTimeout=5 -o BatchMode=yes winvm \
      'if (Test-Path C:\winvm\bootstrap.done) {exit 0} else {exit 1}' >/dev/null 2>&1; then
      break
    fi
    vm_running || die "qemu exited during install; see $S/qemu.log"
    if [ "$i" -gt 0 ] && [ $((i % 20)) -eq 0 ]; then
      elapsed=$((i * 30 / 60))
      echo "install running for ${elapsed} min; inspect with: winvm screenshot"
    fi
    sleep 30
  done
  if [ "$i" -ge 300 ]; then
    die "install timed out after 150 min; check C:\\winvm\\bootstrap.log in the guest and run: winvm screenshot"
  fi
  echo "guest bootstrap finished"

  do_provision stay
  cmd_down
  rm -f "$S/setup.iso"
  cmd_up

  cat <<EOF

winvm is ready.
  winvm ssh                       PowerShell in the guest
  winvm exec 'node -p process.arch'   run a command in the synced folder you are in
  winvm prepare / winvm build     install deps / build vector-client (vector repo)
  winvm gui pnpm tauri:dev        run the app on the guest desktop
  winvm sync add <folder>         sync another project
  winvm rdp                       view the desktop
Guest user: dev, password in $S/password
EOF
  cmd_sync_list
}

cmd_up() {
  local console=0 a i
  for a in "$@"; do
    case "$a" in
      --console) console=1 ;;
      *) die "unknown option: $a" ;;
    esac
  done
  if vm_running; then
    load_config
    start_syncthing
    push_folders || warn "could not push synced folders' .stignore to the guest"
    echo "already running"
    return 0
  fi
  [ -e "$S/disk.qcow2" ] || die "no VM; run winvm create <folder>..."
  load_config
  launch_qemu run "$console"
  start_syncthing
  for ((i = 0; i < 100; i++)); do
    if ssh_probe; then
      break
    fi
    sleep 3
  done
  [ "$i" -lt 100 ] || die "SSH did not come up within 5 min (winvm screenshot)"
  push_folders || warn "could not push synced folders' .stignore to the guest"
  echo ready
}

cmd_down() {
  local pid
  if vm_running; then
    pid=$(cat "$S/qemu.pid")
    ssh -F "$S/ssh_config" -o ConnectTimeout=10 -o BatchMode=yes winvm 'Stop-Computer -Force' >/dev/null 2>&1 || true
    if ! wait_exit "$pid" 180; then
      hmp system_powerdown || true
      if ! wait_exit "$pid" 60; then
        kill "$pid" 2>/dev/null || true
        wait_exit "$pid" 10 || true
      fi
    fi
  fi
  if [ -f "$S/config" ]; then
    stop_syncthing
  fi
}

cmd_status() {
  local conn f name state need comp ssh_ok=no
  if vm_running; then
    echo "vm:   running (pid $(cat "$S/qemu.pid"))"
    if ssh_probe; then ssh_ok=yes; fi
  else
    echo "vm:   stopped"
  fi
  echo "ssh:  $ssh_ok"
  if [ -f "$S/config" ]; then
    load_config
    conn=$(st_api /rest/system/connections 2>/dev/null |
      jq -r --arg id "$GUEST_ST_ID" '.connections[$id].connected // false' 2>/dev/null) || conn=unknown
    echo "sync: connected=${conn:-unknown}"
    for f in "${FOLDERS[@]}"; do
      name=$(basename "$f")
      state=$(st_api "/rest/db/status?folder=$name" 2>/dev/null | jq -r '.state' 2>/dev/null) || state=unknown
      need=$(st_api "/rest/db/status?folder=$name" 2>/dev/null | jq -r '.needFiles' 2>/dev/null) || need=unknown
      comp=$(st_api "/rest/db/completion?folder=$name&device=$GUEST_ST_ID" 2>/dev/null |
        jq -r '.completion' 2>/dev/null) || comp=unknown
      echo "  $name: state=${state:-unknown} needFiles=${need:-unknown} completion=${comp:-unknown}"
    done
  else
    echo "sync: no VM configured"
  fi
  return 0
}

cmd_screenshot() {
  local out=${1:-$S/screen.png}
  require_vm
  out=$(realpath -m "$out")
  rm -f "$out"
  # QEMU 11 HMP syntax is `screendump <file> [-f format]`; without -f the file is a PPM.
  hmp "screendump $out -f png"
  [ -s "$out" ] || die "screendump failed ($out not written)"
  echo "$out"
}

cmd_destroy() {
  [ "${1:-}" = "--yes" ] || die "destroy deletes the VM and all state; pass --yes"
  cmd_down
  if [ -f "$S/config" ]; then
    load_config
    echo "leaving .stignore/.stfolder in: ${FOLDERS[*]}"
  fi
  rm -rf "$S"
  echo "destroyed $S (ISO cache $C kept)"
}

# ---------- provisioning ----------

do_provision() {
  local mode=$1 tok rc=0
  load_config
  require_vm
  gssh 'New-Item -ItemType Directory -Force C:\winvm\syncthing-home | Out-Null'
  new_tmp
  local t=$NEW_TMP
  cp -RL "$WINVM_DATA/guest/." "$t/"
  chmod -R u+w "$t"
  scp -F "$S/ssh_config" -q -r "$t"/* "winvm:C:/winvm/"
  scp -F "$S/ssh_config" -q "$S/syncthing-guest/cert.pem" "$S/syncthing-guest/key.pem" \
    "$S/syncthing-guest/config.xml" "winvm:C:/winvm/syncthing-home/"
  push_folders
  if command -v gh >/dev/null 2>&1 && gh auth token >/dev/null 2>&1; then
    tok=$(mktemp)
    chmod 600 "$tok"
    gh auth token >"$tok"
    scp -F "$S/ssh_config" -q "$tok" "winvm:C:/winvm/gh-token" || rc=$?
    rm -f "$tok"
    [ "$rc" -eq 0 ] || die "failed to copy gh token to guest"
  else
    warn "gh not logged in on host; private cargo deps will fail until you re-run winvm provision"
  fi
  rc=0
  gps "& C:\\winvm\\provision.ps1" || rc=$?
  case "$rc" in
    0) ;;
    10)
      if [ "$mode" = reboot ]; then
        echo "reboot required; restarting VM"
        cmd_down
        cmd_up
      fi
      ;;
    *) die "provision failed (exit $rc); see C:\\winvm\\provision.log in the guest" ;;
  esac
}

cmd_provision() {
  do_provision reboot
}

# ---------- dev loop ----------

cmd_ssh() {
  require_vm
  exec ssh -F "$S/ssh_config" winvm "$@"
}

# run_in_project <ps-command>: sync the selected project, then run the command in
# its guest cwd. select_project must have run.
run_in_project() {
  local tty=()
  sync_wait "$PROJ_NAME"
  if [ -t 0 ] && [ -t 1 ]; then tty=(-t); fi
  exec ssh -F "$S/ssh_config" "${tty[@]}" winvm \
    "$PS_INIT; [Console]::OutputEncoding=[Text.Encoding]::UTF8; Set-Location $(ps_quote "$PROJ_CWD"); $1; $PS_EXIT"
}

cmd_exec() {
  if [ "${1:-}" = "--" ]; then shift; fi
  [ $# -gt 0 ] || die "usage: winvm exec <ps-command...>"
  load_config
  select_project
  run_in_project "$*"
}

gui_abort() {
  gps '& C:\winvm\gui-stop.ps1' || true
  exit 130
}

cmd_gui() {
  local b64 rc=0
  [ $# -gt 0 ] || die "usage: winvm gui <ps-command...>"
  load_config
  select_project
  sync_wait "$PROJ_NAME"
  b64=$(printf %s "$*" | base64 -w0)
  gps "& C:\\winvm\\gui-start.ps1 -CommandBase64 '$b64' -Cwd $(ps_quote "$PROJ_CWD")" || rc=$?
  if [ "$rc" -eq 2 ]; then
    die "a gui command is already running; winvm gui-stop"
  elif [ "$rc" -ne 0 ]; then
    die "gui-start failed (exit $rc)"
  fi
  trap gui_abort INT TERM
  rc=0
  gps '& C:\winvm\gui-tail.ps1' || rc=$?
  trap - INT TERM
  exit "$rc"
}

cmd_gui_stop() {
  require_vm
  gps '& C:\winvm\gui-stop.ps1'
}

# prepare/build are vector-specific: they run against the vector repo root.
cmd_prepare() {
  load_config
  select_project
  run_in_project "& C:\\winvm\\prepare.ps1 -Root $(ps_quote "$PROJ_ROOT")"
}

cmd_build() {
  local stage=${1:-local}
  case "$stage" in
    local | dev | test | prod) ;;
    *) die "stage must be one of: local dev test prod" ;;
  esac
  load_config
  select_project
  run_in_project "& C:\\winvm\\build.ps1 -Root $(ps_quote "$PROJ_ROOT") -Stage $stage"
}

# ---------- synced folders ----------

cmd_sync_list() {
  local f
  load_config
  for f in "${FOLDERS[@]}"; do
    printf '%s\t%s  <->  C:\\src\\%s\n' "$(basename "$f")" "$f" "$(basename "$f")"
  done
}

# Apply a changed FOLDERS: re-render both configs, push the guest side, restart both.
apply_folders() {
  save_config
  render_st_configs
  push_folders
  restart_guest_syncthing
  stop_syncthing
  start_syncthing
}

cmd_sync_add() {
  [ $# -eq 1 ] || die "usage: winvm sync add <host-folder>"
  load_config
  require_vm
  resolve_folder "$1"
  init_folder "$RESOLVED"
  FOLDERS+=("$RESOLVED")
  apply_folders
  echo "syncing $RESOLVED <-> C:\\src\\$(basename "$RESOLVED")"
}

cmd_sync_remove() {
  local f kept=() found=""
  [ $# -eq 1 ] || die "usage: winvm sync remove <name>"
  load_config
  require_vm
  for f in "${FOLDERS[@]}"; do
    if [ "$(basename "$f")" = "$1" ]; then found=$f; else kept+=("$f"); fi
  done
  [ -n "$found" ] || die "no synced folder named $1 (winvm sync list)"
  [ "${#kept[@]}" -gt 0 ] || die "cannot remove the last synced folder"
  FOLDERS=("${kept[@]}")
  apply_folders
  echo "stopped syncing $found (files stay on both sides, guest copy in C:\\src\\$1)"
}

cmd_sync() {
  local sub=${1:-list}
  [ $# -eq 0 ] || shift
  case "$sub" in
    list) cmd_sync_list ;;
    add) cmd_sync_add "$@" ;;
    remove) cmd_sync_remove "$@" ;;
    *) die "usage: winvm sync [list | add <host-folder> | remove <name>]" ;;
  esac
}

cmd_rdp() {
  local pw
  require_vm
  pw=$(cat "$S/password")
  if [ "$(uname -s)" = Darwin ]; then
    cat >"$S/winvm.rdp" <<EOF
full address:s:127.0.0.1:$RDP_PORT
username:s:dev
prompt for credentials:i:0
authentication level:i:0
dynamic resolution:i:1
screen mode id:i:1
redirectclipboard:i:1
audiomode:i:0
EOF
    printf '%s' "$pw" | pbcopy
    echo "password copied to clipboard"
    open -a "Windows App" "$S/winvm.rdp" || die "install Windows App from the Mac App Store"
  else
    nohup xfreerdp "/v:127.0.0.1:$RDP_PORT" /u:dev "/p:$pw" /cert:ignore /dynamic-resolution +clipboard /sound >/dev/null 2>&1 &
  fi
}

# ---------- dispatch ----------

cmd=${1:-help}
[ $# -eq 0 ] || shift
case "$cmd" in
  help | -h | --help) usage ;;
  create) cmd_create "$@" ;;
  up) cmd_up "$@" ;;
  down) cmd_down ;;
  status) cmd_status ;;
  screenshot) cmd_screenshot "$@" ;;
  destroy) cmd_destroy "$@" ;;
  provision) cmd_provision ;;
  ssh) cmd_ssh "$@" ;;
  exec) cmd_exec "$@" ;;
  sync) cmd_sync "$@" ;;
  gui) cmd_gui "$@" ;;
  gui-stop) cmd_gui_stop ;;
  prepare) cmd_prepare ;;
  build) cmd_build "$@" ;;
  rdp) cmd_rdp ;;
  *)
    usage >&2
    die "unknown command: $cmd"
    ;;
esac

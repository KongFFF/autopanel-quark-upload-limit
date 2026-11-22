#!/usr/bin/env bash
set -Eeuo pipefail
ORIG=/usr/bin/autopanel
BACKUP=/root/autopanel-backup/autopanel.original
SOCK=unix:///tmp/supervisor.sock
OLD=fd3a94c9c0173df78b62703f26946559793e9a43365b335df57e0c270f8e16ed
NEW=0c5add05dba0575411b3c8f43812e194c4c7ef3ea1003a8b36a6a196ad05547d
PATCH=${2:-/root/autopanel-test16g/autopanel.unpacked}
ctl(){ supervisorctl -s "$SOCK" "$@"; }
is_running(){ [[ ${1,,} =~ ^autopanel[[:space:]]+running([[:space:]]|$) ]]; }
hash(){ sha256sum "$1" | awk '{print $1}'; }
fail(){ echo "ERROR: $*" >&2; exit 1; }
replace(){ local tmp; tmp=$(mktemp /usr/bin/.autopanel.XXXXXX); if ! cp -a "$1" "$tmp" || ! chmod 755 "$tmp" || ! mv -fT "$tmp" "$ORIG"; then rm -f "$tmp"; return 1; fi; }
[[ $EUID == 0 ]] || fail 'Run as root.'
[[ -f $ORIG && ! -L $ORIG ]] || fail 'Unexpected executable path.'
[[ -S /tmp/supervisor.sock ]] || fail 'Supervisor socket unavailable.'
current=$(hash "$ORIG")
case ${1:-} in
 install)
  [[ $current != "$NEW" ]] || { echo 'Already installed.'; ctl status autopanel; exit 0; }
  [[ $current == "$OLD" ]] || fail 'Unknown AutoPanel version; refusing replacement.'
  [[ -f $PATCH && $(hash "$PATCH") == "$NEW" ]] || fail 'Patch missing or checksum mismatch.'
  [[ $(uname -m) == x86_64 ]] || fail 'Architecture mismatch.'
  deps=$(ldd "$PATCH") || fail 'Dependency check failed.'
  [[ $deps != *'not found'* ]] || fail 'Missing libraries.'
  mkdir -p "$(dirname "$BACKUP")"
  if [[ ! -e $BACKUP ]]; then cp -a "$ORIG" "$BACKUP"; fi
  [[ -f $BACKUP && $(hash "$BACKUP") == "$OLD" ]] || fail 'Backup checksum mismatch.'
  source_file=$PATCH; expected=$NEW; fallback=$BACKUP; fallback_hash=$OLD
  ;;
 rollback)
  [[ $current != "$OLD" ]] || { echo 'Original already installed.'; ctl status autopanel; exit 0; }
  [[ $current == "$NEW" ]] || fail 'Unknown installed version; refusing rollback.'
  [[ -f $BACKUP && $(hash "$BACKUP") == "$OLD" ]] || fail 'Backup missing or invalid.'
  source_file=$BACKUP; expected=$OLD; fallback=; fallback_hash=
  ;;
 *) fail 'Usage: bash autopanel-fix.sh install [patch-path] | rollback';;
esac
state=$(ctl status autopanel) || fail 'Cannot query running service.'
is_running "$state" || fail 'Service not RUNNING; inspect manually.'
echo 'Use independent SSH. Ensure no active tasks. Service will restart.'
read -r -p 'Type YES to continue: ' answer
[[ $answer == YES ]] || fail 'Cancelled.'
recover(){
  trap - ERR
  echo 'Switch failed; attempting recovery.' >&2
  ctl stop autopanel || true
  if [[ -n $fallback ]]; then
    replace "$fallback" || { echo 'Restore failed; use backup manually.' >&2; exit 1; }
    [[ $(hash "$ORIG") == "$fallback_hash" ]] || exit 1
  fi
  ctl start autopanel || true
  ctl status autopanel || true
  exit 1
}
trap recover ERR
ctl stop autopanel
replace "$source_file"
[[ $(hash "$ORIG") == "$expected" ]]
ctl start autopanel
sleep 3
state=$(ctl status autopanel)
is_running "$state"
pid=$(ctl pid autopanel)
[[ $pid =~ ^[1-9][0-9]*$ ]]
[[ $(hash /proc/"$pid"/exe) == "$expected" ]]
trap - ERR
echo "$state"
echo 'Executable checksum verified. Check web UI and upload behavior.'

#!/bin/sh
# Stub sing-box CLI for smoke tests.
case "$1" in
  check)
    cfg="$3"
    if [ -f "$cfg" ] && python3 -c "import json,sys;json.load(open(sys.argv[1]))" "$cfg" 2>/dev/null; then
      exit 0
    fi
    echo "invalid config" >&2
    exit 1
    ;;
  version)
    echo "sing-box version 1.10.0-mock"
    ;;
  generate)
    case "$2" in
      uuid) echo "11111111-1111-1111-1111-111111111111" ;;
      reality-keypair) printf "PrivateKey: REALPRIV\nPublicKey: REALPUB\n" ;;
      wireguard-keypair) printf "PrivateKey: WGPRIV\nPublicKey: WGPUB\n" ;;
      tls-keypair) printf "-----BEGIN PRIVATE KEY-----\nK\n-----END PRIVATE KEY-----\n-----BEGIN CERTIFICATE-----\nC\n-----END CERTIFICATE-----\n" ;;
    esac
    ;;
esac

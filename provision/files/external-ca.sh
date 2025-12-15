#!/bin/bash
set -euo pipefail

script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
provision_dir="$(cd "${script_root}/.." && pwd)"

master="${1:-}"
domain="${2:-}"

usage() {
  cat <<EOF
Usage: $0 master-fqdn domain
EOF
}

if [ -z "$master" ]; then
  echo "ERROR: master is not set"
  usage
  exit 1
fi

if [ -z "$domain" ]; then
  echo "ERROR: domain is not set"
  usage
  exit 1
fi

if [[ "$master" != *".${domain}" ]]; then
  echo "WARNING: master (${master}) does not look like it belongs to domain ${domain}"
fi

csr_file="${provision_dir}/${master}-ipa.csr"
if [ ! -f "$csr_file" ]; then
  echo "ERROR: ${csr_file} not found"
  exit 1
fi

root_ca_key="${script_root}/rootCA.key"
root_ca_crt="${script_root}/rootCA.crt"
ipa_conf="${script_root}/ipa.cnf"

for required in "$root_ca_key" "$root_ca_crt" "$ipa_conf"; do
  if [ ! -f "$required" ]; then
    echo "ERROR: required file ${required} is missing"
    exit 1
  fi
done

signed_cert="${provision_dir}/${master}-ipa.crt"
chain_file="${provision_dir}/${master}-chain.crt"

openssl x509 -req \
  -in "$csr_file" \
  -CA "$root_ca_crt" \
  -CAkey "$root_ca_key" \
  -out "$signed_cert" \
  -days 1825 \
  -sha256 \
  -extfile "$ipa_conf" \
  -extensions req_ext

cat "$signed_cert" "$root_ca_crt" > "$chain_file"

echo "Signed ${csr_file} with ${root_ca_crt} and produced ${signed_cert} and ${chain_file}"
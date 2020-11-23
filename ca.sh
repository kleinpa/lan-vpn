#!/bin/bash -ue
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

usage() {
    cat << EOF
Commands:
   init           make a new ca and generate server config
   backup         saves backup to a timestamped file
   restore        restores backup from the specified file
   make-server    generate a new server certificate and export a config file
   make-client    generate a new client certificate and export a config file
EOF
}

export EASYRSA_PKI=${ca_path}/pki
BACKUP_DIR=${ca_path}/backup
CONFIG_DIR=${ca_path}/config

tool_run() {
    target=$1
    shift
    (cd ${tools_workspace} && bazel run ${target} -- "$@")
}

openvpn="tool_run @com_github_openvpn_openvpn//:openvpn"
easyrsa="tool_run @com_github_openvpn_easyrsa//:easyrsa"

cmd_init() {
    ${easyrsa} init-pki
    ${easyrsa} build-ca

    ${openvpn} --genkey secret ${EASYRSA_PKI}/private/tls-auth.key
}

build_server() {
    name=$1

    if [ -e ${EASYRSA_PKI}/issued/${name}.crt ]; then
        echo "Certificate for ${name} already exists"
    else
        ${easyrsa} build-server-full ${name} nopass
        backup
    fi
}

build_client() {
    name=$1

    if [ -e ${EASYRSA_PKI}/issued/${name}.crt ]; then
        echo "Certificate for ${name} already exists"
    else
        ${easyrsa} build-client-full ${name} nopass
        backup
    fi
}

include_file() {
    if [ ! -r $2 ]; then echo "Can not find file $2" >&2; return 1 ; fi
    printf "\n<%s>\n%s\n</%s>\n" "${1}" "$(cat ${2})" "${1}"
}

genconfig_client() {
    name=$1

    cat client.template.conf

    include_file key "${EASYRSA_PKI}/private/${name}.key"
    include_file cert "${EASYRSA_PKI}/issued/${name}.crt"
    include_file ca "${EASYRSA_PKI}/ca.crt"
    include_file tls-crypt "${EASYRSA_PKI}/private/tls-auth.key"
}

genconfig_server() {
    name=$1

    cat server.template.conf

    include_file key "${EASYRSA_PKI}/private/${name}.key"
    include_file cert "${EASYRSA_PKI}/issued/${name}.crt"
    include_file ca "${EASYRSA_PKI}/ca.crt"
    include_file tls-crypt "${EASYRSA_PKI}/private/tls-auth.key"
}

backup() {
    mkdir -p backup
    BACKUP_FILE="backup-pki-$(date '+%Y-%m-%dT%H%M%S').tar.gz"
    GZIP=-n tar czf "${BACKUP_DIR}/${BACKUP_FILE}" -C "${EASYRSA_PKI}" .
    ln -fs "${BACKUP_DIR}/${BACKUP_FILE}" "${BACKUP_DIR}/latest.tar.gz"
    echo "Saved pki to ${BACKUP_FILE}"
}

CMD="${1-}"
[ -n "${1-}" ] && shift
case "${CMD}" in
    init)
        cmd_init
        ;;
    backup)
        backup
        ;;
    restore)
        rm -rf "${EASYRSA_PKI}"
        mkdir -p "${EASYRSA_PKI}"
        tar xvf $1 -C "${EASYRSA_PKI}"
        ;;
    make-client)
        name=$1
        build_client "${name}"
        mkdir -p "${CONFIG_DIR}"
        genconfig_client "${name}" > "${CONFIG_DIR}/tmp" && mkdir -p "${CONFIG_DIR}/${name}" && mv "${CONFIG_DIR}/tmp" "${CONFIG_DIR}/${name}/${network_name}.conf"
        echo "Wrote config file ${CONFIG_DIR}/${name}/${network_name}.conf"
        ;;
    make-server)
        name=server
        build_server "${name}"
        mkdir -p "${CONFIG_DIR}"
        genconfig_server "${name}" > "${CONFIG_DIR}/tmp" && mv "${CONFIG_DIR}/tmp" "${CONFIG_DIR}/${name}.conf"
        echo "Wrote config file ${CONFIG_DIR}/${name}.conf"
        ;;
    easyrsa)
        ${easyrsa} "${@:2}"
        ;;
    *) usage
esac

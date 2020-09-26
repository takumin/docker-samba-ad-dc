#!/bin/sh
# vim: set noet :

set -eu

##############################################################################
# Default
##############################################################################

if [ -z "${SAMBA_UID:-}" ]; then
	SAMBA_UID=1000
fi
if [ -z "${SAMBA_GID:-}" ]; then
	SAMBA_GID=1000
fi

if [ -z "${SAMBA_DEBUG_LEVEL:-}" ]; then
	SAMBA_DEBUG_LEVEL=1
fi
if [ -z "${SAMBA_PROCESS_MODEL:-}" ]; then
	SAMBA_PROCESS_MODEL="prefork"
fi
if [ -z "${SAMBA_OPTION_PREFORK_CHILDREN:-}" ]; then
	SAMBA_OPTION_PREFORK_CHILDREN=4
fi

if [ -z "${SAMBA_AD_DNS_BACKEND:-}" ]; then
	SAMBA_AD_DNS_BACKEND="SAMBA_INTERNAL"
fi
if [ -z "${SAMBA_AD_DOMAIN:-}" ]; then
	SAMBA_AD_DOMAIN="DS.INTERNAL"
fi
if [ -z "${SAMBA_AD_NETBIOS_DOMAIN:-}" ]; then
	SAMBA_AD_NETBIOS_DOMAIN="DS"
fi
if [ -z "${SAMBA_AD_ADMIN_PASSWD:-}" ]; then
	SAMBA_AD_ADMIN_PASSWD="P@ssw0rd!"
fi

if [ -z "${TZ:-}" ]; then
	TZ="UTC"
fi

##############################################################################
# Check
##############################################################################

if echo "${SAMBA_UID}" | grep -Eqsv '^[0-9]+$'; then
	echo "SAMBA_UID: '${SAMBA_UID}'"
	echo 'Please numric value: SAMBA_UID'
	exit 1
fi
if [ "${SAMBA_UID}" -le 0 ]; then
	echo "SAMBA_UID: '${SAMBA_UID}'"
	echo 'Please 0 or more: SAMBA_UID'
	exit 1
fi
if [ "${SAMBA_UID}" -ge 60000 ]; then
	echo "SAMBA_UID: '${SAMBA_UID}'"
	echo 'Please 60000 or less: SAMBA_UID'
	exit 1
fi

if echo "${SAMBA_GID}" | grep -Eqsv '^[0-9]+$'; then
	echo "SAMBA_GID: '${SAMBA_GID}'"
	echo 'Please numric value: SAMBA_GID'
	exit 1
fi
if [ "${SAMBA_GID}" -le 0 ]; then
	echo "SAMBA_GID: '${SAMBA_GID}'"
	echo 'Please 0 or more: SAMBA_GID'
	exit 1
fi
if [ "${SAMBA_GID}" -ge 60000 ]; then
	echo "SAMBA_GID: '${SAMBA_GID}'"
	echo 'Please 60000 or less: SAMBA_GID'
	exit 1
fi

if echo "${SAMBA_DEBUG_LEVEL}" | grep -Eqsv '^[0-9]+$'; then
	echo "SAMBA_DEBUG_LEVEL: '${SAMBA_DEBUG_LEVEL}'"
	echo 'Please numric value: SAMBA_DEBUG_LEVEL'
	exit 1
fi
if [ "${SAMBA_DEBUG_LEVEL}" -lt 0 ] || [ "${SAMBA_DEBUG_LEVEL}" -gt 10 ]; then
	echo "SAMBA_DEBUG_LEVEL: '${SAMBA_DEBUG_LEVEL}'"
	echo 'Please 0 to 10: SAMBA_DEBUG_LEVEL'
	exit 1
fi

if echo "${SAMBA_PROCESS_MODEL}" | grep -Eqsv '^(single|standard|prefork)$'; then
	echo "SAMBA_PROCESS_MODEL: '${SAMBA_PROCESS_MODEL}'"
	echo 'Please single or standard or prefork: SAMBA_PROCESS_MODEL'
	exit 1
fi

if echo "${SAMBA_OPTION_PREFORK_CHILDREN}" | grep -Eqsv '^[0-9]+$'; then
	echo "SAMBA_OPTION_PREFORK_CHILDREN: '${SAMBA_OPTION_PREFORK_CHILDREN}'"
	echo 'Please numric value: SAMBA_OPTION_PREFORK_CHILDREN'
	exit 1
fi
if [ "${SAMBA_OPTION_PREFORK_CHILDREN}" -le 0 ]; then
	echo "SAMBA_OPTION_PREFORK_CHILDREN: '${SAMBA_OPTION_PREFORK_CHILDREN}'"
	echo 'Please 0 or more: SAMBA_OPTION_PREFORK_CHILDREN'
	exit 1
fi
if [ "${SAMBA_OPTION_PREFORK_CHILDREN}" -ge 256 ]; then
	echo "SAMBA_OPTION_PREFORK_CHILDREN: '${SAMBA_OPTION_PREFORK_CHILDREN}'"
	echo 'Please 256 or less: SAMBA_OPTION_PREFORK_CHILDREN'
	exit 1
fi

if echo "${SAMBA_AD_DOMAIN}" | grep -Eqsv '^[0-9a-zA-Z\.]+$'; then
	echo "SAMBA_AD_DOMAIN: '${SAMBA_AD_DOMAIN}'"
	echo 'Please [0-9a-zA-Z\.]+ value: SAMBA_AD_DOMAIN'
	exit 1
fi

if echo "${SAMBA_AD_NETBIOS_DOMAIN}" | grep -Eqsv '^[0-9a-zA-Z]+$'; then
	echo "SAMBA_AD_NETBIOS_DOMAIN: '${SAMBA_AD_NETBIOS_DOMAIN}'"
	echo 'Please [0-9a-zA-Z]+ value: SAMBA_AD_NETBIOS_DOMAIN'
	exit 1
fi

if [ ! -f "/usr/share/zoneinfo/${TZ}" ]; then
	echo "TZ: '${TZ}'"
	echo 'Not Found Timezone: TZ'
	exit 1
fi

##############################################################################
# Clear
##############################################################################

if getent passwd | awk -F ':' -- '{print $1}' | grep -Eqs '^samba$'; then
	deluser 'samba'
fi
if getent passwd | awk -F ':' -- '{print $3}' | grep -Eqs "^${SAMBA_UID}$"; then
	deluser "${SAMBA_UID}"
fi
if getent group | awk -F ':' -- '{print $1}' | grep -Eqs '^samba$'; then
	delgroup 'samba'
fi
if getent group | awk -F ':' -- '{print $3}' | grep -Eqs "^${SAMBA_GID}$"; then
	delgroup "${SAMBA_GID}"
fi

##############################################################################
# Group
##############################################################################

addgroup -g "${SAMBA_GID}" 'samba'

##############################################################################
# User
##############################################################################

adduser -h '/nonexistent' \
	-g 'samba,,,' \
	-s '/usr/sbin/nologin' \
	-G 'samba' \
	-D \
	-H \
	-u "${SAMBA_UID}" \
	'samba'

##############################################################################
# Timezone
##############################################################################

ln -fs "/usr/share/zoneinfo/${TZ}" "/etc/localtime"
echo "${TZ}" > "/etc/timezone"

##############################################################################
# Initialize
##############################################################################

if [ ! -d "/etc/samba" ]; then
	mkdir -p "/etc/samba"
fi

if [ ! -d "/run/samba" ]; then
	mkdir -p "/run/samba"
fi

if [ ! -d "/var/cache/samba" ]; then
	mkdir -p "/var/cache/samba"
fi

if [ ! -d "/var/lib/samba" ]; then
	mkdir -p "/var/lib/samba"
fi

if [ ! -f "/etc/samba/smb.conf" ]; then
	samba-tool domain provision \
		--server-role=dc \
		--dns-backend="${SAMBA_AD_DNS_BACKEND}" \
		--realm="${SAMBA_AD_DOMAIN}" \
		--domain="${SAMBA_AD_NETBIOS_DOMAIN}" \
		--adminpass="${SAMBA_AD_ADMIN_PASSWD}" \
		--use-rfc2307 \
		--debuglevel=${SAMBA_DEBUG_LEVEL} \
		--option='interfaces = lo eth0' \
		--option='bind interfaces only = yes' \
		--option='vfs objects = acl_tdb'

	# Enable Insecure LDAP Protocol
	sed -i -E 's@^(\[global\])$@\1\n        ldap server require strong auth = no@' '/etc/samba/smb.conf'
fi

##############################################################################
# Daemon
##############################################################################

cat > /etc/resolv.conf <<- __EOF__
search $(echo "${SAMBA_AD_DOMAIN}" | tr '[:upper:]' '[:lower:]')
nameserver 127.0.0.1
options timeout:1
__EOF__

SERV_OPTS="--foreground"
SERV_OPTS="${SERV_OPTS} --interactive"
SERV_OPTS="${SERV_OPTS} --debuglevel=${SAMBA_DEBUG_LEVEL}"
SERV_OPTS="${SERV_OPTS} --debug-stderr"
SERV_OPTS="${SERV_OPTS} --model=${SAMBA_PROCESS_MODEL}"
SERV_OPTS="${SERV_OPTS} --option='prefork children = ${SAMBA_OPTION_PREFORK_CHILDREN}'"

mkdir -p /etc/sv/samba
cat > /etc/sv/samba/run <<- __EOF__
#!/bin/sh
set -e
exec 2>&1
exec /usr/sbin/samba ${SERV_OPTS}
__EOF__
chmod 0755 /etc/sv/samba/run

##############################################################################
# Service
##############################################################################

ln -s /etc/sv/samba /etc/service/samba

##############################################################################
# Parameter
##############################################################################

echo 'Parameter'
echo "SAMBA_UID:                     '${SAMBA_UID}'"
echo "SAMBA_GID:                     '${SAMBA_GID}'"
echo "SAMBA_DEBUG_LEVEL:             '${SAMBA_DEBUG_LEVEL}'"
echo "SAMBA_PROCESS_MODEL:           '${SAMBA_PROCESS_MODEL}'"
echo "SAMBA_OPTION_PREFORK_CHILDREN: '${SAMBA_OPTION_PREFORK_CHILDREN}'"
echo ''

##############################################################################
# Running
##############################################################################

if [ "$1" = 'samba-ad-dc' ]; then
	echo 'Starting Server'
	exec runsvdir /etc/service
fi

exec "$@"

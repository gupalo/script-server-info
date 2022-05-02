#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
[[ -z "${VERBOSE}" ]] && VERBOSE="1"
OUTPUT="/dev/null"
if [[ "${VERBOSE}" == "1" ]]; then
    OUTPUT="/dev/null"
fi
if [[ "${VERBOSE}" == "2" ]]; then
    OUTPUT="/dev/stdout"
fi
TIME_START="$(date +%s)"
DATADIR="${DIR}/data"

function init {

    mkdir -p ${DATADIR}
    rm -rf ${DATADIR}/*
}

function log {
    echo "[$(date -u +"%Y-%m-%d %H:%M:%S")] $@" >&2
    echo "[$(date -u -Iseconds)] $@" >> ${DATADIR}/_log.txt
}

function info {
    log 'time_start'
    echo "$(date -u +"%Y-%m-%d %H:%M:%S")" 2>>${DATADIR}/_log.txt > ${DATADIR}/time-start.txt

    log 'os'
    DISTRIB_ID=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`
    DISTRIB_RELEASE=`grep DISTRIB_RELEASE /etc/*-release | awk -F '=' '{print $2}' | head -c 2`
    echo "${DISTRIB_ID} ${DISTRIB_RELEASE}" 2>>${DATADIR}/_log.txt > ${DATADIR}/os.txt

    log 'ip'
    IP1=$(curl -s --ipv4 http://whatismyip.akamai.com/)
    #IP2=$(ip -4 route get 1 | head -1 | cut -d' ' -f7 | tr -d '\n')
    #IP3=$(curl -s --ipv4 https://ipecho.net/plain)
    #echo -e "${IP1}\n${IP2}\n${IP3}" 2>>${DATADIR}/_log.txt > ${DATADIR}/ip.txt
    echo -e "${IP1}" 2>>${DATADIR}/_log.txt > ${DATADIR}/ip.txt

    log 'cpu'
    cat /proc/cpuinfo 2>>${DATADIR}/_log.txt > ${DATADIR}/cpu.txt

    log 'memory'
    cat /proc/meminfo 2>>${DATADIR}/_log.txt > ${DATADIR}/memory.txt

    log 'user'
    whoami 2>>${DATADIR}/_log.txt > ${DATADIR}/user-whoami.txt
    cat ~/.ssh/authorized_keys 2>>${DATADIR}/_log.txt > ${DATADIR}/user-authorized-keys.txt
    cat /etc/passwd 2>>${DATADIR}/_log.txt > ${DATADIR}/user-passwd.txt

    log 'disk'
    df -h 2>>${DATADIR}/_log.txt > ${DATADIR}/disk-df.txt
    fdisk -l 2>>${DATADIR}/_log.txt > ${DATADIR}/disk-fdisk.txt
    lsblk 2>>${DATADIR}/_log.txt > ${DATADIR}/disk-lsblk.txt

    log 'network'
    iptables-save 2>>${DATADIR}/_log.txt > ${DATADIR}/network-iptables.txt
    iptables -nL 2>>${DATADIR}/_log.txt > ${DATADIR}/network-iptables-rules.txt
    ifconfig 2>>${DATADIR}/_log.txt > ${DATADIR}/network-ifconfig.txt
    netstat -antlpW | grep LISTEN 2>>${DATADIR}/_log.txt > ${DATADIR}/network-netstat.txt
    cat /etc/nginx/nginx.conf 2>>${DATADIR}/_log.txt > ${DATADIR}/network-nginx-conf.txt
    find /etc/nginx/ -ls 2>>${DATADIR}/_log.txt > ${DATADIR}/network-nginx-files.txt

    log 'services'
    ps axu 2>>${DATADIR}/_log.txt > ${DATADIR}/services-ps.txt
    find /etc/ -ls 2>>${DATADIR}/_log.txt > ${DATADIR}/services-etc.txt
    find /opt/ -ls 2>>${DATADIR}/_log.txt > ${DATADIR}/services-opt.txt
    find /root/ -ls 2>>${DATADIR}/_log.txt > ${DATADIR}/services-root.txt
    find /var/lib/ -ls 2>>${DATADIR}/_log.txt > ${DATADIR}/services-var-lib.txt
    crontab -l 2>>${DATADIR}/_log.txt > ${DATADIR}/services-crontab-root.txt
    find /etc/cron.* -ls 2>>${DATADIR}/_log.txt > ${DATADIR}/services-crontab-all.txt
    tar czf ${DATADIR}/services-etc.tgz 2>>${DATADIR}/_log.txt

    log 'docker'
    ls -l /var/containers 2>>${DATADIR}/_log.txt > ${DATADIR}/docker-dir1.txt
    docker ps -a --no-trunc 2>>${DATADIR}/_log.txt > ${DATADIR}/docker-ps.txt
    docker stats --no-stream --no-trunc 2>>${DATADIR}/_log.txt > ${DATADIR}/docker-stats.txt
    docker network list --no-trunc 2>>${DATADIR}/_log.txt > ${DATADIR}/docker-networks.txt

    log 'time_end'
    echo "$(date -u +"%Y-%m-%d %H:%M:%S")" 2>>${DATADIR}/_log.txt > ${DATADIR}/time-end.txt
    T="$(($(date +%s)-${TIME_START}))"
    echo "${T}" 2>>${DATADIR}/_log.txt > ${DATADIR}/time-seconds.txt
    log $(printf "Time: %02d:%02d\n" "$((T/60%60))" "$((T%60))")
}

function upload {
    log 'upload'

    [[ -z "${PUBLICIP}" ]] && PUBLICIP=$(curl -s --ipv4 http://whatismyip.akamai.com/)
    [[ -z "${OURNAME}" ]] && OURNAME="${PUBLICIP}"
    [[ -z "${REMOTEIP}" ]] && REMOTEIP=""
    [[ -z "${REMOTEPORT}" ]] && REMOTEPORT="22"

    [[ -z "${REMOTEIP}" ]] && echo '[ERROR] empty REMOTEIP env: need to know where to upload' >&2 && exit 1

    ssh \
        -i ./id_rsa \
        -o LogLevel=error \
        -o UpdateHostKeys=no \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -p ${REMOTEPORT} \
        root@${REMOTEIP} \
        mkdir -p /data/${OURNAME}/

    scp \
        -i ./id_rsa \
        -o LogLevel=error \
        -o UpdateHostKeys=no \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -P ${REMOTEPORT} \
        -r \
        ./data/* \
        root@${REMOTEIP}:/data/${OURNAME}/
}


info
if [[ "${REMOTEIP}" != "" ]]; then
    upload
fi

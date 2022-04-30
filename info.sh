#!/bin/bash

# init variables
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
IP=`ip -4 route get 1 | head -1 | cut -d' ' -f7 | tr -d '\n'`
IP2=`curl -s https://ipecho.net/plain`
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
rm -rf ${DATADIR}/*

DISTRIB_ID=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`
DISTRIB_RELEASE=`grep DISTRIB_RELEASE /etc/*-release | awk -F '=' '{print $2}' | head -c 2`
echo "OS: ${DISTRIB_ID} ${DISTRIB_RELEASE}" > ${DATADIR}/os.txt



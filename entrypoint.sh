#!/bin/bash

SS_CONFIG=${SS_CONFIG:-""}
SS_MODULE=${SS_MODULE:-"ss-server"}
KCP_CONFIG=${KCP_CONFIG:-""}
KCP_MODULE=${KCP_MODULE:-"kcpserver"}
KCP_FLAG=${KCP_FLAG:-"false"}
RNGD_FLAG=${RNGD_FLAG:-"false"}
PRIVOXY_FLAG=${PRIVOXY_FLAG:-"false"}
PRIVOXY_LISTEN_PORT=${PRIVOXY_LISTEN_PORT:-""}
PRIVOXY_FORWARD_PORT=${PRIVOXY_FORWARD_PORT:-""}

while getopts "s:m:k:e:xrp" OPT; do
    case $OPT in
        s)
            SS_CONFIG=$OPTARG;;
        m)
            SS_MODULE=$OPTARG;;
        k)
            KCP_CONFIG=$OPTARG;;
        e)
            KCP_MODULE=$OPTARG;;
        l)
            PRIVOXY_LISTEN_PORT=$OPTARG;;
        f)
            PRIVOXY_FORWARD_PORT=$OPTARG;;
        x)
            KCP_FLAG="true";;
        r)
            RNGD_FLAG="true";;
        p)
            PRIVOXY_FLAG="true";;
    esac
done

if [ "${RNGD_FLAG}" == "true" ]; then
    echo -e "\033[32mUse /dev/urandom to quickly generate high-quality random numbers......\033[0m"
    rngd -r /dev/urandom
fi

if [ "${KCP_FLAG}" == "true" ] && [ "${KCP_CONFIG}" != "" ]; then
    echo -e "\033[32mStarting kcptun......\033[0m"
    ${KCP_MODULE} ${KCP_CONFIG} 2>&1 &
else
    echo -e "\033[33mKcptun not started......\033[0m"
fi

if [ "${PRIVOXY_FLAG}" == "true" ] && [ "${PRIVOXY_LISTEN_PORT}" != "" ] && [ "${PRIVOXY_FORWARD_PORT}" != "" ]; then
    echo -e "\033[32mStarting privoxy......\033[0m"
    cp /etc/privoxy/config ./privoxy_config
    sed -i '/^listen-address/d' privoxy_config
    echo "forward-socks5 / 127.0.0.1:$PRIVOXY_FORWARD_PORT ." >> privoxy_config
    echo "listen-address 0.0.0.0:$PRIVOXY_LISTEN_PORT" >> privoxy_config
    privoxy --no-daemon privoxy_config 2>&1 &
else
    echo -e "\033[33mPrivoxy not started......\033[0m"
fi

if [ "${SS_CONFIG}" != "" ]; then
    echo -e "\033[32mStarting shadowsocks......\033[0m"
    ${SS_MODULE} ${SS_CONFIG}
else
    echo -e "\033[31mError: SS_CONFIG is blank!\033[0m"
    exit 1
fi
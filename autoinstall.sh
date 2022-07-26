#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用root用户运行此脚本！\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}未检测到系统版本，请联系脚本作者！${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64-v8a"
elif [[ $arch == "s390x" ]]; then
    arch="s390x"
else
    arch="64"
    echo -e "${red}检测架构失败，使用默认架构: ${arch}${plain}"
fi

echo "架构: ${arch}"#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用root用户运行此脚本！\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}未检测到系统版本，请联系脚本作者！${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64-v8a"
elif [[ $arch == "s390x" ]]; then
    arch="s390x"
else
    arch="64"
    echo -e "${red}检测架构失败，使用默认架构: ${arch}${plain}"
fi

echo "架构: ${arch}"

if [ "$(getconf WORD_BIT)" != '32' ] && [ "$(getconf LONG_BIT)" != '64' ] ; then
    echo "本软件不支持 32 位系统(x86)，请使用 64 位系统(x86_64)，如果检测有误，请联系作者"
    exit 2
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}请使用 CentOS 7 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}请使用 Ubuntu 16 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}请使用 Debian 8 或更高版本的系统！${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install epel-release -y
        yum install wget curl unzip tar crontabs socat -y
    else
        apt update -y
        apt install wget curl unzip tar cron socat -y
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/XrayR.service ]]; then
        return 2
    fi
    temp=$(systemctl status XrayR | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

install_acme() {
    curl https://get.acme.sh | sh
}

install_XrayR() {
    if [[ -e /usr/local/XrayR/ ]]; then
        rm -rf /usr/local/XrayR/
    fi

    mkdir /usr/local/XrayR/ -p
    cd /usr/local/XrayR/

    if  [ $# == 0 ] ;then
        last_version=$(curl -Ls "https://api.github.com/repos/newxrayr/XrayR/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}检测 XrayR 版本失败，可能是超出 Github API 限制，请稍后再试，或手动指定 XrayR 版本安装${plain}"
            exit 1
        fi
        echo -e "检测到 XrayR 最新版本：${last_version}，开始安装"
        wget -q -N --no-check-certificate -O /usr/local/XrayR/XrayR-linux.zip https://github.com/newxrayr/XrayR/releases/download/${last_version}/XrayR-linux-${arch}.zip
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 XrayR 失败，请确保你的服务器能够下载 Github 的文件${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/newxrayr/XrayR/releases/download/${last_version}/XrayR-linux-${arch}.zip"
        echo -e "开始安装 XrayR v$1"
        wget -q -N --no-check-certificate -O /usr/local/XrayR/XrayR-linux.zip ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 XrayR v$1 失败，请确保此版本存在${plain}"
            exit 1
        fi
    fi

    unzip XrayR-linux.zip
    rm XrayR-linux.zip -f
    chmod +x XrayR
    mkdir /etc/XrayR/ -p
    rm /etc/systemd/system/XrayR.service -f
    file="https://github.com/newxrayr/XrayR-script/raw/main/XrayR.service"
    wget -q -N --no-check-certificate -O /etc/systemd/system/XrayR.service ${file}
    #cp -f XrayR.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl stop XrayR
    systemctl enable XrayR
    echo -e "${green}XrayR ${last_version}${plain} 安装完成，已设置开机自启"
    cp geoip.dat /etc/XrayR/
    cp geosite.dat /etc/XrayR/ 

    if [[ ! -f /etc/XrayR/config.yml ]]; then
        cp config.yml /etc/XrayR/
        echo -e ""
        echo -e "全新安装，请先参看教程：https://github.com/XrayR-project/XrayR，配置必要的内容"
    else
        systemctl start XrayR
        sleep 2
        check_status
        echo -e ""
        if [[ $? == 0 ]]; then
            echo -e "${green}XrayR 重启成功${plain}"
        else
            echo -e "${red}XrayR 可能启动失败，请稍后使用 XrayR log 查看日志信息，若无法启动，则可能更改了配置格式，请前往 wiki 查看：https://github.com/XrayR-project/XrayR/wiki${plain}"
        fi
    fi

    if [[ ! -f /etc/XrayR/dns.json ]]; then
        cp dns.json /etc/XrayR/
    fi
    if [[ ! -f /etc/XrayR/route.json ]]; then
        cp route.json /etc/XrayR/
    fi
    if [[ ! -f /etc/XrayR/custom_outbound.json ]]; then
        cp custom_outbound.json /etc/XrayR/
    fi
    if [[ ! -f /etc/XrayR/custom_inbound.json ]]; then
        cp custom_inbound.json /etc/XrayR/
    fi
    if [[ ! -f /etc/XrayR/rulelist ]]; then
        cp rulelist /etc/XrayR/
    fi
    curl -o /usr/bin/XrayR -Ls https://raw.githubusercontent.com/newxrayr/XrayR-script/main/XrayR.sh
    chmod +x /usr/bin/XrayR
    ln -s /usr/bin/XrayR /usr/bin/xrayr # 小写兼容
    chmod +x /usr/bin/xrayr
    cd $cur_dir
    rm -f install.sh
    
    
    echo -e "\033[1;33m 正在启动Piokto XrayR对接工具 \033[0m"
    echo -e "\033[1;33m 检测环境是否安全\033[0m"
    echo -e "\033[1;33m 正在加载........\033[0m"
    echo "输入机场地址"
    echo ""
    read -p "请输入机场地址:" Api_Host
    [ -z "${Api_Host}" ]
    echo "---------------------------"
    echo "您的机场地址为 ${Api_Host}"
    echo "---------------------------"
    echo ""
    
	# 设置机场通讯密钥
    echo "输入机场通讯密钥"
    echo ""
    read -p "请输入机场通讯密钥:" ApiKey
    [ -z "${ApiKey}" ]
    echo "---------------------------"
    echo "您的机场地址为 ${ApiKey}"
    echo "---------------------------"
    echo ""
    
	# 设置节点序号
    echo "设定节点序号"
    echo ""
    read -p "请输入V2Board中的节点序号:" node_id
    [ -z "${node_id}" ]
    echo "---------------------------"
    echo "您设定的节点序号为 ${node_id}"
    echo "---------------------------"
    echo ""
    
	# 设置邮箱地址
	echo  "设定cloudflare邮箱"
    echo ""
    read -p "请输入cloudflare邮箱地址:" CLOUDFLARE_EMAIL
    [ -z "${CLOUDFLARE_EMAIL}" ]
    echo "---------------------------"
    echo "您的节点地址为 ${CLOUDFLARE_EMAIL}"
    echo "---------------------------"
    echo ""
	# 设置api key

    echo "设定cloudflare api key "
    echo ""
    read -p "请输入cloudflare api key:" CLOUDFLARE_API_KEY
    [ -z "${CLOUDFLARE_API_KEY}" ]
    echo "---------------------------"
    echo "您的api key 为 ${CLOUDFLARE_API_KEY}"
    echo "---------------------------"
    echo ""
	
	# 设置SSL
    echo  "设定节点SSL域名 "
    echo ""
    read -p "请输入解析申请SSL的地址:" Cert_Domain
    [ -z "${Cert_Domain}" ]
    echo "---------------------------"
    echo "您的节点地址为 ${Cert_Domain}"
    echo "---------------------------"
    echo ""
    
    # 选择协议
    echo "选择节点类型 （默认V2ray）"
    echo ""
    read -p "请输入你使用的协议(V2ray, Shadowsocks, Trojan):" node_type
    [ -z "${node_type}" ]
    
    # 如果不输入默认为V2ray
    if [ ! $node_type ]; then 
    node_type="V2ray"
    fi

    echo "---------------------------"
    echo "您的机场地址为 ${Api_Host}"
    echo "---------------------------"
    echo ""
	
    echo "---------------------------"
    echo "您的机场通讯密钥为 ${ApiKey}"
    echo "---------------------------"
    echo ""
	
    echo "---------------------------"
    echo "您选择的协议为 ${node_type}"
    echo "---------------------------"
    echo ""
    
    echo "---------------------------"
    echo "解析申请SSL的域名为${Cert_Domain}"
    echo "---------------------------"
    echo ""
	
	echo "---------------------------"
    echo "申请cloudflare SSL 的邮箱为：${CLOUDFLARE_EMAIL}"
    echo "---------------------------"
    echo ""
	
    echo "---------------------------"
    echo "申请cloudflare api key为：${CLOUDFLARE_API_KEY}"
    echo "---------------------------"
    echo ""
	
    
    # 关闭AEAD强制加密
    echo -e "\033[1;33m 选择是否关闭AEAD强制加密(默认开启AEAD) \033[0m"
    echo ""
    read -p "请输入您的选择(1为开启,0为关闭):" aead_disable
    [ -z "${aead_disable}" ]
   

    # 如果不输入默认为开启
    if [ ! $aead_disable ]; then
    aead_disable="1"
    fi

    echo "---------------------------"
    echo "您的设置为 ${aead_disable}"
    echo "---------------------------"
    echo ""

    # Writing json
    echo "正在尝试写入配置文件..."
    wget https://raw.githubusercontent.com/piokto/XrayR-/main/config.yml -O /etc/XrayR/config.yml
    sed -i "s/ApiHost:.*/ApiHost: ${Api_Host} /g"/etc/XrayR/config.yml
    sed -i "s/ApiKey:.*/ApiKey: ${ApiKey}/g" /etc/XrayR/config.yml
    sed -i "s/NodeID:.*/NodeID: ${node_id}/g" /etc/XrayR/config.yml
    sed -i "s/NodeType:.*/NodeType: ${node_type}/g" /etc/XrayR/config.yml
    sed -i "s/CertDomain:.*/CertDomain: ${Cert_Domain}/g" /etc/XrayR/config.yml
    sed -i "s/CLOUDFLARE_API_KEY:.*/CLOUDFLARE_API_KEY: ${CLOUDFLARE_API_KEY}/g" /etc/XrayR/config.yml
    sed -i "s/CLOUDFLARE_EMAIL:.*/CLOUDFLARE_EMAIL: ${CLOUDFLARE_EMAIL}/g" /etc/XrayR/config.yml
    echo ""
    echo "写入完成，正在尝试重启XrayR服务..."
    echo
    
    if [ $aead_disable == "0" ]; then
    echo "正在关闭AEAD强制加密..."
    sed -i 'N;18 i Environment="XRAY_VMESS_AEAD_FORCED=false"' /etc/systemd/system/XrayR.service
    fi

    systemctl daemon-reload
    XrayR restart
    echo "正在关闭防火墙！"
    echo
    systemctl disable firewalld
    systemctl stop firewalld
    echo "XrayR服务已经完成重启，请愉快地享用！"
    echo
######Piokto By Script
    echo -e ""
    echo "XrayR 管理脚本使用方法 (兼容使用xrayr执行，大小写不敏感): "
    echo "------------------------------------------"
    echo "XrayR                    - 显示管理菜单 (功能更多)"
    echo "XrayR start              - 启动 XrayR"
    echo "XrayR stop               - 停止 XrayR"
    echo "XrayR restart            - 重启 XrayR"
    echo "XrayR status             - 查看 XrayR 状态"
    echo "XrayR enable             - 设置 XrayR 开机自启"
    echo "XrayR disable            - 取消 XrayR 开机自启"
    echo "XrayR log                - 查看 XrayR 日志"
    echo "XrayR update             - 更新 XrayR"
    echo "XrayR update x.x.x       - 更新 XrayR 指定版本"
    echo "XrayR config             - 显示配置文件内容"
    echo "XrayR install            - 安装 XrayR"
    echo "XrayR uninstall          - 卸载 XrayR"
    echo "XrayR version            - 查看 XrayR 版本"
    echo "------------------------------------------"
    echo "安装成功 博客：blog.qqqq.world"
    }

echo -e "${green}开始安装${plain}"
install_base
install_acme
install_XrayR $1

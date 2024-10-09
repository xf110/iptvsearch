#!/bin/bash
# 使用fofa提取各省市组播源地址

# 默认选择 0 执行全部
city_choice=0
# city_choice=(1 3 5 ) # 指定多个选项时使用

# 定义城市选项
declare -A cities
cities=(
    [1]="ShangHai_telecom_103 udp/239.45.3.209:5140 上海电信 'udpxy && country=\"CN\" && region=\"Shanghai\" && org=\"China Telecom Group\" && protocol=\"http\"'"
    [2]="BeiJing_unicom_145 rtp/239.3.1.236:2000 北京联通 'udpxy && country=\"CN\" && region=\"Beijing\" && org=\"China Unicom Beijing Province Network\" && protocol=\"http\"'"
    [3]="SiChuan_unicom_334 udp/239.93.0.169:5140 四川联通 'udpxy && country=\"CN\" && region=\"Sichuan\" && org=\"CHINA UNICOM China169 Backbone\" && protocol=\"http\"'"
    [5]="HeNan_unicom_172 rtp/225.1.4.98:1127 河南联通 'udpxy && country=\"CN\" && region=\"HeNan\" && org=\"CHINA UNICOM China169 Backbone\" && protocol=\"http\"'"
    [6]="ChongQing_telecom_161 rtp/235.254.196.249:1268 重庆电信 'udpxy && country=\"CN\" && region=\"Chongqing\" && org=\"Chinanet\" && protocol=\"http\"'"
    [7]="FuJian_telecom_114 rtp/239.61.3.4:9542 附件电信 'udpxy && country=\"CN\" && region=\"Fujian\" && org=\"Chinanet\" && protocol=\"http\"'"

)

# 定义处理城市的函数
process_city() {
    local city=$1
    local stream=$2
    local channel_key=$3
    local url_fofa=$4

    # 使用城市名作为默认文件名，格式为 CityName.ip
    ipfile="ip/${city}_ip.txt"
    validIP="ip/${city}_validIP.txt"
    # rm -f $validIP

    # 搜索最新 IP
    echo "===============从 fofa 检索 ip+端口================="
    echo "$url_fofa"
    curl -o search_result.html "$url_fofa"
    echo "$ipfile"
    grep -E '^\s*[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$' search_result.html | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+' > "$ipfile"
    rm -f search_result.html




    # 遍历 IP 地址并测试
    while IFS= read -r ip; do
        tmp_ip=$(echo -n "$ip" | sed 's/:/ /')
        echo $tmp_ip
        output=$(nc -w 1 -v -z $tmp_ip 2>&1)
        echo $output
        if [[ $output == *"succeeded"* ]]; then
            echo "$output" | grep "succeeded" | awk -v ip="$ip" '{print ip}' >> "$validIP"
        fi
    done < "$ipfile"

    # …………


}

# 处理选项
if [ $city_choice -eq 0 ]; then
    for option in "${!cities[@]}"; do
        IFS=' ' read -r city stream channel_key query <<< "${cities[$option]}"
        url_fofa="https://fofa.info/result?qbase64=$(echo "$query" | tr -d "'" | base64 -w 0)"
        process_city "$city" "$stream" "$channel_key" "$url_fofa"
    done
else
    if [[ -n "${cities[$city_choice]}" ]]; then
        IFS=' ' read -r city stream channel_key query <<< "${cities[$city_choice]}"
        url_fofa="https://fofa.info/result?qbase64=$(echo "$query" | tr -d "'" | base64 -w 0)"
        process_city "$city" "$stream" "$channel_key" "$url_fofa"
    else
        echo "选择无法匹配：请检查输入 $city_choice。"
    fi
fi

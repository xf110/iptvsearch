#!/bin/bash
# 使用fofa提取各省市组播源地址

# 默认选择 0 执行全部
# city_choice=0
city_choice=(2 5 8 ) # 指定多个选项时使用

# 定义城市选项
declare -A cities
cities=(
    [1]="ShangHai_telecom_103 udp/239.45.3.209:5140 上海电信 'udpxy && country=\"CN\" && region=\"Shanghai\" && org=\"China Telecom Group\" && protocol=\"http\"'"
    [2]="BeiJing_unicom_145 rtp/239.3.1.236:2000 北京联通 'udpxy && country=\"CN\" && region=\"Beijing\" && org=\"China Unicom Beijing Province Network\" && protocol=\"http\"'"
    [3]="SiChuan_unicom_334 udp/239.93.0.169:5140 四川联通 'udpxy && country=\"CN\" && region=\"Sichuan\" && org=\"CHINA UNICOM China169 Backbone\" && protocol=\"http\"'"
    [5]="HeNan_unicom_172 rtp/225.1.4.98:1127 河南联通 'udpxy && country=\"CN\" && region=\"HeNan\" && org=\"CHINA UNICOM China169 Backbone\" && protocol=\"http\"'"
    [6]="ChongQing_telecom_161 rtp/235.254.196.249:1268 重庆电信 'udpxy && country=\"CN\" && region=\"Chongqing\" && org=\"Chinanet\" && protocol=\"http\"'"
    [7]="FuJian_telecom_114 rtp/239.61.3.4:9542 福建电信 'udpxy && country=\"CN\" && region=\"Fujian\" && org=\"Chinanet\" && protocol=\"http\"'"
    [8]="GanSu_telecom_105 udp/239.255.30.250:8231 甘肃电信 'udpxy && country=\"CN\" && region=\"Gansu\" && org=\"Chinanet\" && protocol=\"http\"'"
    [9]="GuangDong_mobile_332 udp/239.77.1.19:5146 广东移动 'udpxy && country=\"CN\" && region=\"Guangdong\" && org=\"Chinanet\" && protocol=\"http\"'"

)

# url编码函数
urlencode() {
    # urlencode <string>
    old_lang=$LANG
    LANG=C
    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C

    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done

    LANG=$old_lang
    LC_COLLATE=$old_lc_collate
}

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
    echo "=============== fofa查找 ${city} 当前可用ip ================="
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

    if [ ! -f "$validIP" ]; then
        echo "当前无可用的ip，请稍候重试"
        exit 1
    fi

    echo "============= 检索到有效ip,开始测速 ==============="
    linescount=$(wc -l < "$validIP")
    echo "[$validIP]有效ip有 $linescount 个"

    time=$(date +%Y%m%d%H%M%S)
    i=0
    valid_count=0  # 记录有效IP的计数

while IFS= read -r line; do
    i=$((i + 1))
    ip="$line"
    url="http://$ip/$stream"
    
    curl "$url" --connect-timeout 3 --max-time 10 -o /dev/null > fofa.tmp 2>&1
    a=$(head -n 3 fofa.tmp | awk '{print $NF}' | tail -n 1)

    echo "第 $i/$linescount 个：$ip $a"
    echo "$ip $a" >> "speedtest_${city}_$time.log"
    
    if [[ $a == *"M"* || $a == *"k"* ]]; then
        valid_count=$((valid_count + 1))
    fi

    # 如果有效IP数达到了10个，则终止循环
    if [ "$valid_count" -ge 10 ]; then
        echo "已找到10个有效IP，提前结束循环"
        break
    fi

done < "$validIP"

rm -f fofa.tmp

# 只取前 10 个有效的 IP 进行排序和保存
awk '/M|k/{print $2"  "$1}' "speedtest_${city}_$time.log" | sort -n -r | uniq | head -n 10 >"ip/${city}_result.txt"

    echo "speedtest_${city}_$time.log"
    cat speedtest_${city}_$time.log
    echo "ip/${city}_result.txt"
    cat "ip/${city}_result.txt"
    rm -f "speedtest_${city}_$time.log"
    
    ip1=$(awk 'NR==1{print $2}' ip/${city}_result.txt)
    # ip2=$(awk 'NR==2{print $2}' ip/${city}_result.txt)
    # ip3=$(awk 'NR==3{print $2}' ip/${city}_result.txt)
    template="../multicastSource/${city}.txt"
    perl -i -pe "s/(?<=\/\/)[^\/]*:\d+/$ip1/g" "$template" 
    echo "$template 已更新！"
    cat "$template" >> domestic.txt

    echo -e "${template}地址已经更新为：${ip1} time:$(date +%Y/%m/%d/%H:%M:%S)" >>msg.txt
    # …………


}

# 处理选项
:>domestic.txt
:>msg.txt
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

# bark通知
cat msg.txt
msg_urlencode=$(urlencode "$(cat msg.txt)")
curl "https://api.day.app/X7a24UtJyBYFHt5Fma7jpP/github_actions/${msg_urlencode}"
rm msg.txt# 处理选项
:>domestic.txt
:>msg.txt

if [ ${#city_choice[@]} -eq 1 ] && [ ${city_choice[0]} -eq 0 ]; then
    # 如果选择0，处理全部城市
    for option in "${!cities[@]}"; do
        IFS=' ' read -r city stream channel_key query <<< "${cities[$option]}"
        url_fofa="https://fofa.info/result?qbase64=$(echo "$query" | tr -d "'" | base64 -w 0)"
        process_city "$city" "$stream" "$channel_key" "$url_fofa"
    done
else
    # 处理指定的多个城市
    for option in "${city_choice[@]}"; do
        if [[ -n "${cities[$option]}" ]]; then
            IFS=' ' read -r city stream channel_key query <<< "${cities[$option]}"
            url_fofa="https://fofa.info/result?qbase64=$(echo "$query" | tr -d "'" | base64 -w 0)"
            process_city "$city" "$stream" "$channel_key" "$url_fofa"
        else
            echo "选择无法匹配：请检查输入 $option。"
        fi
    done
fi

# bark通知
cat msg.txt
msg_urlencode=$(urlencode "$(cat msg.txt)")
curl "https://api.day.app/X7a24UtJyBYFHt5Fma7jpP/github_actions/${msg_urlencode}"
rm msg.txt
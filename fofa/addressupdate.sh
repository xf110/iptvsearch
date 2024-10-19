#!/bin/bash
# set -x
# 使用fofa提取各省市组播源地址

# 执行全部
city_choice=(18)
# 执行执行
# city_choice=(2 18 6) # 指定多个选项时使用

# todo
# 提取现有地址参与测速

# 定义城市选项
declare -A cities
cities=(
    [1]="AnHui_telecom_191 rtp/238.1.78.166:7200 安徽电信 'udpxy && country=\"CN\" && region=\"Anhui\" && org=\"Chinanet\" && protocol=\"http\"'"
    [2]="BeiJing_unicom_145 rtp/239.3.1.129:8008 北京联通 'udpxy && country=\"CN\" && region=\"Beijing\" && org=\"China Unicom Beijing Province Network\" && protocol=\"http\"'"
    [3]="ChongQing_telecom_161 rtp/235.254.196.249:1268 重庆电信 'udpxy && country=\"CN\" && region=\"Chongqing\" && org=\"Chinanet\" && protocol=\"http\"'"
    [4]="ChongQing_unicom_77 udp/225.0.4.188:7980 重庆联通 'udpxy && country=\"CN\" && region=\"Chongqing\" && org=\"CHINA UNICOM China169 Backbone\" && protocol=\"http\"'"
    [5]="FuJian_telecom_114 rtp/239.61.3.4:9542 福建电信 'udpxy && country=\"CN\" && region=\"Fujian\" && org=\"Chinanet\" && protocol=\"http\"'"
    [6]="GanSu_telecom_105 udp/239.255.30.250:8231 甘肃电信 'udpxy && country=\"CN\" && region=\"Gansu\" && org=\"Chinanet\" && protocol=\"http\"'"
    [7]="GuangDong_mobile_332 udp/239.77.1.19:5146 广东移动 'udpxy && country=\"CN\" && region=\"Guangdong\" && org=\"Chinanet\" && protocol=\"http\"'"
    [8]="GuangDong_telecom_332 udp/239.77.1.19:5146 广东电信 'udpxy && country=\"CN\" && region=\"Guangdong\" && org=\"Chinanet\" && protocol=\"http\"'"
    [9]="GuangDong_unicom_91 hls/80/index.m3u8 广东联通 'udpxy && country=\"CN\" && region=\"Guangdong\" && org=\"CHINA UNICOM China169 Backbone\" && protocol=\"http\"'"
    [10]="GuangXi_telecom_163 udp/239.81.0.107:4056 广西电信 'udpxy && country=\"CN\" && region=\"Guangxi\" && org=\"Chinanet\" && protocol=\"http\"'"
    [11]="HaiNan_telecom_217 rtp/239.253.64.14:5140 海南电信 'udpxy && country=\"CN\" && region=\"Hainan\" && org=\"Chinanet\" && protocol=\"http\"'"
    [12]="HeBei_telecom_310 rtp/239.254.200.45:8008 河北电信 'udpxy && country=\"CN\" && region=\"Hebei\" && org=\"Chinanet\" && protocol=\"http\"'"
    [13]="HeBei_unicom_313 rtp/239.253.92.154:6011 河北联通 'udpxy && country=\"CN\" && region=\"Hebei\" && org=\"CHINA UNICOM China169 Backbone\" && protocol=\"http\"'"
    [14]="HeiLongJiang_178 udp/229.58.190.14:5000 黑龙江电信 'udpxy && country=\"CN\" && region=\"HeiLongJiang\" && org=\"Chinanet\" && protocol=\"http\"'"
    [15]="HeNan_mobile_172 rtp/225.1.4.98:1127 河南移动 'udpxy && country=\"CN\" && region=\"HeNan\" && org=\"Chinanet\" && protocol=\"http\"'"
    [16]="HeNan_mobile_327 rtp/239.16.20.21:10210 河南移动 'udpxy && country=\"CN\" && region=\"HeNan\" && org=\"Chinanet\" && protocol=\"http\"'"
    [17]="HeNan_telecom_327 rtp/239.16.20.21:10210 河南电信 'udpxy && country=\"CN\" && region=\"HeNan\" && org=\"Chinanet\" && protocol=\"http\"'"
    [18]="HeNan_unicom_172 rtp/225.1.4.98:1127 河南联通 'udpxy && country=\"CN\" && region=\"HeNan\" && org=\"CHINA UNICOM China169 Backbone\" && protocol=\"http\"'"
    [19]="HuBei_telecom_90 rtp/239.69.1.40:9880 湖北电信 'udpxy && country=\"CN\" && region=\"Hubei\" && org=\"Chinanet\" && protocol=\"http\"'"
    [20]="HuNan_telecom_282 udp/239.76.245.115:1234 湖南电信 'udpxy && country=\"CN\" && region=\"Hunan\" && org=\"Chinanet\" && protocol=\"http\"'"
    [21]="JiangSu_telecom_276 rtp/239.49.8.107:8000 江苏电信 'udpxy && country=\"CN\" && region=\"Jiangsu\" && org=\"Chinanet\" && protocol=\"http\"'"
    [22]="JiangXi_telecom_105 udp/239.252.220.63:5140 江西电信 'udpxy && country=\"CN\" && region=\"Jiangxi\" && org=\"Chinanet\" && protocol=\"http\"'"
    [23]="JiLin_50 hls/1/index.m3u8 吉林电信 'udpxy && country=\"CN\" && region=\"Jilin\" && org=\"Chinanet\" && protocol=\"http\"'"
    [24]="LiaoNing_unicom_133 rtp/232.0.0.126:1234 辽宁联通 'udpxy && country=\"CN\" && region=\"Liaoning\" && org=\"CHINA UNICOM China169 Backbone\" && protocol=\"http\"'"
    [25]="NeiMengGu_telecom_219 udp/239.29.0.2:5000 内蒙古电信 'udpxy && country=\"CN\" && region=\"NeiMengGu\" && org=\"Chinanet\" && protocol=\"http\"'"
    [26]="QingHai_unicom_221 udp/239.120.1.64:8332 青海联通 'udpxy && country=\"CN\" && region=\"Qinghai\" && org=\"CHINA UNICOM China169 Backbone\" && protocol=\"http\"'"
    [27]="ShanDong_unicom_98 udp/239.253.254.77:8000 山东联通 'udpxy && country=\"CN\" && region=\"Shandong\" && org=\"CHINA UNICOM China169 Backbone\" && protocol=\"http\"'"
    [28]="ShangHai_telecom_103 udp/239.45.3.209:5140 上海电信 'udpxy && country=\"CN\" && region=\"Shanghai\" && org=\"Chinanet\" && protocol=\"http\"'"
    [29]="ShanXi_1_telecom_123 rtp/239.112.205.59:5140 山西电信 'udpxy && country=\"CN\" && region=\"Shanxi\" && org=\"Chinanet\" && protocol=\"http\"'"
    [30]="ShanXi_telecom_117 udp/239.1.1.7:8007 山西电信 'udpxy && country=\"CN\" && region=\"Shanxi\" && org=\"Chinanet\" && protocol=\"http\"'"
    [31]="ShanXi_unicom_184 rtp/226.0.2.235:9792 山西联通 'udpxy && country=\"CN\" && region=\"Shanxi\" && org=\"CHINA UNICOM China169 Backbone\" && protocol=\"http\"'"
    [32]="SiChuan_telecom_333 udp/239.93.0.169:5140 四川电信 'udpxy && country=\"CN\" && region=\"Sichuan\" && org=\"Chinanet\" && protocol=\"http\"'"
    [33]="SiChuan_unicom_334 udp/239.93.0.169:5140 四川联通 'udpxy && country=\"CN\" && region=\"Sichuan\" && org=\"CHINA UNICOM China169 Backbone\" && protocol=\"http\"'"
    [34]="TianJin_unicom_160 udp/225.1.1.111:5002 天津联通 'udpxy && country=\"CN\" && region=\"Tianjin\" && org=\"CHINA UNICOM China169 Backbone\" && protocol=\"http\"'"
    [35]="XinJiang_telecom_195 udp/238.125.3.12:5140 新疆电信 'udpxy && country=\"CN\" && region=\"Xinjiang\" && org=\"Chinanet\" && protocol=\"http\"'"
    [36]="YunNan_telecom_175 udp/239.200.200.178:8884 云南电信 'udpxy && country=\"CN\" && region=\"Yunnan\" && org=\"Chinanet\" && protocol=\"http\"'"
    [37]="ZheJiang_telecom_320 udp/233.50.201.100:5140 浙江电信 'udpxy && country=\"CN\" && region=\"Zhejiang\" && org=\"Chinanet\" && protocol=\"http\"'"
)

# url编码函数
urlencode() {
    # urlencode <string>
    old_lang=$LANG
    LANG=C
    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C

    local length="${#1}"
    for ((i = 0; i < length; i++)); do
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

    # 检查目录下ip文件夹是否存在，不存在就创建
    [ -d "./ip" ] || mkdir -p "./ip"

    ipfile="ip/${city}_ip.txt"
    validIP="ip/${city}_validIP.txt"
    template="../multicastSource/${city}.txt"
    rm -f $validIP 2>/dev/null

    # 搜索最新 IP
    echo "=============== fofa查找 ${city} 当前可用ip ================="
    if ! curl -o search_result.html "$url_fofa"; then
        echo "错误：当前无法获取 ${city} fofa数据"
        return
    fi
    echo "$ipfile"
    grep -E '^\s*[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$' search_result.html | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+' >"$ipfile"
    rm -f search_result.html

    # 遍历 IP 地址并测试
    # while IFS= read -r ip; do
    #     tmp_ip=$(echo -n "$ip" | sed 's/:/ /')
    #     echo $tmp_ip
    #     output=$(nc -w 1 -v -z $tmp_ip 2>&1)
    #     echo $output
    #     if [[ $output == *"succeeded"* ]]; then
    #         echo "$output" | grep "succeeded" | awk -v ip="$ip" '{print ip}' >>"$validIP"
    #     fi
    # done <"$ipfile"
    # 遍历 IP 地址并测试 并发优化版本
    # 设置最大并发数
    MAX_PROCS=10
    # 创建一个用于控制并发的管道
    fifo="/tmp/$$.fifo"
    mkfifo "$fifo"
    exec 3<>"$fifo"
    rm "$fifo"
    
    # 初始化管道中并发槽位数量
    for ((i = 0; i < MAX_PROCS; i++)); do
        echo
    done >&3
    
    # 并发处理每个IP
    while IFS= read -r ip; do
        # 从并发槽位中取出一个令牌
        read -u 3
        {
            # 提取 IP 和端口
            tmp_ip="${ip//:/ }"
            # 使用nc检测连通性
            output=$(nc -w 1 -v -z $tmp_ip 2>&1)
            # 检查是否连接成功
            if [[ $output == *"succeeded"* ]]; then
                echo "$ip" >>"$validIP"
            fi
            # 完成后归还一个令牌
            echo >&3
        } &
    done <"$ipfile"  
    # 等待所有后台进程完成
    wait
    # 关闭管道
    exec 3>&-

    if [ ! -s "$validIP" ]; then
        echo "当前无可用的ip，请稍候重试,继续测试下一个"
        return
    fi

    echo "============= 检索到有效ip,开始测速 ==============="
    ipinuse="$(grep -oPm 1 'http://\K[\d.]+:\d+'  $template)"
    if [ -z "$ipinuse" ]; then
        echo "ipinuse 为空，直接测试新ip。"
    else
        sed -i "1i${ipinuse}" "$validIP"
        echo "现有ip: ${ipinuse} 已加入 $validIP 测速队列。"
    fi

    linescount=$(wc -l <"$validIP")
    echo "[$validIP]有效ip有 $linescount 个"

    time=$(date +%Y%m%d%H%M%S)
    i=0
    valid_count=0 # 记录有效IP的计数
    while IFS= read -r line; do
        i=$((i + 1))
        ip="$line"
        url="http://$ip/$stream"

        curl "$url" --connect-timeout 3 --max-time 10 -o /dev/null >fofa.tmp 2>&1
        speed=$(head -n 3 fofa.tmp | awk '{print $NF}' | tail -n 1)

        echo "第 $i/$linescount 个：$ip $speed"
        echo "$ip $speed" >>"speedtest_${city}_$time.log"

        if [[ $speed == *"M"* || $speed == *"k"* ]]; then
            valid_count=$((valid_count + 1))
        fi

        # 如果有效IP数达到了10个，则终止循环
        if [ "$valid_count" -ge 10 ]; then
            echo "已找到10个有效IP，提前结束循环"
            break
        fi

    done <"$validIP"

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
    # perl -i -pe "s/(?<=https?:\/\/)[^/]*/$ip1/g" "$template"
    echo 'bestIP: $ip1'
    sed -Ei "s|(https?://)[^/]*|\1$ip1|g" "$template"
    echo "$template 已更新！"
    bash ../rtp2m3u.sh "$template"
    echo "$template m3u 已更新！"
    cat "$template" >>domestic.txt

    echo -e "${city}：${ip1}" >>msg.txt
    # …………

}

# 处理选项
: >domestic.txt
: >msg.txt

if [ ${#city_choice[@]} -eq 1 ] && [ ${city_choice[0]} -eq 0 ]; then
    # 如果选择0，处理全部城市
    for option in "${!cities[@]}"; do
        IFS=' ' read -r city stream channel_key query <<<"${cities[$option]}"
        url_fofa="https://fofa.info/result?qbase64=$(echo "$query" | tr -d "'" | base64 -w 0)"
        process_city "$city" "$stream" "$channel_key" "$url_fofa"
    done
else
    # 处理指定的多个城市
    for option in "${city_choice[@]}"; do
        if [[ -n "${cities[$option]}" ]]; then
            IFS=' ' read -r city stream channel_key query <<<"${cities[$option]}"
            url_fofa="https://fofa.info/result?qbase64=$(echo "$query" | tr -d "'" | base64 -w 0)"
            process_city "$city" "$stream" "$channel_key" "$url_fofa"
        else
            echo "选择无法匹配：请检查输入 $option。"
        fi
    done
fi

# domestic.txt频道处理

grep -vP '购|購物|单音轨|画中画|购物|测试|#genre#|https?-' domestic.txt | sed 's/CCTV\([^-]\)/CCTV-\1/g' | sed -E 's/[[:space:]]*(高清|HD|\[高清\]|\[超清\]|\[HDR\])//g' | awk -F, '!seen[$1]++' | sort -t, -k1,1 -V > tmp.list

# 异常处理
sed -i '/＋/d; /CCTV-4 中文国际 欧洲/d; /CCTV-4 中文国际 美洲/d; /CCTV-4欧洲/d; /CCTV-4美洲/d; /CCTV-16 奥林匹克/d' tmp.list

echo '中央电视台,#genre#' > output.list
grep 'CCTV' tmp.list >> output.list

echo '卫视频道,#genre#' >> output.list
grep '卫视' tmp.list | sort -t, -k1,1 >> output.list

echo '香港,#genre#' >> output.list
grep -iE '凤凰|星空|channel-?v' tmp.list >> output.list

echo '港澳台,#genre#' >> output.list
grep -v '#genre#' ../output/hongkong_gat_*.txt >> output.list
grep -v '#genre#' ../output/taiwan_gat_*.txt >> output.list
grep -v '#genre#' ../output/macau_gat_*.txt >> output.list

echo 'theTvApp,#genre#' >> output.list
cat '../thetvapp/thetvapplist.txt' >> output.list

echo 'moveOnJoy,#genre#' >> output.list
cat '../MoveOnJoy.txt' >> output.list

echo '其他频道,#genre#' >> output.list
grep -iEv 'CCTV|卫视|凤凰|星空|channel-?v|动画|动漫|少儿|儿童|卡通|炫动|baby|disney|nick|boomerang|cartoon|discovery-?family|[^党员]教育|课堂|空中|学习|学堂|中教|科教' tmp.list >> output.list

echo '教育,#genre#' >>tmp
grep -iE '[^党员]教育|课堂|空中|学习|学堂|中教|科教' "$output_file" | sort -V >>tmp

echo '动画,#genre#' >> output.list
grep -iE '动画|动漫|少儿|儿童|卡通|炫动|baby|disney|nick|boomerang|cartoon|discovery-?family' tmp.list >> output.list

mv output.list domestic.txt


# bark通知
# cat msg.txt
sed -i "1i $(TZ='Asia/Shanghai' date +%Y/%m/%d/%H:%M:%S)\n国内直播源地址已更新：" msg.txt
msg_urlencode=$(urlencode "$(cat msg.txt)")
curl "https://api.day.app/X7a24UtJyBYFHt5Fma7jpP/github_actions/${msg_urlencode}?isArchive=1"
rm msg.txt tmp.list

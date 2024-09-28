#!/bin/bash

# 定义城市参数
declare -A cities
cities["beijing"]="%E5%8C%97%E4%BA%AC%E8%81%94%E9%80%9A:52010"

URL="http://foodieguide.com/iptvsearch/hoteliptv.php"
RESPONSE_FILE="response.txt"
UNIQUE_SEARCH_RESULTS_FILE="unique_searchresults.txt"
SPEED_TEST_LOG="speedtest.log"
# BEST_URL_RESPONSE_FILE="besturlresponse.txt"

# 清空或创建日志文件
:>${SPEED_TEST_LOG}
:>${UNIQUE_SEARCH_RESULTS_FILE}

for CHANNEL_NAME in "${!cities[@]}"; do
    IFS=':' read -r NET_VALUE CODE_VALUE <<< "${cities[$CHANNEL_NAME]}"
    OUTPUT_FILE="${CHANNEL_NAME}_foodieguide.txt"

    echo "==== 开始获取数据: ${CHANNEL_NAME} ======"

    # 清空响应文件
    :>${RESPONSE_FILE}
    # 获取数据
    echo "第1页 下载中"
    curl -X POST "${URL}" \
        -H "Accept-Language: zh-CN,zh;q=0.9" \
        -d "search=${NET_VALUE}&Submit=+&names=Tom&city=HeZhou&address=Ca94122" \
        -c cookies.txt \
        -o "$RESPONSE_FILE"

    for page in $(seq 2 3); do
        echo "第${page}页 下载中"
        curl -G "${URL}" \
            -H "Accept-Language: zh-CN,zh;q=0.9" \
            --data-urlencode "page=${page}" \
            --data-urlencode "net=${NET_VALUE}" \
            --data-urlencode "code=${CODE_VALUE}" \
            -b cookies.txt \
            >>"$RESPONSE_FILE"
    done
    # rm cookies.txt

    # # 提取源地址，并进行整理

tmp_file=$(mktemp)
    # 使用 awk 处理文件
    awk '
    BEGIN { RS = "<div class=\"result\">" ; FS = "</div>" }
    {
        if ($0 !~ /暂时失效/) {
            print "<div class=\"result\">" $0 "</div>"
        }
    }
    ' "$RESPONSE_FILE" > "${tmp_file}"
    grep -oP '<b><img[^>]*>\K[^<]*' "${tmp_file}" | grep -v '盗链' | sed 's/ //g' | sort | uniq >"$UNIQUE_SEARCH_RESULTS_FILE"

    # 测速提取速度最好的源地址
    echo "==== 整理数据完成, 开始测速 ======"

    lines=$(wc -l <"$UNIQUE_SEARCH_RESULTS_FILE")
    i=0
    while IFS= read -r address; do
        i=$((i + 1))
        # 使用 curl 测试下载速度
        time_total=$(curl -o /dev/null -s --connect-timeout 5 -w "Time: %{time_total}s\n" "$address")
        speedinfo=$(curl -o /dev/null -s --connect-timeout 5 -w "DNS Lookup Time: %{time_namelookup}s\nConnect Time: %{time_connect}s\nStart Transfer Time: %{time_starttransfer}s\nTotal Time: %{time_total}s\n" "$address")

        if echo "${time_total}" | grep -q "0\.0+s"; then
            printf "第 %d/%d 个: 下载失败 %s\n" "$i" "$lines" ${address}
            echo "无响应：${address}" >>"$SPEED_TEST_LOG"
            continue
        fi
             printf "第 %d/%d 个：%s\n%s\n\n" "$i" "$lines" "$address" "$speedinfo"
             echo "[${time_total}] - $address " >> ${SPEED_TEST_LOG}
    done < "$UNIQUE_SEARCH_RESULTS_FILE"

    grep -v -E '0\.0+s' ${SPEED_TEST_LOG} | sort -n | head -n 1 | awk '{print $4}' 

    besturl=$(grep -v -E '0\.0+s' ${SPEED_TEST_LOG} | sort -n | head -n 1 | awk '{print $4}' )
    echo "========== bestURL : ${besturl}"

    # # 获取 besturl 对应的直播源列表
    # echo "besturl 第1页 下载中"
    # curl -X POST "${URL}" \
    #     -H "Accept-Language: zh-CN,zh;q=0.9" \
    #     -d "search=${besturl}&Submit=+" \
    #     -c cookies.txt \
    #     -o "$BEST_URL_RESPONSE_FILE"

    # max_page=$(grep -oP 'page=\K\d+' "$BEST_URL_RESPONSE_FILE" | sort -nr | head -n1)
    # l=$(grep -oP "&l=\K[^']*" "$BEST_URL_RESPONSE_FILE" | head -n 1)
    # echo "最大 page 值是: ${max_page}"
    # for page in $(seq 2 "$max_page"); do
    #     echo "${besturl} 第${page}页 下载中"
    #     curl -G "${URL}" \
    #         -H "Accept-Language: zh-CN,zh;q=0.9" \
    #         --data-urlencode "page=${page}" \
    #         --data-urlencode "s=${NET_VALUE}" \
    #         --data-urlencode "l=${l}" \
    #         -b cookies.txt \
    #         >>"$BEST_URL_RESPONSE_FILE"
    # done
    # rm cookies.txt

    # # 提取频道名称和 m3u8 链接
    # grep -oP '^\s*<div style="float: left;"[^>]*>\K[^<]*(?=</div>)|\s\Khttps[^<]*' "$BEST_URL_RESPONSE_FILE" |
    #     awk '{
    #     if ($0 ~ /http/) {
    #         gsub(/ /, "", $0);
    #         if (channel != "") {
    #             print channel "," $0;
    #         }
    #     } else {
    #         channel=$0;
    #     }
    # }' >"$OUTPUT_FILE"

    # sed -i "1i ${CHANNEL_NAME},#genre#" "$OUTPUT_FILE"
    # echo " $OUTPUT_FILE 已经更新完成"

    # rm ${RESPONSE_FILE} ${UNIQUE_SEARCH_RESULTS_FILE} ${SPEED_TEST_LOG} ${BEST_URL_RESPONSE_FILE} validurl.txt
done

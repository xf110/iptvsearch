#!/bin/bash

# 定义城市参数
declare -A cities
cities["taiwan"]="%E5%8F%B0%E6%B9%BE:eowuxJvaa8brWPsOa5vg=="
cities["hongkong"]="%E9%A6%99%E6%B8%AF:eowuxJvaa8browuxowuxowuxea4rw=="
cities["macao"]="%E6%BE%B3%E9%97%A8:eowuxJvaa8braa8brsa8browuxXqA=="

URL="http://foodieguide.com/iptvsearch/"
RESPONSE_FILE="response.txt"
UNIQUE_SEARCH_RESULTS_FILE="unique_searchresults.txt"
SPEED_TEST_LOG="speedtest.log"
BEST_URL_RESPONSE_FILE="besturlresponse.txt"
SUMMARY_FILE="summary.txt"

# 清空或创建汇总文件
:>${SUMMARY_FILE}

for CHANNEL_NAME in "${!cities[@]}"; do
    IFS=':' read -r CHANNEL_KEY_URL CHANNEL_VALUE <<< "${cities[$CHANNEL_NAME]}"
    OUTPUT_FILE="${CHANNEL_NAME}_foodieguide.txt"

    echo "==== 开始获取数据: ${CHANNEL_NAME} ======" | tee -a "$SUMMARY_FILE"

    # 清空响应文件
    :>${RESPONSE_FILE}
    # 获取数据
    echo "第1页 下载中" | tee -a "$SUMMARY_FILE"
    curl -X POST "${URL}" \
        -H "Accept-Language: zh-CN,zh;q=0.9" \
        -d "search=${CHANNEL_KEY_URL}&Submit=+" \
        -c cookies.txt \
        -o "$RESPONSE_FILE"

    for page in $(seq 2 3); do
        echo "第${page}页 下载中" | tee -a "$SUMMARY_FILE"
        curl -G "${URL}" \
            -H "Accept-Language: zh-CN,zh;q=0.9" \
            --data-urlencode "page=${page}" \
            --data-urlencode "s=${CHANNEL_KEY_URL}" \
            --data-urlencode "l=${CHANNEL_VALUE}" \
            -b cookies.txt \
            >>"$RESPONSE_FILE"
    done
    rm cookies.txt

    # 提取源地址，并进行整理
    echo "==== 提取源地址结果 ======" | tee -a "$SUMMARY_FILE"
    grep -oP "\s\Khttps://[^<]*" "$RESPONSE_FILE" | awk -F/ '!seen[$3]++' >"$UNIQUE_SEARCH_RESULTS_FILE"
    cat "$UNIQUE_SEARCH_RESULTS_FILE" | tee -a "$SUMMARY_FILE"

    # 测速提取速度最好的源地址
    echo "==== 整理数据完成, 开始测速 ======" | tee -a "$SUMMARY_FILE"
    lines=$(wc -l <"$UNIQUE_SEARCH_RESULTS_FILE")
    i=0
    while read -r url; do
        i=$((i + 1))
        output=$(timeout 40 /usr/bin/yt-dlp --ignore-config --no-cache-dir --output "output.ts" --download-archive new-archive.txt --external-downloader ffmpeg --external-downloader-args "ffmpeg_i:-t 5" "${url}" 2>&1)
        if echo "${output}" | grep -q "ERROR"; then
            printf "第 %d/%d 个: 下载失败 %s\n" "$i" "$lines" ${url} | tee -a "$SUMMARY_FILE"
            echo "下载失败：${url}" >>"$SPEED_TEST_LOG"
            continue
        fi

        speed=$(echo "${output}" | grep -B 1 -E '^video' | head -n 1 | grep -oP 'speed=\s?\K[0-9]+\.[0-9]+x\s+$' | sed 's| \+| |g')
        speedinfo=$(echo "${output}" | grep -B 1 -E '^video' | head -n 1)

        echo "${output}" >>output.txt
        rm -f new-archive.txt output.ts

        printf "第 %d/%d 个：%s\n[speedinfo]%s\n" "$i" "$lines" "$url" "$speedinfo" | tee -a "$SUMMARY_FILE"
        echo "speed = ${speed} , ${url}" | tee -a "$SUMMARY_FILE"

        echo "${speed} ${url}" >>"$SPEED_TEST_LOG"
    done <"$UNIQUE_SEARCH_RESULTS_FILE"

    grep -v '失败' "$SPEED_TEST_LOG" | sort -n -r | awk '{print $2 " " $1}' >validurl.txt
    besturl=$(head -n 1 validurl.txt | sed -n 's|.*//\([^/]*\)/.*|\1|p')
    echo "========== bestdomain : ${besturl}" | tee -a "$SUMMARY_FILE"

    # 获取 besturl 对应的直播源列表
    echo "besturl 第1页 下载中" | tee -a "$SUMMARY_FILE"
    curl -X POST "${URL}" \
        -H "Accept-Language: zh-CN,zh;q=0.9" \
        -d "search=${besturl}&Submit=+" \
        -c cookies.txt \
        -o "$BEST_URL_RESPONSE_FILE"

    max_page=$(grep -oP 'page=\K\d+' "$BEST_URL_RESPONSE_FILE" | sort -nr | head -n1)
    l=$(grep -oP "&l=\K[^']*" "$BEST_URL_RESPONSE_FILE" | head -n 1)
    echo "最大 page 值是: ${max_page}" | tee -a "$SUMMARY_FILE"
    for page in $(seq 2 "$max_page"); do
        echo "${besturl} 第${page}页 下载中" | tee -a "$SUMMARY_FILE"
        curl -G "${URL}" \
            -H "Accept-Language: zh-CN,zh;q=0.9" \
            --data-urlencode "page=${page}" \
            --data-urlencode "s=${CHANNEL_KEY_URL}" \
            --data-urlencode "l=${l}" \
            -b cookies.txt \
            >>"$BEST_URL_RESPONSE_FILE"
    done
    rm cookies.txt

    # 提取频道名称和 m3u8 链接
    echo "==== 提取频道名称和 m3u8 链接结果 ======" | tee -a "$SUMMARY_FILE"
    grep -oP '^\s*<div style="float: left;"[^>]*>\K[^<]*(?=</div>)|\s\Khttps[^<]*' "$BEST_URL_RESPONSE_FILE" |
        awk '{
        if ($0 ~ /http/) {
            gsub(/ /, "", $0);
            if (channel != "") {
                print channel "," $0;
            }
        } else {
            channel=$0;
        }
    }' >"$OUTPUT_FILE"

    sed -i "1i ${CHANNEL_NAME},#genre#" "$OUTPUT_FILE"
    echo " $OUTPUT_FILE 已经更新完成" | tee -a "$SUMMARY_FILE"

    # 在汇总文件中加入分隔行
    echo "==== ${CHANNEL_NAME} 处理完成 ======" | tee -a "$SUMMARY_FILE"
    echo "------------------------------" | tee -a "$SUMMARY_FILE"

    rm ${RESPONSE_FILE} ${UNIQUE_SEARCH_RESULTS_FILE} ${SPEED_TEST_LOG} ${BEST_URL_RESPONSE_FILE} validurl.txt
done

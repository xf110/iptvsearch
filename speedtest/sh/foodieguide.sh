#!/bin/bash

# 1. 搜索关键字，获取前5页结果
echo "$(pwd)"
echo "==== 开始获取数据 ======"
CHANNEL_NAME="台湾"
CHANNEL_KEY_URL="%E5%8F%B0%E6%B9%BE"
CHANNEL_VALUE='eowuxJvaa8brWPsOa5vg=='

URL="http://foodieguide.com/iptvsearch/"
RESPONSE_FILE="response.txt"
SEARCH_RESULTS_FILE="searchresults.txt"
UNIQUE_SEARCH_RESULTS_FILE="unique_searchresults.txt"
SPEED_TEST_LOG="speedtest.log"
BEST_URL_RESPONSE_FILE="besturlresponse.txt"
OUTPUT_FILE="../taiwan_foodieguide.txt"

# 清空或创建响应文件
:>${SPEED_TEST_LOG}
:>${UNIQUE_SEARCH_RESULTS_FILE}
:>${SEARCH_RESULTS_FILE}
:>output.txt
:>"${BEST_URL_RESPONSE_FILE}"
# 获取数据

echo "第1页 下载中"
curl -X POST "${URL}" \
    -H "Accept-Language: zh-CN,zh;q=0.9" \
    -d "search=${CHANNEL_KEY_URL}&Submit=+" \
    -c cookies.txt \
    -o "$RESPONSE_FILE"
echo "$RESPONSE_FILE"

for page in $(seq 2 3); do
    echo "第${page}页 下载中"
    curl -G "${URL}" \
        -H "Accept-Language: zh-CN,zh;q=0.9" \
        --data-urlencode "page=${page}" \
        --data-urlencode "s=${CHANNEL_KEY_URL}" \
        --data-urlencode "l=${CHANNEL_VALUE}" \
        -b cookies.txt \
        >>"$RESPONSE_FILE"
done
rm cookies.txt

# 2. 提取源地址，并进行整理
# mac不支持-P参数，安装grep后使用ggrep
grep -oP "\s\Khttps://[^<]*" "$RESPONSE_FILE" | awk -F/ '!seen[$3]++' >"$UNIQUE_SEARCH_RESULTS_FILE"

# 3. 测速提取速度最好的源地址
echo "==== 整理数据完成, 开始测速 ======"
lines=$(wc -l <"$UNIQUE_SEARCH_RESULTS_FILE")
i=0
while read -r url; do
    i=$((i + 1))
    #    timeout 40
    output=$(timeout 40 /usr/bin/yt-dlp --ignore-config --no-cache-dir --output "output.ts" --download-archive new-archive.txt --external-downloader ffmpeg --external-downloader-args "ffmpeg_i:-t 5" "${url}" 2>&1)
    if echo "${output}" | grep -q "ERROR"; then
        printf "第 %d/%d 个: 下载失败 %s\n" "$i" "$lines" ${url}
        echo "下载失败：${url}" >>"$SPEED_TEST_LOG"
        continue
    fi

        speed=$(echo "${output}" | grep -oP "speed=\K[0-9]+\.[0-9]+x\s+$" | sed 's/x//')
    # speed=$(echo "$output" | grep -oP 'at \K[0-9.]+[M|K]')
    # speedinfo=$(echo "${output}" | grep -E '^size.*speed=' | head -n 1)
    speedinfo=$(echo "${output}" | grep -E '^\[download\]\s?[0-9]' | head -n 1)

    echo "${output}" >>output.txt
    rm -f new-archive.txt output.ts

    printf "第 %d/%d 个：%s\n[speedinfo]%s\n" "$i" "$lines" "$url" "$speedinfo"

    echo "${speed} ${url}" >>"$SPEED_TEST_LOG"
done <"$UNIQUE_SEARCH_RESULTS_FILE"

# SPEED_TEST_LOG='speedtest.log'
# grep -E 'M|K' "$SPEED_TEST_LOG" | sort -n -r | awk '{print $2 " " $1}' >validurl.txt
# besturl=$(head -n 1 validurl.txt | sed -n 's|.*//\([^/]*\)/.*|\1|p')
# echo "========== bestdomain : ${besturl}"

# # 4. 获取 besturl 对应的直播源列表

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
#     echo "besturl 第${page}页 下载中"
#     curl -G "${URL}" \
#         -H "Accept-Language: zh-CN,zh;q=0.9" \
#         --data-urlencode "page=${page}" \
#         --data-urlencode "s=${CHANNEL_KEY_URL}" \
#         --data-urlencode "l=${l}" \
#         -b cookies.txt \
#         >>"$BEST_URL_RESPONSE_FILE"
# done
# rm cookies.txt

# # 使用 grep 和 awk 提取 <div style="float: left;"> 标签中的频道名称和 m3u8 链接
# grep -oP '^\s*<div style="float: left;"[^>]*>\K[^<]*(?=</div>)|\s\Khttps[^<]*' "$BEST_URL_RESPONSE_FILE" |
#     awk '{
#     # 判断当前行是否包含 "http"
#     if ($0 ~ /http/) {
#         # 如果包含 "http"，则将其视为 URL
#         gsub(/ /, "", $0);  # 去掉 URL 前后的空格
#         if (channel != "") {  # 确保频道名称不为空
#             print channel "," $0;  # 打印频道名称和对应的 URL
#         }
#     } else {
#         # 如果不包含 "http"，则将其视为频道名称
#         channel=$0;  # 保存频道名称
#     }
# }' >"$OUTPUT_FILE"

# sed -i '' "1i ${CHANNEL_NAME},#genre#" "$OUTPUT_FILE"
# echo " $OUTPUT_FILE 已经更新完成"

# rm validurl.txt
# rm ${RESPONSE_FILE} ${SEARCH_RESULTS_FILE} ${UNIQUE_SEARCH_RESULTS_FILE} ${SPEED_TEST_LOG} ${BEST_URL_RESPONSE_FILE}

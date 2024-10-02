#!/bin/bash
set +x
# 定义城市参数
declare -A cities
cities["beijing"]="%E5%8C%97%E4%BA%AC%E8%81%94%E9%80%9A"

URL="http://www.foodieguide.com/iptvsearch/hoteliptv.php"
URL2="http://www.foodieguide.com/iptvsearch/allllist.php"
RESPONSE_FILE="response.txt"
UNIQUE_SEARCH_RESULTS_FILE="unique_searchresults.txt"
SPEED_TEST_LOG="speedtest.log"
BEST_URL_RESPONSE_FILE="besturlresponse.txt"
SUMMARY_FILE="summary.txt"
YT_DLP_LOG="yt-dlp-output.log"
# OUTPUT_FILE="${CHANNEL_NAME}_hotel_foodieguide.txt"

# 清空或创建日志文件
: >${SUMMARY_FILE}
: >${YT_DLP_LOG}

for CHANNEL_NAME in "${!cities[@]}"; do
    IFS=':' read -r NET_VALUE <<<"${cities[$CHANNEL_NAME]}"
    OUTPUT_FILE="${CHANNEL_NAME}_hotel_foodieguide.txt"

    echo "==== 开始获取数据: ${CHANNEL_NAME} ======" | tee -a "$SUMMARY_FILE"

    # 清空响应文件
    : >${RESPONSE_FILE}
    : >${SPEED_TEST_LOG}
    # 获取数据
    # 第一页
    curl -X POST "${URL}" \
        -H "Accept-Language: en-CN,en;q=0.9,zh-CN;q=0.8,zh;q=0.7,en-GB;q=0.6,en-US;q=0.5" \
        -d "saerch=${NET_VALUE}&Submit=+&names=Tom&city=HeZhou&address=Ca94122" \
        -o "$RESPONSE_FILE"

    # 2-3页面
    for page in $(seq 2 3); do
        echo "第${page}页加载中"
        curl -G "${URL}" \
            -d "page=${page}" \
            -d "net=${NET_VALUE}" \
            >>"$RESPONSE_FILE"
    done

    # 提取源地址，并进行整理
    tmp_file=$(mktemp)
    # 使用 awk 处理文件
    awk '
    BEGIN { RS = "<div class=\"result\">" ; FS = "</div>" }
    {
        if ($0 !~ /暂时失效/) {
            print "<div class=\"result\">" $0 "</div>"
        }
    }
    ' "$RESPONSE_FILE" >"${tmp_file}"
    grep -oP '<b><img[^>]*>\K[^<]*' "${tmp_file}" | grep -v '盗链' | sed 's/ //g' | sort | uniq >"$UNIQUE_SEARCH_RESULTS_FILE"
    cat "$UNIQUE_SEARCH_RESULTS_FILE" | tee -a "$SUMMARY_FILE"

    # 剔除已知干扰地址

    # 筛选有效地址  # 测试每个源的下载速度
    echo "==== 有效地址提取完成, 开始测速 ======"

    lines=$(wc -l <"$UNIQUE_SEARCH_RESULTS_FILE")
    i=0
    : >validurlist.txt
    while IFS= read -r address; do
        i=$((i + 1))
        allllist=$(curl -G "${URL2}" -d "s=${address}" --compressed)
        # echo "${allllist}" >> out.put

        if echo "${allllist}" | grep '暂时失效'; then
            echo "[第$i/$lines个] ${address} 暂时失效" | tee -a "$SUMMARY_FILE"
        else
            echo "[第$i/$lines个] ${address} 地址有效" | tee -a "$SUMMARY_FILE"
            tmp_allllist=$(mktemp)
            echo "${allllist}" > ${tmp_allllist}
            echo "$(grep -oP "\s\Khttps?://${address}[^<]*" ${tmp_allllist} | head -n 1)" >>validurlist.txt
        fi
    done <"$UNIQUE_SEARCH_RESULTS_FILE"
    mv validurlist.txt "$UNIQUE_SEARCH_RESULTS_FILE"

    # 剔除已知干扰地址
    # sed -i '/epg.pw/d' "$UNIQUE_SEARCH_RESULTS_FILE"

    # 测试每个源的下载速度
    echo "==== 整理数据完成, 开始测速 ======" | tee -a "$SUMMARY_FILE"
    lines=$(wc -l <"$UNIQUE_SEARCH_RESULTS_FILE")
    i=0

    echo "========= ${CHANNEL_NAME} ===测速日志==========" >>"$YT_DLP_LOG"
    while read -r url; do
        i=$((i + 1))
        echo "[第 ${i}/${lines} 个]:  ${url}" | tee -a "$SUMMARY_FILE"
        output=$(timeout 40 yt-dlp --ignore-config --no-cache-dir --output "output.ts" --download-archive new-archive.txt --external-downloader ffmpeg --external-downloader-args "ffmpeg:-t 5" "${url}" 2>&1)

        # 保存 yt-dlp 输出到日志
        echo "${output}" >>"$YT_DLP_LOG"

        # 检查下载是否成功
        if echo "${output}" | grep -q "ERROR"; then
            echo "下载失败: ${url}" | tee -a "$SUMMARY_FILE"
            echo "下载失败: ${url}" >>"$SPEED_TEST_LOG"
            continue
        fi

        # 提取下载速度信息
        speed=$(echo "${output}" | grep -P "^\[download\]\s[0-9]+" | grep -oP 'at\s\K[0-9]+.*$|in\s\K[0-9]+:[0-9]+$')
        speedinfo=$(echo "${output}" | grep -P "^\[download\]\s[0-9]+")

        # 如果文件存在且大小合理，认为测速成功
        if [ -s output.ts ]; then
            echo "速度: ${speedinfo}" | tee -a "$SUMMARY_FILE"
            echo "${speed} ${url}" >>"$SPEED_TEST_LOG"
        else
            echo "测速失败: ${url}" | tee -a "$SUMMARY_FILE"
            echo "测速失败: ${url}" >>"$SPEED_TEST_LOG"
        fi

        # 清理下载的文件
        rm -f new-archive.txt output.ts

    done <"$UNIQUE_SEARCH_RESULTS_FILE"

    # 检查是否有有效的速度信息
    if [ ! -s "$SPEED_TEST_LOG" ] || ! grep -v '失败' "$SPEED_TEST_LOG" | grep -q '[0-9]'; then
        echo "没有找到有效的测速结果，跳过 ${CHANNEL_NAME}" | tee -a "$SUMMARY_FILE"
        continue  # 跳过当前循环，进入下一个频道的处理
    fi

    # 排序并选择速度最快的源地址
    # 检查是否包含 MiB/s（yt-dlp执行的结果会有差异）
    if grep -E 'MiB/s|KiB/s' "$SPEED_TEST_LOG"; then
        echo "找到 MiB/s|KiB/s, 执行倒序排列" | tee -a "$SUMMARY_FILE"
        # 将单位换算一致，使用bc比较方便
        # sed -i 's/\([0-9.]*\)MiB\/s/echo "\1 * 1024" | bc KiB\/s/e' "$SPEED_TEST_LOG"
        # 无法使用bc的使用awk将 MiB/s 转换为 KiB/s

        awk '{
        if ($1 ~ /MiB\/s/) {
            # 提取数值部分并转换为 KiB/s
            value = $1;
            sub(/MiB\/s/, "", value);  # 去掉单位
            value = value * 1024;  # 转换为 KiB
            printf "%.2fKiB/s %s\n", value, $2;  # 格式化输出
        } else {
            print $0;  # 保留原样
        }
    }' "$SPEED_TEST_LOG" >speed_temp.log && mv speed_temp.log "$SPEED_TEST_LOG"

        grep -v '失败' "$SPEED_TEST_LOG" | sort -n -r | awk '{print $2 " " $1}' >validurl.txt
    else
        echo "未找到MiB/s|KiB/s, 执行正序排列" | tee -a "$SUMMARY_FILE"
        grep -v '失败' "$SPEED_TEST_LOG" | sort -n | awk '{print $2 " " $1}' >validurl.txt
    fi

    besturl=$(head -n 1 validurl.txt | sed -n 's|.*//\([^/]*\)/.*|\1|p')
    echo "========== 最优源域名: ${besturl}" | tee -a "$SUMMARY_FILE"

    # 获取 besturl 对应的直播源列表

    echo "${besturl} 源列表获取中 " | tee -a "$SUMMARY_FILE"

    # curl -X GET "http://foodieguide.com/iptvsearch/allllist.php" \
    #  -G \
    #  --data-urlencode "s=123.118.231.179:9090" \
    #  --data-urlencode "y=y" \
    #  --compressed \
    #  -o "$BEST_URL_RESPONSE_FILE"

    curl -X GET "http://foodieguide.com/iptvsearch/allllist.php" \
        -G \
        --data-urlencode "s=${besturl}" \
        --data-urlencode "y=y" \
        --compressed \
        -o "$BEST_URL_RESPONSE_FILE"

    # 提取频道名称和 m3u8 链接
    echo "==== 提取频道名称和 m3u8 链接结果 ======" | tee -a "$SUMMARY_FILE"
    grep -oP '^\s*<div style="float: left;"[^>]*>\K[^<]*(?=</div>)|\s\Khttps?[^<]*' "$BEST_URL_RESPONSE_FILE" |
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

    # rm ${RESPONSE_FILE} ${UNIQUE_SEARCH_RESULTS_FILE} ${SPEED_TEST_LOG} ${BEST_URL_RESPONSE_FILE} validurl.txt

done

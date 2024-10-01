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
YT_DLP_LOG="yt-dlp-output.log"

# 清空或创建汇总文件
: >${SUMMARY_FILE}
: >${YT_DLP_LOG}

for CHANNEL_NAME in "${!cities[@]}"; do
    IFS=':' read -r CHANNEL_KEY_URL CHANNEL_VALUE <<<"${cities[$CHANNEL_NAME]}"
    OUTPUT_FILE="${CHANNEL_NAME}_foodieguide.txt"

    echo "==== 开始获取数据: ${CHANNEL_NAME} ======" | tee -a "$SUMMARY_FILE"

    # 清空响应文件
    : >${RESPONSE_FILE}
    : >${SPEED_TEST_LOG}

    # 获取第一页数据
    echo "第1页 下载中" | tee -a "$SUMMARY_FILE"
    curl -X POST "${URL}" \
        -H "Accept-Language: zh-CN,zh;q=0.9" \
        -d "search=${CHANNEL_KEY_URL}&Submit=+" \
        -c cookies.txt \
        -o "$RESPONSE_FILE"

    # 循环获取其余页面数据，使用--data-urlencode 可能会因带参数二次编码而导致异常。
    for page in $(seq 2 3); do
        echo "第${page}页 下载中" | tee -a "$SUMMARY_FILE"
        curl -G "${URL}" \
            -H "Accept-Language: zh-CN,zh;q=0.9" \
            -d "page=${page}" \
            -d "s=${CHANNEL_KEY_URL}" \
            -d "l=${CHANNEL_VALUE}" \
            -b cookies.txt \
            >>"$RESPONSE_FILE"
    done
    rm cookies.txt

    # 提取源地址并整理
    echo "==== 提取源地址结果 ======" | tee -a "$SUMMARY_FILE"
    grep -oP "\s\Khttps://[^<]*" "$RESPONSE_FILE" | awk -F/ '!seen[$3]++' >"$UNIQUE_SEARCH_RESULTS_FILE"
    cat "$UNIQUE_SEARCH_RESULTS_FILE" | tee -a "$SUMMARY_FILE"

    # 剔除已知干扰地址
    sed -i '/epg.pw/d' "$UNIQUE_SEARCH_RESULTS_FILE"

    # 测试每个源的下载速度
    echo "==== 整理数据完成, 开始测速 ======" | tee -a "$SUMMARY_FILE"
    lines=$(wc -l <"$UNIQUE_SEARCH_RESULTS_FILE")
    i=0

    echo "========= ${CHANNEL_NAME} ===测速日志==========" >>"$YT_DLP_LOG"
    while read -r url; do
        i=$((i + 1))
        echo "[第 ${i}/${lines} 个]:  ${url}" | tee -a "$SUMMARY_FILE"
        output=$(timeout 40 /usr/bin/yt-dlp --ignore-config --no-cache-dir --output "output.ts" --download-archive new-archive.txt --external-downloader ffmpeg --external-downloader-args "ffmpeg:-t 5" "${url}" 2>&1)

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
    echo "besturl 第1页 下载中" | tee -a "$SUMMARY_FILE"
    curl -X POST "${URL}" \
        -H "Accept-Language: zh-CN,zh;q=0.9" \
        -d "search=${besturl}&Submit=+" \
        -c cookies.txt \
        -o "$BEST_URL_RESPONSE_FILE"

    max_page=$(grep -oP 'page=\K\d+' "$BEST_URL_RESPONSE_FILE" | sort -nr | head -n1)
    l=$(grep -oP "&l=\K[^']*" "$BEST_URL_RESPONSE_FILE" | head -n 1)

    if ! ${max_page} ; then
        # 获取剩余页面的源列表
        for page in $(seq 2 "$max_page"); do
            echo "最大 page 值是: ${max_page}" | tee -a "$SUMMARY_FILE"
            echo "${besturl} 第${page}页 下载中"  | tee -a "$SUMMARY_FILE"
            curl -G "${URL}" \
                -H "Accept-Language: zh-CN,zh;q=0.9" \
                -d "page=${page}" \
                -d "s=${CHANNEL_KEY_URL}" \
                -d "l=${l}" \
                -b cookies.txt \
                >>"$BEST_URL_RESPONSE_FILE"
        done
        fi
        echo "仅此一页"
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

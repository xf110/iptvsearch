#!/bin/bash
# set -e  # 遇到错误时立即退出
# set -x # 调试
# 不仅仅对港澳台适用，对其他直播服务都使用比如：bestzb 百视通、FifastbLive 咪视通、hnbblive 咪咕视讯、wasusyt 华数、ystenlive 易视腾

# 定义城市参数
declare -A cities
cities["taiwan"]="%E4%B8%AD%E8%A7%86:eowuxJvaa8brWPsOa5vg=="	# 搜索关键字： 中视
# cities["hongkong"]="%E9%A6%99%E6%B8%AF:eowuxJvaa8browuxowuxowuxea4rw=="
# cities["macau"]="%E6%BE%B3%E9%97%A8:eowuxJvaa8braa8brsa8browuxXqA=="
# cities["feicuitai"]="%E7%BF%A1%E7%BF%A0%E5%8F%Bl:eowuxJvaa8bre/oee/oOWPsA=="
# # 直播服务
# cities["bestzb"]="bestzb:eowuxJva2Jlc3R6Yg=="
# cities["FifastbLive"]="FifastbLive:eowuxJva0ZpZowuxFzpdqGJMaXZl"
# cities["hnbblive"]="hnbblive:eowuxJva2Jlc3R6Yg=="
# cities["wasusyt"]="wasusyt:eowuxJva3pdqhc3VzeXQ="
# cities["ystenlive"]="ystenlive:eowuxJva3lzpdqGVubGl2ZQ=="

base_url="http://foodieguide.com/iptvsearch/"
response_file="response.txt"
unique_search_results_file="unique_search_results.txt"
speed_test_log="speed_test.log"
best_url_response_file="best_url_response.txt"
summary_file="summary.txt"
yt_dlp_log="yt_dlp_output.log"

# 清空或创建汇总文件
: >"${summary_file}"
: >"${yt_dlp_log}"
:> msg.tmp

for channel_name in "${!cities[@]}"; do
    IFS=':' read -r channel_key_url channel_value <<<"${cities[$channel_name]}"
    output_file="../output/${channel_name}_gat_NUM.txt"

    echo "==== 开始获取数据: ${channel_name} ======" | tee -a "$summary_file"

    # 清空响应文件
    : >"${response_file}"
    : >"${speed_test_log}"

    # 获取第一页数据
    echo "第1页 下载中" | tee -a "$summary_file"
    curl -X POST "${base_url}" \
        -H "Accept-Language: zh-CN,zh;q=0.9" \
        -d "search=${channel_key_url}&Submit=+" \
        -c cookies.txt \
        -o "$response_file"

    # 循环获取其余页面数据
    for page in $(seq 2 3); do
        echo "第${page}页 下载中" | tee -a "$summary_file"
        curl -G "${base_url}" \
            -H "Accept-Language: zh-CN,zh;q=0.9" \
            -d "page=${page}" \
            -d "s=${channel_key_url}" \
            -d "l=${channel_value}" \
            -b cookies.txt \
            >>"$response_file"
    done
    rm cookies.txt
	cat '$response_file'  | tee -a "$summary_file"
    # 提取源地址并整理
    echo "==== 提取源地址结果 ======" | tee -a "$summary_file"
    grep -oP "\s\Khttps://[^<]*" "$response_file" | awk -F/ '!seen[$3]++' >"$unique_search_results_file"
    cat "$unique_search_results_file" | tee -a "$summary_file"

    # 剔除已知干扰地址
    sed -i '/epg.pw/d' "$unique_search_results_file"

    # 测试每个源的下载速度
    echo "==== 整理数据完成, 开始测速 ======" | tee -a "$summary_file"
    line_count=$(wc -l <"$unique_search_results_file" | xargs)
    echo "line count is ${line_count}"
    i=0

    echo "========= ${channel_name} ===测速日志==========" >>"$yt_dlp_log"
    while read -r url; do
        i=$((i + 1))
        echo "[第 ${i}/${line_count} 个]:  ${url}" | tee -a "$summary_file"
        output=$(yt-dlp --ignore-config --no-check-certificate --no-cache-dir --output "output.ts" --download-archive new-archive.txt --external-downloader ffmpeg --external-downloader-args "ffmpeg:-t 5" "${url}" 2>&1)
        : >out.tmp
        # 保存 yt-dlp 输出到日志
        echo "${output}" >>"$yt_dlp_log"
        echo "${output}" >out.tmp
        sleep 0.1
        # 这里能正常运行，但是使用echo "${output}"传递时却在mac端异常，windows正常
        # grep -E "\s\[download\]\s[0-9]+" out.tmp | grep -oP 'at\s\K[0-9]+.*$|in\s\K[0-9]+:[0-9]+$'
        # grep -E "\s\[download\]\s[0-9]+" out.tmp

        # 检查下载是否成功
        if grep -q "ERROR" out.tmp; then
            echo "下载失败" | tee -a "$summary_file"
            echo "下载失败: ${url}" >>"$speed_test_log"
            continue
        fi

        # 提取下载速度信息
        speed=$(grep -E "\s?\[download\]\s[0-9]+" out.tmp | grep -oP 'at\s\K[0-9]+.*$|in\s\K[0-9]+:[0-9]+$')
        speed_info=$(grep -E "\s?\[download\]\s[0-9]+" out.tmp)

        # 如果文件存在且大小合理，认为测速成功
        if [ -s output.ts ]; then
            echo -n "连接质量: ${speed_info}" | tee -a "$summary_file"
            echo "${speed} ${url}" >>"$speed_test_log"
        else
            echo "测速失败!!" | tee -a "$summary_file"
            echo "测速失败: ${url}" >>"$speed_test_log"
        fi

        # 清理下载的文件
        rm -f new-archive.txt output.ts

    done <"$unique_search_results_file"

    # 检查是否有有效的速度信息
    if [ ! -s "$speed_test_log" ] || ! grep -v '失败' "$speed_test_log" | grep -q '[0-9]'; then
        echo "没有找到有效的测速结果，跳过 ${channel_name}" | tee -a "$summary_file"
        continue
    fi

    # 排序并选择速度最快的源地址
    if grep -E 'MiB/s|KiB/s' "$speed_test_log"; then
        echo "找到 MiB/s|KiB/s, 执行倒序排列" | tee -a "$summary_file"

        awk '{
        if ($1 ~ /MiB\/s/) {
            value = $1;
            sub(/MiB\/s/, "", value);
            value = value * 1024;
            printf "%.2fKiB/s %s\n", value, $2;
        } else {
            print $0;
        }
        }' "$speed_test_log" >speed_temp.log && mv speed_temp.log "$speed_test_log"

        grep -v '失败' "$speed_test_log" | sort -n -r | awk '{print $2 " " $1}' >valid_url.txt
    else
        echo "未找到MiB/s|KiB/s, 执行正序排列" | tee -a "$summary_file"
        grep -v '失败' "$speed_test_log" | sort -n | awk '{print $2 " " $1}' >valid_url.txt
    fi

    best_url=$(head -n 1 valid_url.txt | sed -n 's|.*//\([^/]*\)/.*|\1|p')
    echo "========== 最优源域名: ${best_url}" | tee -a "$summary_file"

    # 获取 best_url 对应的直播源列表
    echo "$best_url 第1页 下载中" | tee -a "$summary_file"
    curl -X POST "${base_url}" \
        -H "Accept-Language: zh-CN,zh;q=0.9" \
        -d "search=${best_url}&Submit=+" \
        -c cookies.txt \
        -o "$best_url_response_file"

    # 提取最大页面数和 l 参数
    max_page=$(grep -oP 'page=\K\d+' "$best_url_response_file" | sort -nr 2>/dev/null | head -n 1)
    l=$(grep -oP "&l=\K[^']*" "$best_url_response_file" | head -n 1)

    # 检查 max_page 是否存在且大于 1
    if [[ -n "$max_page" && "$max_page" -gt 1 ]]; then
        echo "最大 page 值是: ${max_page}" | tee -a "$summary_file"

        # 从第二页开始分页下载
        for page in $(seq 2 "$max_page"); do
            echo "${best_url} 第${page}页 下载中" | tee -a "$summary_file"
            curl -G "${base_url}" \
                -H "Accept-Language: zh-CN,zh;q=0.9" \
                -d "page=${page}" \
                -d "s=${channel_key_url}" \
                -d "l=${l}" \
                -b cookies.txt \
                >>"$best_url_response_file"
        done
    else
        echo "仅此一页" | tee -a "$summary_file"
    fi

    rm cookies.txt
    # 清除已经的文件，NUM不能会导致旧文件无法被覆盖需要手动删除
    ls ../output/${channel_name}*.txt
    rm ../output/${channel_name}*.txt 2>/dev/null
    ls ../output/${channel_name}*.txt
    
    # 提取频道名称和 m3u8 链接
    echo "==== 提取频道名称和 m3u8 链接结果 ======" | tee -a "$summary_file"
    grep -oP '^\s*<div style="float: left;"[^>]*>\K[^<]*(?=</div>)|\s\Khttps?[^<]*' "$best_url_response_file" |
        awk '{
        if ($0 ~ /http/) {
            gsub(/ /, "", $0);
            if (channel != "") {
                print channel "," $0;
            }
        } else {
            channel=$0;
        }
    }' >"$output_file"

    sed -i "1i \\${channel_name},#genre#" "$output_file"
    linescount=$(($(wc -l < "$output_file") - 1))
    NEW_output="${output_file//NUM/$linescount}"
    mv "$output_file" "$NEW_output"

    echo "${channel_name}_$linescount ：${best_url}" >> msg.tmp
    rm $summary_file
    rm ${response_file} ${unique_search_results_file} ${speed_test_log} ${best_url_response_file} ${yt_dlp_log} out.tmp valid_url.txt

done
sed -i "1i $(TZ='Asia/Shanghai' date +%Y/%m/%d/%H:%M:%S)\n港澳台直播源列表已更新: " msg.tmp

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

# bark通知
msg_urlencode=$(urlencode "$(cat msg.tmp)")
curl "https://api.day.app/X7a24UtJyBYFHt5Fma7jpP/github_actions/${msg_urlencode}?isArchive=1"
rm -f msg.tmp

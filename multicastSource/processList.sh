#!/bin/bash
# set -x

# 检查是否提供了输入文件名
if [ -z "$1" ]; then
  echo "用法: $0 <输入文件名>"
  exit 1
fi

# 使用命令行参数作为输入文件名
input_file="$1"
filename=$(basename -- "$input_file")
output_file="${filename%.*}_uniq.${filename##*.}"

cat "$input_file" >"$output_file"
sed -Ei 's/\s/_/g' "$output_file"

# 剔除非有效频道
grep -Pv '单音轨|画中画|购物|测试|健康|调解|#genre#|https?-' "$output_file" >tmp.list && mv tmp.list "$output_file"

# 调整频道数字格式
sed -Ei 's|tv-?([0-9]+)|TV-\1|Ig' "$output_file"

# 统一频道名称
sed -i 's/＋/\+/g; s/(高请|HD|720p)/高清/Ig; s/1080p/超高清/g; s/360p/标清/g; s/fdr/全高清/Ig; s/^央视/CCTV/g; s/^中央/CCTV/g' "$output_file"
sed -Ei 's/(\s|-|_?)(\[?\(?(高清|4K|f?hdr?|超清|超高清|标清|高请|1280|1080|720)\]?\)?.*)(,)/ \2\4/Ig' "$output_file"

# 调整部分数字和名称分割
sed -Ei 's/([0-9][\+＋]?)([^0-9kK\s,+].*)(,)/\1 \2\3/Ig; s/\s+/ /g; s/^\s+//g' "$output_file"
# sed -Ei 's/-([^0-9a-zA-Z])/\1/g' "$output_file"

# 根据频道名称及清晰度去重
# sort -t, -k1.1,1V "$output_file" | awk -F, '!seen[$1]++' >tmp.list && mv tmp.list "$output_file"
# 根据频道名称去重
sort -k1.1,1V "$output_file" | awk 'BEGIN {FS = "[, ]+"} !SEEN[$1]++' >tmp.list && mv tmp.list "$output_file"

# 频道分组
echo '中央电视,#genre#' >tmp
grep -iE 'cctv|央视' "$output_file" | sort -V >>tmp

echo '卫视频道,#genre#' >>tmp
grep -iE '卫视' "$output_file" | sort -V >>tmp

echo '香港,#genre#' >>tmp
grep -iE '凤凰|channel-?v' "$output_file" | sort -V >>tmp

echo '影视剧院,#genre#' >>tmp
grep -iE '电影|电视剧|影院|剧院|剧场|故事|影视|喜剧|大剧|怀旧|谍战|院线' "$output_file" | sort -V >>tmp

echo '4K,#genre#' >>tmp
grep -iE '4K|超高清|全高清' "$output_file" | sort -V >>tmp

echo '动画,#genre#' >>tmp
grep -iE '动画|动漫|少儿|儿童|卡通|炫动|baby|disney|boomerang|cartoon|discovery\s?family|nick' "$output_file" | sort -V >>tmp

echo '教育,#genre#' >>tmp
grep -iE '[^党员]教育|课堂|空中|学习|学堂|中教|科教' "$output_file" | sort -V >>tmp

grep -iv '/cctv|央视|卫视|凤凰|channel-?v|电影|电视剧|影院|剧院|剧场|故事|影视|喜剧|大剧|怀旧|谍战|院线|4K|超高清|全高清|动画|动漫|少儿|儿童|卡通|炫动|baby|disney|boomerang|cartoon|discovery\s?family|nick|[^党员]教育|课堂|空中|学习|学堂|中教|科教/Id' "$output_file" >>tmp
mv tmp "$output_file"

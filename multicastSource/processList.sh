#!/bin/bash
# set -x


# 检查是否提供了输入文件名
if [ -z "$1" ]; then
  echo "用法: $0 <输入文件名>"
  exit 1
fi

# 使用命令行参数作为输入文件名
input_file="$1"
output_file="${filename%.*}_bak.${filename##*.}"



sed -Ei 's/\s/_/g' "$input_file" "$output_file"

# 剔除非有效频道
grep -Pv '单音轨|画中画|购物|测试|#genre#|https?-' "$output_file" >tmp.list && mv tmp.list "$output_file"

# 调整频道数字格式
sed -Ei 's|tv-?([0-9]+)|TV-\1|Ig' "$output_file"

# 统一频道名称
sed -i 's/＋/+/g; s/(高请|HD|720p)/高清/g; s/1080p/超高清/g; s/360p/标清/g; s/fdr/全高清/Ig' "$output_file"
sed -Ei 's/(\s|-|_?)(\[?\(?(高清|4K|f?hdr?|超清|超高清|标清|高请|1280|1080|720)\]?\)?.*)(,)/ \2\4/Ig' "$output_file"

# 调整部分数字和名称分割
sed -Ei 's/([0-9][+＋]?)([^0-9kK\s,].*)(,)/\1 \2\3/Ig; s/\s+/ /g; s/^\s+//g' "$output_file"
sed -Ei 's/-([^0-9a-zA-Z])/\1/g' "$output_file"

# 根据频道名称及清晰度去重
sort -t, -k1.1,1V "$output_file" | awk -F, '!seen[$1]++' > tmp.list && mv tmp.list "$output_file"
# 根据频道名称去重
# sort -k1.1,1V "$output_file" | awk 'BEGIN {FS = "[, ]+"} !SEEN[$1]++' > tmp.list && mv tmp.list "$output_file"

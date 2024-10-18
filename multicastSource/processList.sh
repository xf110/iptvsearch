#!/bin/bash
# set -x

list="$1"

sed -Ei 's/\s/_/g' "$list"

# 剔除非有效频道
grep -Pv '单音轨|画中画|购物|测试|#genre#|https?-' "$list" >tmp.list && mv tmp.list "$list"

# 调整频道数字格式
sed -Ei 's|tv-?([0-9]+)|TV-\1|Ig' "$list"

# 统一频道名称
sed -i 's/＋/+/g; s/(高请|HD|720p)/高清/g; s/1080p/超高清/g; s/360p/标清/g; s/fdr/全高清/Ig' "$list"
sed -Ei 's/(\s|-|_?)(\[?\(?(高清|4K|f?hdr?|超清|超高清|标清|高请|1280|1080|720)\]?\)?.*)(,)/ \2\4/Ig' "$list"

# 调整部分数字和名称分割
sed -Ei 's/([0-9][+＋]?)([^0-9kK\s,].*)(,)/\1 \2\3/Ig; s/\s+/ /g; s/^\s+//g' "$list"
sed -Ei 's/-([^0-9a-zA-Z])/\1/g' "$list"

# 根据频道名称及清晰度去重
sort -t, -k1.1,1V "$list" | awk -F, '!seen[$1]++' > tmp.list && mv tmp.list "$list"
# 根据频道名称去重
# sort -k1.1,1V "$list" | awk 'BEGIN {FS = "[, ]+"} !SEEN[$1]++' > tmp.list && mv tmp.list "$list"

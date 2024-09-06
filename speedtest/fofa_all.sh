#!/bin/bash

# 输出传递的参数
echo "传递的参数: $@"

time=$(date +%m%d%H%M)
i=0

# 如果没有传入参数，则提示用户选择城市
if [ $# -eq 0 ]; then
  echo "请选择城市："
  echo "1. 上海电信（Shanghai_103）"
  echo "2. 北京联通（beijing_unicom_145）"
  echo "3. 四川电信（sichuan_telecom_333）"
  echo "4. 浙江电信（Zhejiang_120）"
  echo "5. 北京电信（Beijing_dianxin_186）"
  echo "6. 江苏（Jiangsu）"
  echo "7. 广东电信（Guangdong_332）"
  echo "8. 河南电信（Henan_327）"
  echo "9. 山西电信（Shanxi_117）"
  echo "10. 天津联通（Tianjin_160）"
  echo "11. 湖北电信（Hubei_90）"
  echo "12. 福建电信（Fujian_114）"
  echo "13. 湖南电信（Hunan_282）"
  echo "14. 甘肃电信（Gansu_105）"
  echo "15. 河北联通（Hebei_313）"
  echo "0. 全部"
  read -t 10 -p "输入选择或在10秒内无输入将默认选择全部: " city_choice

  # 显示用户选择
  echo "用户选择: $city_choice"

  if [ -z "$city_choice" ]; then
      echo "未检测到输入，自动选择全部选项..."
      city_choice=0
  fi

else
  city_choice=$1
fi

# 显示最终选择
echo "最终选择: $city_choice"

# 根据用户选择设置城市和相应的stream
case $city_choice in
    1)
        city="Shanghai_103"
        stream="udp/239.45.1.4:5140"
        channel_key="上海"
        url_fofa=$(echo  '"udpxy" && country="CN" && region="Shanghai" && org="China Telecom Group" && protocol="http"' | base64 |tr -d '\n')
        url_fofa="https://fofa.info/result?qbase64="$url_fofa
        ;;
    2)
        city="beijing_unicom_145"
        stream="rtp/239.3.1.236:2000"
        channel_key="北京联通"
        url_fofa=$(echo  '"udpxy" && country="CN" && region="Beijing" && org="China Unicom Beijing Province Network" && protocol="http"' | base64 |tr -d '\n')
        url_fofa="https://fofa.info/result?qbase64="$url_fofa
        ;;
    3)
        city="sichuan_telecom_333"
        stream="udp/239.93.42.33:5140"
        channel_key="四川电信"
        url_fofa=$(echo  '"udpxy" && country="CN" && region="Sichuan" && protocol="http"' | base64 |tr -d '\n')
        url_fofa="https://fofa.info/result?qbase64="$url_fofa
        ;;
    # 其他城市省略，按相同结构继续配置
    0)
        # 选择全部选项，逐个处理每个选项
        for option in {2,3,16}; do
          echo "递归调用脚本，选择: $option"
          bash "$0" $option
        done
        exit 0
        ;;
    *)
        echo "错误：无效的选择。选择值为: $city_choice"
        exit 1
        ;;
esac

ipfile="ip/${city}.ip"
only_good_ip="ip/${city}.onlygood.ip"
rm -f $only_good_ip

echo "===============从 fofa 检索 ip+端口================="
curl -o test_${city}.html "$url_fofa"
grep -E '^\s*[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$' test_${city}.html | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+' > "$ipfile"
rm -f test_${city}.html

# 遍历 IP 地址并测试
while IFS= read -r ip; do
    tmp_ip=$(echo -n "$ip" | sed 's/:/ /')
    output=$(nc -w 1 -v -z $tmp_ip 2>&1)
    if [[ $output == *"succeeded"* ]]; then
        echo "$output" | grep "succeeded" | awk -v ip="$ip" '{print ip}' >> "$only_good_ip"
    fi
done < "$ipfile"

echo "===============检索完成================="

# 检查文件
if [ ! -f "$only_good_ip" ]; then
    echo "错误：文件 $only_good_ip 不存在。"
    exit 1
fi

lines=$(wc -l < "$only_good_ip")
echo "【$only_good_ip】内 ip 共计 $lines 个"

time=$(date +%Y%m%d%H%M%S)
i=0
while IFS= read -r line; do
    i=$((i + 1))
    ip="$line"
    url="http://$ip/$stream"
    curl "$url" --connect-timeout 3 --max-time 10 -o /dev/null >zubo.tmp 2>&1
    a=$(head -n 3 zubo.tmp | awk '{print $NF}' | tail -n 1)

    echo "第 $i/$lines 个：$ip $a"
    echo "$ip $a" >> "speedtest_${city}_$time.log"
done < "$only_good_ip"

rm -f zubo.tmp
awk '/M|k/{print $2"  "$1}' "speedtest_${city}_$time.log" | sort -n -r >"result/result_fofa_${city}.txt"
cat "result/result_fofa_${city}.txt"
rm -f "speedtest_${city}_$time.log"

echo "处理完成，合并结果为: zubo_fofa.txt"
cat result/*.txt > zubo_fofa.txt

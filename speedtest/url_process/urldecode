#!/bin/bash
# 使用时命令行传递参数即可： urldecode.sh "fwq000%20url_process"
urldecode() {
    # urldecode <string>
    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}
urldecode "$1"

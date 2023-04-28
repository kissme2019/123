#!/bin/bash

# 定义要测试的IP地址段
ip_blocks=(
    "173.245.48.0/20"
    "103.21.244.0/22"
    "103.22.200.0/22"
    "103.31.4.0/22"
    "141.101.64.0/18"
    "108.162.192.0/18"
    "190.93.240.0/20"
    "188.114.96.0/20"
    "197.234.240.0/22"
    "198.41.128.0/17"
    "162.158.0.0/15"
    "104.16.0.0/13"
    "104.24.0.0/14"
    "172.64.0.0/13"
    "131.0.72.0/22"
)

# 定义测试结果存放数组
declare -A results

# 循环测试每个IP段的IP地址
for block in "${ip_blocks[@]}"
do
    # 提取IP地址段和掩码
    ip=$(echo "$block" | cut -d/ -f1)
    mask=$(echo "$block" | cut -d/ -f2)

    # 使用fping命令测试IP地址段内的所有IP地址
    # -S选项指定源IP地址
    # -q选项忽略输出结果
    # -c选项指定测试次数
    # -t选项指定超时时间
    # -i选项指定间隔时间
    # -b选项指定批处理模式，以提高效率
    # -a选项只显示存活的主机
    # -r选项指定将结果输出为数字形式的区间
    # 注意：fping命令需要先安装
    fping -S 192.168.0.8 -q -c 5 -t 100 $ip/$mask -i 100 -b -a -r 0 >> /dev/null &

    # 将每个IP地址段测试结果保存到字典中
    results["$block"]=$!
done

# 等待所有测试完成
wait

# 循环处理每个IP地址段的测试结果
for block in "${ip_blocks[@]}"
do
    # 提取测试结果
    # $?获取前面命令的退出状态，0表示没有丢包
    # awk是一个文本处理工具，$NF表示最后一列，{}中是条件判断和输出语句
    # shift命令将命令行参数左移
    # 此处使用了管道符和重定向来进行文本处理
    loss=$(grep -oP '(?<=\().*?(?=%)' "fping.${results[$block]}" | awk '{if($NF=="0%") {print $0}}' | head -1)
    latency=$(grep -oP '(?<=\=).*' "fping.${results[$block]}" | awk '{print substr($0,1,length($0)-2)}' | sort -n | head -1)

    # 计算结果
    metrics=""
    if [ -n "$loss" ]; then
        metrics="$metrics$loss "
    else
        metrics="$metrics- "
    fi
    if [ -n "$latency" ]; then
        metrics="$metrics$latency"
    else
        metrics="$metrics-"
    fi

    # 输出结果
    echo "$block: $metrics"
done

# 删除临时文件
rm -f fping.*

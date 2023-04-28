#!/bin/bash

# 定义待测试的 IP 地址列表
ip_list=(
173.245.48.0/20
103.21.244.0/22
103.22.200.0/22
103.31.4.0/22
141.101.64.0/18
108.162.192.0/18
190.93.240.0/20
188.114.96.0/20
197.234.240.0/22
198.41.128.0/17
162.158.0.0/15
104.16.0.0/13
104.24.0.0/14
172.64.0.0/13
131.0.72.0/22
)

# 定义测试线程数
max_threads=10

# 定义结果数组
result=()

# 定义测试过程，用 ping 命令测试延迟和丢包率
test_ip() {
    ip=$1
    ping_result=$(ping -c3 -q $ip)
    loss_rate=$(echo "$ping_result" | grep -oP '\d+(?=% packet loss)')
    delay=$(echo "$ping_result" | grep -oP '\d+\.\d+(?=\/ms)' | sort -n | head -n 1)

    # 把测试结果添加到结果数组中
    result+=("$ip,$loss_rate,$delay")
}

# 使用循环和多线程技术测试所有的 IP 地址
running_threads=0
for ip in "${ip_list[@]}"; do
    # 如果线程数达到上限，等待已有线程结束
    while [ $running_threads -ge $max_threads ]; do
        sleep 1
        running_threads=$(jobs -r | wc -l)
    done

    # 启动一个新线程测试一个 IP 地址
    test_ip $ip & 

    running_threads=$(jobs -r | wc -l)
done

# 等待所有线程结束
wait

# 找出丢包率最低并且延迟相对最低的 IP 地址
best_ip=""
lost_rate=100
delay=10000
for r in "${result[@]}"; do
    ip=$(echo $r | cut -d',' -f1)
    l=$(echo $r | cut -d',' -f2)
    d=$(echo $r | cut -d',' -f3)

    if [ $(echo "$l<=$lost_rate" | bc) -eq 1 ] && [ $(echo "$d<=$delay" | bc) -eq 1 ]; then
        best_ip=$ip
        lost_rate=$l
        delay=$d
    fi
done

echo "Best IP: $best_ip, Loss Rate: $lost_rate%, Delay: $delay ms"

#!/bin/bash

# Define the subnet list to test
subnets=( "173.245.48.0/20" "103.21.244.0/22" "103.22.200.0/22" "103.31.4.0/22" "141.101.64.0/18" "108.162.192.0/18" "190.93.240.0/20" "188.114.96.0/20" "197.234.240.0/22" "198.41.128.0/17" "162.158.0.0/15" "104.16.0.0/13" "104.24.0.0/14" "172.64.0.0/13" "131.0.72.0/22" )

# Define the number of ping packets and the timeout period
num_packets=10
timeout_period=1

# Define a function to test the subnet
test_subnet() {
    subnet=$1
    ping_result=$(ping -c $num_packets -W $timeout_period $subnet)
    packet_loss=$(echo "$ping_result" | awk '/packet loss/ {print $6}' | cut -d'%' -f1)
    avg_latency=$(echo "$ping_result" | awk '/avg/ {print $4}' | cut -d'/' -f2)

    echo "$subnet packet_loss: $packet_loss, avg_latency: $avg_latency"

    # Output format: <subnet> <packet_loss> <avg_latency>
    echo $subnet $packet_loss $avg_latency >> temp.txt
}

# Create an empty temp file to record the test results
> temp.txt

# Test each subnet using multiple threads
for subnet in "${subnets[@]}"; do
  test_subnet "$subnet" &
done

# Wait for all tests to finish
wait

# Sort the results by packet loss and average latency, and output the best subnet
best_subnet=$(sort -k2n,2 -k3n,3 temp.txt | head -n 1)
echo "Best subnet: $best_subnet"

# Delete the temp file
rm temp.txt

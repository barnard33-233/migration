#!/bin/bash

# @Gemini

# This script pins all threads (LWP) of a target user's QEMU processes
# to a predefined list of host CPU cores.

# --- CONFIGURATION SECTION ---
# Target username running the QEMU processes
TARGET_USER="mohan"

# List of host CPU cores for pinning.
# These should ideally be isolated cores (using isolcpus/cgroups).
# The script will cycle through this list if the number of threads exceeds
# the list length.
# CPU_CORES=(32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63)
CPU_CORES=(48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63)

# --- CORE LOGIC ---

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run with root privileges (sudo) for taskset operations."
   exit 1
fi

echo "--- STARTING QEMU THREAD PINNING TASK ---"
echo "Target User: ${TARGET_USER}"
echo "Pinning Core List Length: ${#CPU_CORES[@]}"
echo "-----------------------------------------"

# Initialize core index
core_index=0
total_threads_pinned=0

# 1. Find all QEMU process PIDs for the target user
QEMU_PIDS=$(pgrep -u "${TARGET_USER}" -f "qemu-system")

if [ -z "$QEMU_PIDS" ]; then
    echo "INFO: No QEMU processes found running for user ${TARGET_USER}."
    exit 0
fi

# 2. Iterate through each QEMU process
for qemu_pid in ${QEMU_PIDS}; do
    echo "PROCESSING QEMU main process PID: ${qemu_pid}"

    # 3. Find ALL TIDs under this QEMU process
    ALL_TIDS=$(ps -Tp "${qemu_pid}" -o tid | tail -n +2)
    
    if [ -z "$ALL_TIDS" ]; then
        echo "   WARNING: No threads found under process ${qemu_pid}. Skipping."
        continue
    fi

    echo "   Number of threads found: $(echo ${ALL_TIDS} | wc -w)"

    # 4. Iterate through all threads and perform pinning
    for thread_tid in ${ALL_TIDS}; do
        
        # Check if the core list has been exhausted (optional warning)
        if [ $core_index -ge ${#CPU_CORES[@]} ]; then
            echo "   WARNING: Core list exhausted. Subsequent threads will cycle or stop pinning."
        fi

        # Get the host core number to pin to (using modulo for cycling)
        host_core=${CPU_CORES[core_index % ${#CPU_CORES[@]}]}

        # Execute taskset pinning
        taskset -p -c "${host_core}" "${thread_tid}" > /dev/null 2>&1
        
        # Check if taskset was successful
        if [ $? -eq 0 ]; then
            echo "   SUCCESS: TID ${thread_tid} pinned to host core ${host_core}"
            total_threads_pinned=$((total_threads_pinned + 1))
        else
            echo "   FAILED: TID ${thread_tid} pinning to host core ${host_core} failed!"
        fi

        # Move to the next core
        core_index=$((core_index + 1))
    done
done

echo "-----------------------------------------"
echo "COMPLETED. Total threads pinned: ${total_threads_pinned}"
echo "-----------------------------------------"

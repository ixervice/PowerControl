 #!/bin/bash

function set_cpu_Freq()
{
    cpu_index=$1
    let cpu_freq=$2
    if(($cpu_index==0));then
        cpu_isOnLine=1
    else
        cpu_isOnLine=$(cat /sys/devices/system/cpu/cpu${cpu_index}/online)
    fi
    if(($cpu_freq==0));then
        if((cpu_isOnLine==0));then
            sudo echo 1 > "/sys/devices/system/cpu/cpu${cpu_index}/online"
            sudo echo "schedutil" > "/sys/devices/system/cpu/cpu${cpu_index}/cpufreq/scaling_governor"
            sudo echo 0 > "/sys/devices/system/cpu/cpu${cpu_index}/online"
        else
            sudo echo "schedutil" > "/sys/devices/system/cpu/cpu${cpu_index}/cpufreq/scaling_governor"
        fi
    else
        if((cpu_isOnLine==0));then
            sudo echo 1 > "/sys/devices/system/cpu/cpu${cpu_index}/online"
            sudo echo "userspace" > "/sys/devices/system/cpu/cpu${cpu_index}/cpufreq/scaling_governor"
            sudo echo $cpu_freq > "/sys/devices/system/cpu/cpu${cpu_index}/cpufreq/scaling_max_freq"
            sudo echo 0 > "/sys/devices/system/cpu/cpu${cpu_index}/online"
        else
            sudo echo "userspace" > "/sys/devices/system/cpu/cpu${cpu_index}/cpufreq/scaling_governor"
            sudo echo $cpu_freq > "/sys/devices/system/cpu/cpu${cpu_index}/cpufreq/scaling_max_freq"
        fi
    fi
}

function get_cpu_nowFreq()
{
    cpu_index=$1
    echo "$(cat /sys/devices/system/cpu/cpufreq/policy${cpu_index}/scaling_cur_freq)"
}

function get_cpu_AvailableFreq()
{
    echo "$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_available_frequencies)"
}

function set_cpu_online()
{
    cpu_index=$1
    cpu_online=$2
    echo $cpu_online > "/sys/devices/system/cpu/cpu${cpu_index}/online"
}

function get_cpuID()
{
    lscpu | grep "Model name" | sed -n '1p'| cut -d : -f 2 | xargs
}

function set_cpu_tdp()
{
    let slow=$1*1000
    let fast=$2*1000
    sudo ../plugins/PowerControl/bin/ryzenadj --stapm-limit=$fast --fast-limit=$fast --slow-limit=$fast --tctl-temp=100
    sudo echo "../plugins/PowerControl/bin/ryzenadj  --stapm-limit=${fast} --fast-limit=${fast}   --slow-limit=${slow}" >>  /tmp/powertools-sh.log
}

function set_clock_limits()
{
    let min=$1
    let max=$2
    if(($min==0 || $max==0));then
        sudo echo "auto">/sys/class/drm/card0/device/power_dpm_force_performance_level
    else
        sudo echo "manual">/sys/class/drm/card0/device/power_dpm_force_performance_level
        sudo echo "s 0 ${min}" > /sys/class/drm/card0/device/pp_od_clk_voltage
        sudo echo "s 1 ${max}" > /sys/class/drm/card0/device/pp_od_clk_voltage
        sudo echo "c" > /sys/class/drm/card0/device/pp_od_clk_voltage
    fi
    sudo echo "gpu_clock_limit "$1 $2 >> /tmp/powerControl-sh.log
}

function get_gpu_FreqMinLimit()
{
    echo "$(sudo cat /sys/class/drm/card0/device/pp_dpm_sclk|grep "0:"|awk '{print $2}'|sed -e  's/Mhz//g')"
}

function get_gpu_FreqMaxLimit()
{
    echo "$(sudo cat /sys/class/drm/card0/device/pp_dpm_sclk|grep "2:"|awk '{print $2}'|sed -e  's/Mhz//g')"
}

function set_gpu_flk()
{
    flk=$1
    index=$(((1600-$flk)/400))
    now_mode=$(cat /sys/class/drm/card0/device/power_dpm_force_performance_level)
    sudo chmod 777  /sys/class/drm/card0/device/pp_dpm_fclk
    if [[ "$now_mode"!="manual" ]];then
        sudo echo "manual" >/sys/class/drm/card0/device/power_dpm_force_performance_level
        sudo echo "$index" >/sys/class/drm/card0/device/pp_dpm_fclk
    else
        sudo echo "$index" > /sys/class/drm/card0/device/pp_dpm_fclk
    fi
    sudo echo "gpu_flk_limit " $index >> /tmp/powerControl-sh.log
}


function check_clock_limits()
{
    mode=$1
    now_mode=$(cat /sys/class/drm/card0/device/power_dpm_force_performance_level)
    if [[ "$now_mode"!="$mode" ]];then
        if(( "$1" == "manual"));then
            sudo echo "manual" >/sys/class/drm/card0/device/power_dpm_force_performance_level
            sudo echo "s 0 $2" > /sys/class/drm/card0/device/pp_od_clk_voltage
            sudo echo "s 1 $3" > /sys/class/drm/card0/device/pp_od_clk_voltage
            sudo echo "c" > /sys/class/drm/card0/device/pp_od_clk_voltage
        else
            sudo echo "auto" >/sys/class/drm/card0/device/power_dpm_force_performance_level
        fi
    fi
}

function set_cpu_boost()
{
    boost=$1
    if (($boost == 1)); then
        echo 1 > "/sys/devices/system/cpu/cpufreq/boost"
    else
        echo 1 > "/sys/devices/system/cpu/cpufreq/boost"
        echo 0 > "/sys/devices/system/cpu/cpufreq/boost"
    fi
}


 if [ -n "$1" ]; then
    case "$1" in
    set_cpu_online)set_cpu_online $2 $3;;
    set_cpu_Freq)set_cpu_Freq $2 $3;;
    get_cpu_nowFreq)get_cpu_nowFreq $2;;
    get_cpu_AvailableFreq)get_cpu_AvailableFreq $2 $3;;
    set_cpu_tdp)set_cpu_tdp $2 $3 ;;
    set_clock_limits)set_clock_limits $2 $3;;
    set_cpu_boost)set_cpu_boost $2;;
    check_clock_limits)check_clock_limits $2 $3 $4;;
    set_gpu_flk)set_gpu_flk $2;;
    get_cpuID)get_cpuID;;
    get_gpu_FreqMinLimit)get_gpu_FreqMinLimit;;
    get_gpu_FreqMaxLimit)get_gpu_FreqMaxLimit;;
    *)sudo echo $1 $2 $3 $4>>  /tmp/powerControl-sh.log;;
    esac
fi

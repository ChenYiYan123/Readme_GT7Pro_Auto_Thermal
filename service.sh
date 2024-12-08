#!/system/bin/sh
MODDIR=${0%/*}

# 延迟启动
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 3
done

# 修改温度墙
echo '95000' > ${MODDIR}/temp
for temp in /sys/class/thermal/thermal_zone*/trip_point_*_temp; do
  if [ "$(cat "$temp")" -gt 85000 ]; then
    mount -o make,bind ${MODDIR}/temp "$temp"
  fi
done

# 定义一个函数用于设置伪装温度
temp() {
  stop horae
  echo "0 36000" > /proc/shell-temp
  echo "1 36000" > /proc/shell-temp
  echo "2 36000" > /proc/shell-temp
  echo "3 36000" > /proc/shell-temp
}

# 目标应用包名
TARGET_APP="com.oplus.camera"

# 状态记录变量
LAST_STATE="stopped"

# 持续检测循环
while true; do
    # 获取当前前台窗口的包名
    FOREGROUND_APP=$(dumpsys window | grep -E 'mCurrentFocus' | awk -F '/' '{print $1}' | awk '{print $NF}')

    if [ "$FOREGROUND_APP" = "$TARGET_APP" ] && [ "$LAST_STATE" != "running" ]; then
        # 应用切换到前台
        LAST_STATE="running"
        start horae
    elif [ "$FOREGROUND_APP" != "$TARGET_APP" ] && [ "$LAST_STATE" != "stopped" ]; then
        # 应用不在前台
        LAST_STATE="stopped"
        temp
    fi

    # 延迟 1 秒再检测
    sleep 1
done
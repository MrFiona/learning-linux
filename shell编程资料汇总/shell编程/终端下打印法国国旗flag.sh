#!/bin/bash

declare -i MAX_COL_NUM
declare -i MAX_ROW_NUM

declare -i START_ROW=1
declare -i START_COL=1

flag_init()
{
        echo -ne "\033[2J"
        MAX_ROW_NUM=`stty size|cut -d " " -f 1`
        MAX_COL_NUM=`stty size|cut -d " " -f 2`
        echo $MAX_ROW_NUM $MAX_COL_NUM
}

flag_draw_single()
{
        local i j

        i=$1
        for ((j = $2; j <= $3; j++))
        do
                echo -e "\033[${i};${j}H\033[$4;31m \033[0m"
        done
}

flag_draw()
{
        local i j

        for i in `seq 2 $((MAX_ROW_NUM-1))`
        do
                k=$((MAX_COL_NUM/3))
                flag_draw_single $i 0 $k 44
                flag_draw_single $i $k $((k*2)) 47
                flag_draw_single $i $((k*2)) $((k*3 - 1)) 41
        done
}

flag_init
flag_draw
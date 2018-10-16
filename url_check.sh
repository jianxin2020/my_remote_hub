#!/bin/bash
. /etc/init.d/functions  #引入系统函数库
function usage(){
    echo $"usage: $0 url"
    return 1
}
function check_url(){
    #echo $1
    wget --spider -q -o /dev/null --tries=1 -T 5 $1
    #--spider which means that it will not download the pages, just check that they are there.
    #-q 不显示指令执行过程
    #-o --output-file=logfile
    #--tries=1 尝试次数
    #-T timeout seconds 超时时间
    if  [ $? -eq 0 ]
        then
            action "$1 is yes"  /bin/true
        else
            action "$1 is error"  /bin/false
    fi    
}
function main(){
    #echo $#
    if [ $# -ne 1 ]
        then
            usage
        else
            check_url $1        
    fi
}
main $*





cat /etc/passwd | awk -F":" 'BEGIN{a[1]="a1";a[2]="a2";b[1]="b1"}END{for(i in a){if(b[i]==""){b[i]=0};print i,a[i],b[i]}}'

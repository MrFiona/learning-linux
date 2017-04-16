#!/bin/bash
#ShellName:LazyManage.sh
#Conf:serverlist.conf
#By:peter.li
#2013-06-06
#http://hi.baidu.com/quanzhou722/item/4ccf7e88a877eaccef083d1a

LANG="en_US.UTF-8"

while true
do

Set_Variable(){

ServerList=serverlist.conf
Port=22
TimeOut="-1"
Task=20

RemoteUser="peterli"
RemotePasswd="123456"
RemoteRootPasswd="xuesong"
KeyPasswd=""

ScpPath="/root/lazy.txt"
ScpRemotePath="/tmp/"
ScriptPath="Remote.sh"
}

System_Check(){

#Kill the CTRL + z sleep process
if [ "$1" == kill ];then
	ps -eaf |awk '$NF~/.*'${0##*/}'/&&$6~/tty|pts.*/{print $2}' |xargs -t -i kill -9 {}
	exit
fi

#Check the configuration file
if [ ! -s serverlist.conf ];then
	echo "error:IP list serverlist.conf file does not exist or is null"
	exit
fi


#rpm check
for i in dialog expect
do
	rpm -q $i >/dev/null
	[ $? -ge 1 ] && echo "$i does not exist,Please root yum -y install $i to install,exit" && exit
done

#The current user
#LazyUser=`whoami`

#System parameters
#BitNum=`getconf LONG_BIT`
#SystemNum=`lsb_release -a|grep Release |awk '{print $2}'`

}

Select_Type() {
while true
do
clear
	case $Operate in
	1)
		Type=`dialog --no-shadow --stdout --backtitle "LazyManage" --title "System work content"  --menu "select" 10 60 0 \
		1a "[Common operations]" `
	;;
	2)
		Type=`dialog --no-shadow --stdout --backtitle "LazyManage" --title "Custom work content"  --menu "select" 10 60 0 \
		1b "[web upgrade]" \
		2b "[db   manage]" `
	;;
	esac
	[ $? -eq 0 ] && Select_Work $Type || break
done
}

Select_Work() {
while true
do
clear
	case $Type in
	1a)
		Work=`dialog --no-shadow  --stdout --backtitle "LazyManage" --title "Common operations" --menu "select" 20 60 0 \
		1aa "[custom cmd ]" \
		2aa "[scp file   ]" \
		3aa "[exec script]" `
	;;
	1b)
		Work=`dialog --no-shadow  --stdout --backtitle "LazyManage" --title "web upgrade" --menu "select" 20 60 0 \
		1ba "[job1]" \
		2ba "[job2]" \
		3ba "[job3]" `
	;;
	2b)
		Work=`dialog --no-shadow  --stdout --backtitle "LazyManage" --title "db   manage" --menu "select" 20 60 0 \
		1bb "[job1]" \
		2bb "[job2]" \
		3bb "[job3]" `
	;;
	esac
	[ $? -eq 0 ] && Get_Ip $Work || break
done
}

Get_Ip(){
while true
do
clear
case $Work in
[1-9]a[a-z])
	List=`awk '$1!~"^#"&&$1!=""{print $1" "$1" on"}' $ServerList`
;;
1ba)
	List=`awk '$1!~"^#"&&$1!=""&&$2=="job1"&&$3=="web"{print $1" "$2"_"$3" on"}' $ServerList`
;;
2ba)
	List=`awk '$1!~"^#"&&$1!=""&&$2=="job2"&&$3=="web"{print $1" "$2"_"$3" on"}' $ServerList`
;;
3ba)
	List=`awk '$1!~"^#"&&$1!=""&&$2=="job3"&&$3=="web"{print $1" "$2"_"$3" on"}' $ServerList`
;;
1bb)
	List=`awk '$1!~"^#"&&$1!=""&&$2=="job1"&&$3=="db"{print $1" "$2"_"$3" on"}' $ServerList`
;;
2bb)
	List=`awk '$1!~"^#"&&$1!=""&&$2=="job2"&&$3=="db"{print $1" "$2"_"$3" on"}' $ServerList`
;;
3bb)
	List=`awk '$1!~"^#"&&$1!=""&&$2=="job3"&&$3=="db"{print $1" "$2"_"$3" on"}' $ServerList`
;;
*)
	echo "Dialog list does not exist"
	break
;;
esac

IpList=`dialog --no-shadow  --stdout --backtitle "LazyManage" --title "ip list" --separate-output --checklist "select IP" 0 60 0 $List`
[ $? -eq 0 ]  || break 

Message=`cat <<EOF

Please make sure the information
========================

$IpList

========================
EOF`

dialog --backtitle "LazyManage" --title "Confirm IP" --no-shadow --yesno "$Message" 20 60
[ $? -eq 0 ] && Perform || break

done
}

Perform(){
	mkdir -p ./lazyresult
	echo "============= `date +%Y-%m-%d_%H:%M` =============" >>./lazyresult/lazy.log
	case $Work in
	1aa)
		echo -e '\e[35mPlease enter the custom command[backapace=ctrl+backapace]: \e[m'
		while read Cmd
		do
			if [ X"$Cmd" != X ];then
				break
			fi
			echo 'Please type the command again[backapace=ctrl+backapace]'
		done
		echo "Custom_Cmd ${Cmd}">>./lazyresult/lazy.log
		More_Thread Interactive_Auth Ssh_Cmd
	;;
	2aa)
		if [ ! -e ${ScpPath} ];then
			echo "${ScpPath} file or directory does not exist "
			read
			break
		fi
		echo "Scp_File ${ScpPath}-${ScpRemotePath}">>./lazyresult/lazy.log
		More_Thread Interactive_Auth Scp_File
	;;
	3aa)
		echo "Exec_Script ${ScriptPath}">>./lazyresult/lazy.log
		More_Thread Interactive_Auth Ssh_Script
	;;
	[1-9]ba)
		echo "custom"
	;;
	[1-9]bb)
		echo "custom"
	;;

	*)
		echo "Dialog list does not exist"
		break
	;;
	esac
	
	echo "Operation is complete "
	read
}

More_Thread(){
for Ip in $IpList
do
	((num++))
	$1 $2 |awk 'BEGIN{RS="(expect_start|expect_eof|expect_failure)"}END{print $0}' |tee -a ./lazyresult/lazy.log &
	if [ $num -eq $Task ];then
	wait
	num=0
	fi
done
wait
num=0
}

Interactive_Auth(){
#RemoteRootPasswd=`awk '$1=='$Ip'{print $5}' $ServerList`

/usr/bin/expect -c "
proc jiaohu {} {
	send_user expect_start
	expect {
		password {
			send ${RemotePasswd}\r;
			send_user expect_eof
			expect {
				\"does not exist\" {
					send_user expect_failure
					exit 10
				}
				password {
					send_user expect_failure
					exit 5
				}
				Password {
					send ${RemoteRootPasswd}\r;
					send_user expect_eof
					expect {
						incorrect {
							send_user expect_failure
							exit 6
						}
						eof 
					}
				}
				eof
			}
		}
		passphrase {
			send ${KeyPasswd}\r;
			send_user expect_eof
			expect {
				\"does not exist\" {
					send_user expect_failure
					exit 10
				}
				passphrase{
					send_user expect_failure
					exit 7
				}
				Password {
					send ${RemoteRootPasswd}\r;
					send_user expect_eof
					expect {
						incorrect {
							send_user expect_failure
							exit 6
						}
						eof
					}
				}
				eof
			}
		}
		Password {
			send ${RemoteRootPasswd}\r;
			send_user expect_eof
			expect {
				incorrect {
					send_user expect_failure
					exit 6
				}
				eof
			}
		}
		\"No route to host\" {
			send_user expect_failure
			exit 4
		}
		\"Invalid argument\" {
			send_user expect_failure
			exit 8
		}
		\"Connection refused\" {
			send_user expect_failure
			exit 9
		}
		\"does not exist\" {
			send_user expect_failure
			exit 10
		}
		timeout {
			send_user expect_failure
			exit 3
		}
		eof
	}
}

set timeout $TimeOut
switch $1 {
	Ssh_Cmd {
		spawn ssh -t -p $Port -o StrictHostKeyChecking=no $RemoteUser@$Ip /bin/su - root -c \\\"$Cmd\\\"
		jiaohu
	}
	Ssh_Script {
		spawn scp -P $Port -o StrictHostKeyChecking=no $ScriptPath $RemoteUser@$Ip:/tmp/${ScriptPath##*/};
		jiaohu
		spawn ssh -t -p $Port -o StrictHostKeyChecking=no $RemoteUser@$Ip /bin/su - root -c  \\\"/bin/sh /tmp/${ScriptPath##*/}\\\" ;
		jiaohu
	}
	Scp_File {
		spawn scp -P $Port -o StrictHostKeyChecking=no -r $ScpPath $RemoteUser@$Ip:${ScpRemotePath};
		jiaohu
	}
}
"
case $? in
0)
	echo -e "\e[32m$Ip------------------------OK \e[m"
;;
1|2)
	echo -e "\e[31m$Ip:expect grammar or unknown error \e[m"
	echo -e "\e[31m$Ip------------------------failure \e[m"
;;
3)
	echo -e "\e[31m$Ip:connection timeout \e[m"
	echo -e "\e[31m$Ip------------------------failure \e[m"
;;
4)
	echo -e "\e[31m$Ip:host not found \e[m"
	echo -e "\e[31m$Ip------------------------failure \e[m"
;;
5)
	echo -e "\e[31m$Ip:user passwd error \e[m"
	echo -e "\e[31m$Ip------------------------failure \e[m"
;;
6)
	echo -e "\e[31m$Ip:root passwd error \e[m"
	echo -e "\e[31m$Ip------------------------failure \e[m"
;;
7)
	echo -e "\e[31m$Ip:key passwd error \e[m"
	echo -e "\e[31m$Ip------------------------failure \e[m"
;;
8)
	echo -e "\e[31m$Ip:ssh parameter not correct \e[m"
	echo -e "\e[31m$Ip------------------------failure \e[m"
;;
9)
	echo -e "\e[31m$Ip:ssh invalid port parameters \e[m"
	echo -e "\e[31m$Ip------------------------failure \e[m"
;;
10)
	echo -e "\e[31m$Ip:root user does not exist \e[m"
	echo -e "\e[31m$Ip------------------------failure \e[m"
;;
esac

}

trap "" 2 3

System_Check $1

Set_Variable

#Script entrance
Operate=`dialog --no-shadow --stdout --backtitle "LazyManage" --title "manipulation menu"  --menu "select" 10 60 0 \
1 "[system operate]" \
2 "[custom operate]" `
[ $? -eq 0 ] && Select_Type $Operate || exit

done

#End



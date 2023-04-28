#!/bin/bash
#这是一键更新的脚本

#写一个控制选项界面(是多级，比如备份的话，备份哪个？提示“当前是在XX服务器，你要全部备份吗？或者备份1 备份2)
# blue 1.一键备份
# blue 2.更新XPE
# blue 3.更新SBC
# blue 4.更新开户
# blue 5.更新商城
# blue 6.更新SUIT
# blue 7.回滚上一个版本
# blue 8.查看当前备份的文件
# blue 9.一键killtomcat
# blue 10.一键重启tomcat
# blue 11.清理日志
# blue 0.退出

#舍弃
# #写入对应关系表（一一对应）：
# cat /dev/null >/root/ip.txt
# cat > /root/ip.txt << EOF
# 跳板机:10.88.66.152
# 网厅:10.88.66.138
# 开户:10.88.66.200
# xpe:10.88.66.201
# 商城:10.88.66.155
# 电子协议:10.88.66.154
# EOF



#先写功能函数

#颜色提示函数
#基佬紫 
purple(){
echo -e "\\033[35;1m${*}\\033[0m"
} 

#天依蓝
tyblue(){
echo -e "\\033[36;1m${*}\\033[0m"
} 

#原谅绿
green(){
echo -e "\\033[32;1m${*}\\033[0m"
}

#鸭屎黄
yellow(){
echo -e "\\033[33;1m${*}\\033[0m"
} 

#姨妈红
red(){
echo -e "\\033[31;1m${*}\\033[0m" 
} 

#蓝色
blue() {
echo -e "\\033[34;1m${*}\\033[0m"
}




#核心函数，得到要操作的文件列表，并且对比出当前服务器的名字
#操作列表函数

list(){

#写个数组，比如网厅要备份什么文件、开户要备份什么文件、商城、xpe要备份什么文件  列个表格出来，这个是固定的，然后跟bf查找到的列表进行对比，输出重复的文件，再把重复的文件拿来备份或者更新 

#WTQYB
wtqyblist=(/usr/local/WTQYB/wt-mobile /usr/local/WTQYB/xpe-products-wt-backend-static /usr/local/WTQYB/xpe-products-wt-front-static)
#网厅
wtlist=(/usr/local/tomcat/apache-tomcat-sbc-api /usr/local/tomcat/apache-tomcat-sbc-flow /usr/local/tomcat/apache-tomcat-sbc-web /usr/local/tomcat/apache-tomcat-wt-api)
#开户
khlist=(/usr/local/tomcat/apache-tomcat-kh /usr/local/tomcat/apache-tomcat-khgl /usr/local/tomcat/apache-tomcat-sjkh2 /usr/local/tomcat/apache-tomcat-sjkh)
#XPE
xpelist=(/usr/local/tomcat/apache-tomcat-config /usr/local/tomcat/apache-tomcat-suit-backend /usr/local/tomcat/apache-tomcat-video /usr/local/tomcat/apache-tomcat-sisap)
#商城
sclist=(/usr/local/tomcat/apache-tomcat-config /usr/local/tomcat/apache-tomcat-rzzx /usr/local/tomcat/apache-tomcat-mall-backend /usr/local/tomcat/apache-tomcat-suit-backend /usr/local/tomcat/apache-tomcat-sjsc /usr/local/tomcat/apache-tomcat-sisap)


#echo ${wtqyblist[*]} |sed 's/;/\n/g' |sort |uniq 


#汇总数组，把上面的服务器目录汇总
sz_list=(${wtqyblist[*]} ${wtlist[*]} ${khlist[*]} ${xpelist[*]} ${sclist[*]})
#调用${list([*])}| sed 's/ /;/g'| sed 's/;/\n/g'

#得到对照列表,现在所有的”数“都以 分割 用的时候要加个 sed 's/ /\n/g'   (替换所有的 为回车符号)
#对照组目录参数	
dz_list=`echo ${sz_list[*]}| sed 's/ /\n/g'|sort`




#得到当前服务器存在的列表$fwq_list	
if [[ -d "/usr/local/WTQYB/" ]]
then
#查找WTQYB下一层的文件夹 15日内改变过的 名字叫XXXXX或者XXXX  排序
fwq_list=`find /usr/local/WTQYB/ -maxdepth 1 -type d -atime -15 -name "xpe-products-wt*" -o -name "wt-mobile"| sort`

#新建更新文件的文件夹
if [ ! -d "/usr/local/WTQYB/abc" ]
then
mkdir -p /usr/local/WTQYB/abc
fi

#fwwj_list=`find /usr/local/WTQYB -maxdepth 1 -name "pc-front*" -o -name "pc-video*" -o -name "wt-mobile-ccgr*"| sort`
fwwj_list=(wt-mobile_ccgr pc-front pc-video)

elif [[ -d "/usr/local/tomcat/" ]]
then

fwq_list=`find /usr/local/tomcat/apache-tomcat*/ -type d -atime -30 -name "webapps" | awk -F "/webapps" '{print $1}'| sort`

#新建更新文件的文件夹
if [ ! -d "/usr/local/tomcat/abc" ]
then
mkdir -p /usr/local/tomcat/abc
fi
#fwwj_list=`find /usr/local/tomcat/abc -atime -15 -name "xpe-*" -o -name "sbc.*"| sort`
fwwj_list=(`find /usr/local/tomcat/apache-tomcat*/webapps -maxdepth 1 -type d |grep "/webapps/"| awk -F "/webapps/" '{print $2}'|sort`)

else
red "找不到要备份的文件！"
fi

# echo "对照组目录列表是："
# echo $dz_list| sed 's/ /\n/g'
# echo "当前服务器目录列表是："
# echo $fwq_list| sed 's/ /\n/g'
# echo "公共目录列表是："

#公共目录数组  也就是服务器和预制的数组对比后的值
gg_list=(`comm -12 <(echo $dz_list| sed 's/ /\n/g') <(echo $fwq_list| sed 's/ /\n/g')`)	

q=0
w=0
e=0
r=0
t=0
y=0

for gg in ${gg_list[*]}
do
{
if [[ "${wtqyblist[*]}" =~ "$gg" ]]
then
((q++))
q=$q

elif [[ "${wtlist[*]}" =~ "$gg" ]]
then
((w++))
w=$w

elif [[ "${khlist[*]}" =~ "$gg" ]]
then
((e++))
e=$e

elif [[ "${xpelist[*]}" =~ "$gg" ]]
then
((r++))
r=$r

elif [[ "${sclist[*]}" =~ "$gg" ]]
then
((t++))
t=$t

else
pt="error!"

fi
}

done

# }&
# wait
# done


pt_list=($q $w $e $r $t $y)
#排序
#然后得出数组中最大值
max=${pt_list[0]}
second=${pt_list[1]}


for l in ${pt_list[*]}
do
if [[ "$l" > "$max" ]]
then
max=$l
elif [[ "$l" -le "$max" ]] && [[ "$l" -gt "$second" ]] 
then
second=$l
elif [[ "$l" -le "$second" ]] && [[ "$l" -gt "$third" ]] 
then
third=$l
else
:
fi
done


#echo "当前最大的数是$max"
#echo "第二大的是$second"
#echo "现在排序数组是：(${pt_list[*]})"





#排序得到当前服务器中最大的数量最多的那个服务

j=${#pt_list[*]}
for((i=0;i<j;i++))
do
{

#echo "当前${pt_list[$i]}"
#echo "max 为$max"



if [[ "${pt_list[$i]}" == "$max" ]]
then

case $i in
0)
pt=跳板机
#echo "aaa"
ggcz_list_pt1=(`comm -12 <(echo ${wtqyblist[*]}| sed 's/ /\n/g'| sort) <(echo ${gg_list[*]}| sed 's/ /\n/g'| sort) `)			
;;
1)
pt=网厅
#echo "bbb"
ggcz_list_pt1=(`comm -12 <(echo ${wtlist[*]}| sed 's/ /\n/g'| sort) <(echo ${gg_list[*]}| sed 's/ /\n/g'| sort) `)
;;
2)
pt=开户
#echo "ccc"
ggcz_list_pt1=(`comm -12 <(echo ${khlist[*]}| sed 's/ /\n/g'| sort) <(echo ${gg_list[*]}| sed 's/ /\n/g'| sort) `)
;;
3)
pt=xpe
#echo "dddd"
ggcz_list_pt1=(`comm -12 <(echo ${xpelist[*]}| sed 's/ /\n/g'| sort) <(echo ${gg_list[*]}| sed 's/ /\n/g'| sort) `)
;;
4)
pt=商城
ggcz_list_pt1=(`comm -12 <(echo ${sclist[*]}| sed 's/ /\n/g'| sort) <(echo ${gg_list[*]}| sed 's/ /\n/g'| sort) `)				
#echo "eeeee"
;;
*)
pt=error


esac



elif [[ "${pt_list[$i]}" == "$second" ]]
then

case $i in		
0)
pt2=跳板机
#echo "aaa"

ggcz_list_pt2=(`comm -12 <(echo ${wtqyblist[*]}| sed 's/ /\n/g'| sort) <(echo ${gg_list[*]}| sed 's/ /\n/g'| sort) `)
;;
1)
pt2=网厅
#echo "bbb"
ggcz_list_pt2=(`comm -12 <(echo ${wtlist[*]}| sed 's/ /\n/g'| sort) <(echo ${gg_list[*]}| sed 's/ /\n/g'| sort) `)
;;
2)
pt2=开户
#echo "ccc"
ggcz_list_pt2=(`comm -12 <(echo ${khlist[*]}| sed 's/ /\n/g'| sort) <(echo ${gg_list[*]}| sed 's/ /\n/g'| sort) `)
;;
3)
pt2=xpe
#echo "dddd"
ggcz_list_pt2=(`comm -12 <(echo ${xpelist[*]}| sed 's/ /\n/g'| sort) <(echo ${gg_list[*]}| sed 's/ /\n/g'| sort) `)
;;
4)
pt2=商城
ggcz_list_pt2=(`comm -12 <(echo ${sclist[*]}| sed 's/ /\n/g'| sort) <(echo ${gg_list[*]}| sed 's/ /\n/g'| sort) `)			
#echo "eeeee"
;;
*)
pt2=""

esac

elif [[ "${pt_list[$i]}" == "$third" ]]
then
:
continue
#备用
#如果存在三个服务在一个服务器的 启用这个，四个五个六个的 得继续加 elif ;then...
else
#echo "亲，请手动配置"
:
fi
}
done


#区分 单服务服务器 和多服务服务器
if [[ "$pt" != "" ]] && [[ "$pt2" = "" ]]
then
fwqm=$pt
elif [[ "$pt" != "" ]] && [[ "$pt2" != "" ]]
then
fwqm=$pt、$pt2
else
fwqm="unknown！请手动检查和配置“list”函数。"
fi

}




#操作选择函数 公共的  会展示你的所有目录
czwztx(){
clear
red "警告！"

red "将要对以下目录进行操作，请确认！"

if [[ "$pt" != "" ]] && [[ "$pt2" = "" ]]
then

#如果单服务器，ggcz_list是：
ggcz_list_pt=${gg_list[*]}
yellow "当前服务器是:$pt,请选择你要的操作的对象："
blue "1.$pt的列表为:"
yellow "${ggcz_list_pt1[*]}"| sed 's/ /\n/g'| sort
blue "2.退出"	
#单服务服务器的选择
read xz1	

elif [[ "$pt" != "" ]] && [[ "$pt2" != "" ]]
then
yellow "当前服务器有多个服务,请选择你要的操作的对象："
blue "1.$pt的列表为:"
yellow "${ggcz_list_pt1[*]}" | sed 's/ /\n/g'| sort
blue "2.$pt2的列表为:"
yellow "${ggcz_list_pt2[*]}" | sed 's/ /\n/g'| sort
blue "3.所有列表"
yellow "${gg_list[*]}" | sed 's/ /\n/g' | sort
blue "4.返回"

#多服务服务器的选择
read xz2

else
red "error!当前没有操作目录！请手动检查"
read -aa
fi

}








#根据文件目录来判断当前的服务器的位置
#xpe的目录在WTQYB下面
welcome(){

#星期几用这个控制
if [[ $(date +%w) = 1 ]]
then
exq=一
elif [[ $(date +%w) = 2 ]]
then
exq=二
elif [[ $(date +%w) = 3 ]]
then
exq=三
elif [[ $(date +%w) = 4 ]]
then
exq=四
elif [[ $(date +%w) = 5 ]]
then
exq=五
elif [[ $(date +%w) = 6 ]]
then
exq=六
else
exq=日
fi

#得到当前服务器的ip地址
zjip=`ifconfig| grep -w "inet"| grep -w "inet"| grep -v "127.0.0.1"| grep -v "192.168.*"| awk -F '[ :]+' '{if($4!="")print $4}'| sort| uniq`



yellow "长城国瑞测试环境专用"
yellow "今天是$(date +%Y年%m月%d日),星期$exq,当前主机ip是:$zjip,服务器是:$fwqm"
yellow "当前版本是0.0.3"


}



#校验文件  ${*}  *指的是单个的元素 必须配合for ...in...循环来用
jywj(){

for j in ${*}
do
{
green "					#完整性校验"
gzip -t "$j"
if [[ "$?" -eq "0" ]]
then
green "$j  备份数据完整性校验通过,备份文件有效！"
echo 

else
red "$j 备份数据完整性校验未过,备份文件无效或者不完整！"
red "请手动删除该文件，并再次备份！"
read aa
break 1

fi
}&
wait
done

}


#备份文件查询**************************************************************************************************************************************

bfwjcx(){

#查询是否存在今日备份的目录          ${*}中  *是指的操作目录下的所有元素
for ky in ${*}
do
{
#判断webapps 目录在不在来确定服务器是tomcat 还是WTQYB

we=`find ${ky%/*} -type d -name "webapps"`
if [[ "$we" != "" ]]
then
ky_list=`find $ky -type f -name "webapps-"$(date +"%Y%m%d")".tar.gz"`

# yellow "ky_list是"
# echo "$ky_list"
else
na=`echo $ky |awk -F '/' '{print $NF}'`
ky_list=`find ${ky%/*} -type f -name "$na-"$(date +"%Y%m%d")".tar.gz"`
# yellow "ky_list是"
# echo "$ky_list"
fi

if [[ "$ky_list" != "" ]]
then
green "					#备份检查"
green "$ky_list已经备份！"		
#yellow "开始完整性校验..."
jywj "$ky_list"	


elif [[ "$ky_list" == "" ]]
then
#echo "$ky"	
echo 
red "今日$ky没有备份！"
echo
#没有就备份！
bf "$ky"

else 
red "error!查询今日备份的文件出错！"
fi
}&
wait	
done
yellow "					#执行完成，请确认"
read aa
#clear
}


#选择  需要输出操作是哪个目录  


#备份选择函数
#这里换成while do
xz(){
while :
do

if [[ "$xz1" == "1" ]] || [[ "$xz2" == "1" ]]
then
yellow "检查今日是否存在备份"
bfwjcx "${ggcz_list_pt1[*]}"
#clear
break 1

elif [[ "$xz1" == "2" ]] || [[ "$xz2" == "4" ]]
then
yellow "ok,bye！"
#read aa
sleep 1s
#clear
break 1

elif [[ "$xz2" == "2" ]]
then
yellow "检查今日是否存在备份"
bfwjcx "${ggcz_list_pt2[*]}"
#clear
break 1
elif [[ "$xz2" == "3" ]]
then
yellow "检查今日是否存在备份"
bfwjcx "${gg_list[*]}"
#clear
break 1
else
red "你的选择有误！请重新选择！"
read aa
czwztx

fi


done
}






#备份函数 会调用完整性检测
bf(){

yellow "准备备份${*}目录下的文件"

#循环备份
for bf in ${*}
do
{	
if [[ "${*}" != "" ]]
then
if [[ "$we" != "" ]]
then
bf_list="$bf/webapps"
else
bf_list=$bf
fi

# #文件夹的名字
ne=`echo $bf_list| awk -F "/" '{print $NF}'`
#文件保存的路径/结尾
lj=`echo $bf_list| awk -F "$ne" '{print $1}'`
green "					#开始备份"

tar -czf "$lj$ne-"$(date "+%Y%m%d")".tar.gz" -C "$lj" "$ne"
green "$lj$ne-$(date "+%Y%m%d").tar.gz 备份完成！"
jywj "$lj$ne-$(date "+%Y%m%d").tar.gz"

else			
red "${*}为空,请检查！"
fi

}&
wait
done
}



#tomcat结束函数***************************************************************************************************************

#选择结束tomcat的函数
xz_kill_tomcat(){

while :
do

if [[ "$xz1" == "1" ]] || [[ "$xz2" == "1" ]]
then
yellow "查看当前正在运行的相关列表tomcat服务"
#red "请确定要关闭这个服务吗？(Y/y/回车确认；其他按键取消)"
killtomcat "${ggcz_list_pt1[*]}"
#clear
break 1

elif [[ "$xz1" == "2" ]] || [[ "$xz2" == "4" ]]
then
yellow "ok,bye！"
sleep 1s
#clear
break 1

elif [[ "$xz2" == "2" ]]
then
yellow "查看当前正在运行的相关列表tomcat服务"
#red "请确定要关闭这个服务吗？(Y/y/回车确认；其他按键取消)"
killtomcat "${ggcz_list_pt2[*]}"
#clear
break 1
elif [[ "$xz2" == "3" ]]
then
yellow "查看当前正在运行的相关列表tomcat服务"

killtomcat "${gg_list[*]}"

#clear
break 1
else
red "你的选择有误！请重新选择！"
read aa
czwztx
fi
done

}




#关闭tomcat函数部分
killtomcat(){
green "正在运行的tomcat服务有："

for k_t in ${*}
do	
{
run_tomcatlist=`ps -ef | grep -w "$k_t"| grep -v grep`
run_tomcat_id=`ps -ef | grep -w "$k_t"| grep -v grep| awk '{print $2}'`
if [[ "$run_tomcat_id" != "" ]]
then
green $k_t  $run_tomcat_id

blue "请确定要关闭这个服务吗？(Y/y/回车确认；其他按键取消)"
#这个是不用回车


read -s -n 1 kill

case $kill in
"")				
kill -9 $run_tomcat_id
if [[ $? -eq 0 ]]
then
green $run_tomcat_id kill 成功！
else
red $run_tomcat_id kill 失败！
fi
;;
Y)
kill -9 $run_tomcat_id
if [[ $? -eq 0 ]]
then
green $run_tomcat_id kill 成功！
else
red $run_tomcat_id kill 失败！
fi
;;
y)
kill -9 $run_tomcat_id
if [[ $? -eq 0 ]]
then
green $run_tomcat_id kill 成功！
else
red $run_tomcat_id kill 失败！
fi
;;
*)
yellow "$run_tomcat_id  passed!"
esac

else
yellow "当前$k_t目录下没有正在运行的tomcat服务！"

fi
}
done

yellow "						#执行完成，请确认"
read aa	
}


#tomcat启动函数***************************************************************************************************************
#启动tomcat 选择的函数
xz_start_tomcat(){

while :
do

if [[ "$xz1" == "1" ]] || [[ "$xz2" == "1" ]]
then
#yellow "查看当前正在运行的相关列表tomcat服务"
start_tomcat "${ggcz_list_pt1[*]}"
#clear
break 1

elif [[ "$xz1" == "2" ]] || [[ "$xz2" == "4" ]]
then
yellow "ok,bye！"
sleep 1s
#clear
break 1

elif [[ "$xz2" == "2" ]]
then
#yellow "查看当前正在运行的相关列表tomcat服务"
start_tomcat "${ggcz_list_pt2[*]}"
#clear
break 1
elif [[ "$xz2" == "3" ]]
then
#yellow "查看当前所有tomcat服务"
start_tomcat "${gg_list[*]}"

#clear
break 1
else
red "你的选择有误！请重新选择！"
read aa
czwztx
fi
done

}



#启动tomcat的函数
start_tomcat(){
yellow "提示：启动过程中请不要ctrl+C结束！"
n=0
m=0
for res_tom in ${*}
do
{
#理论上该服务器正在运行的所有tomcat服务
run_list=`ps -ef|grep tomcat|grep -v "zook"|grep -v "active"| awk -F '/conf' '{if($1!="")print $1}'|awk -F '=' '{if($2!="") print $2"/"}'`
#echo ${run_list}

#这里不能用=~  这个正则式子没办法区分 kh 和khgl   用搜索的方式  echo xxx| sed 's/ /\n/g| awk -F xxxx{print $0}'|grep -w "xxxxx"
#写个通用的  

#查找现在已启动列表里面有没有这个目录
result=`echo ${run_list}|sed 's/ /\n/g'|grep -w "${res_tom}"`
#echo $result



#决定启动顺序
xt_list=(config sisap video suit-backend mall-backend rzzx sjsc sbc-api sbc-flow sbc-web wt-api khgl kh sjkh sjkh2)

for xt in ${xt_list[*]}
do
#{
#1.必须是存在的目录																			2.这个服务是没有启动的
if [[ "`echo ${*}|sed 's/ /\n/g'| awk -F '[/ -]+' '{print $0}' |grep -w "$xt"`" != "" ]] && [[ "`echo ${run_list}|sed 's/ /\n/g'|grep -w "$xt"`" == "" ]]
then

blue "确定要启动$xt吗？(回车/Y/y确定，其他按钮跳过)"

read -s -n 1 j


case $j in 
Y)
yellow "将启动$xt"
bash /usr/local/tomcat/apache-tomcat-$xt/bin/startup.sh && tail -fn 0 --pid=`ps uxh|grep "sed /startup"| grep -v "zookee*" | grep -v "active*"| grep -v "redi*"| grep -v "grep" | awk '{ print $2 } ' | sort -nr | head -1 ` /usr/local/tomcat/apache-tomcat-$xt/logs/catalina.out| sed /startup[[:space:]]in/Q		

if [[ $? -eq 0 ]]
then

green "$xt已经启动！"
else
red "$xt启动失败！"
fi

;;
y)
yellow "将启动$xt"

bash /usr/local/tomcat/apache-tomcat-$xt/bin/startup.sh && tail -fn 0 --pid=`ps uxh|grep "sed /startup"| grep -v "zookee*" | grep -v "active*"| grep -v "redi*"| grep -v "grep" | awk '{ print $2 } ' | sort -nr | head -1 ` /usr/local/tomcat/apache-tomcat-$xt/logs/catalina.out| sed /startup[[:space:]]in/Q		

if [[ $? -eq 0 ]]
then

green "$xt已经启动！"
else
red "$xt启动失败！"
fi				
;;
"")
yellow "将启动$xt"

bash /usr/local/tomcat/apache-tomcat-$xt/bin/startup.sh && tail -fn 0 --pid=`ps uxh|grep "sed /startup"| grep -v "zookee*" | grep -v "active*"| grep -v "redi*"| grep -v "grep" | awk '{ print $2 } ' | sort -nr | head -1 ` /usr/local/tomcat/apache-tomcat-$xt/logs/catalina.out| sed /startup[[:space:]]in/Q		
if [[ $? -eq 0 ]]
then

green "$xt已经启动！"
else
red "$xt启动失败！"
fi					
;;
*)
yellow "$xt passed!"
esac

#当前这个任务是运行的											#当前这个任务也是在我选的目录里面的
elif [[ "`echo ${run_list}|sed 's/ /\n/g'|grep -w "$xt"`" != "" ]] && [[ "`echo ${*}|sed 's/ /\n/g'| awk -F '[/ -]+' '{print $0}' |grep -w "$xt"`" != "" ]]
then
((n++))
abc=(`echo ${*}`)
if [[ "$n" -gt "${#abc[@]}" ]]
then
green "您选择的tomcat已经全部启动了！"
read aa
#clear
break 3

else
green "$xt正在运行！"
fi

#当前这个目录下的服务在选的目录里面搜不到(也就是不存在)
elif [[ "`echo ${*}|sed 's/ /\n/g'| awk -F '[/ -]+' '{print $0}' |grep -w "$xt"`" == "" ]]
then
((m++))
abc=(`echo ${*}`)
#如果所有的都匹配过了，还是找不到，那么就报这个
if [[ "$m" -ge "${#xt_list[@]}*${#abc[@]}" ]]
then
# echo $m
# echo "${#xt_list[@]}*${#abc[@]}"
red "当前服务器下没有符合条件的tomcat服务需要启动，请确认！"
#echo
read aa
sleep 1.5s
#clear
break 3
fi

else				
continue
fi
# }&
# wait
done

}
done

green "                                  #执行完成，请确认"
read aa
}			












#来个一键更新好了 

##################################################一键更新#################################################
#1.让人选，你要更新哪个？ A,B   你还要更新另一个吗？实现了
#2.全量还是增量 
#3.更新以后自动重启
#4.目前更新可以分为两大类，一个是带tomcat的 一个是不带的，带的需要先备份，然后关闭tomcat，然后更新，然后启动tomcat；不带的就先备份，然后更新
#4.5 走一样的流程  全部走关闭服务，更新再启动服务的流程，直接调用之前的函数

#这个更新的话 要怎么更新 





#1.打印当前的操作列表


#复制的时候 弄个日志出来，然后读取第一列 对比下时间 如果三日内有更新的  就提示已经更新了 是否覆盖更新  做个选择
##\cp ./sbc.flow.api-1.0.0.war ./sbc.flow.api-1.0.0.war.111| echo "$(date +%Y%m%d)          success" >>./1.log

#先选择要处理的目录




xz_gx(){
while :
do

if [[ "$xz1" == "1" ]] || [[ "$xz2" == "1" ]]
then
yellow "根据更新包文件名的特性，默认会将带1.0.0的文件夹做全量更新处理，没有带1.0.0的文件夹做增量更新处理，如果是合成包，请将文件名结尾处加上.1.0.0"
echo
yellow "检查今日是否存在更新记录"
gx_jc "${ggcz_list_pt1[*]}"
#clear
break 1

elif [[ "$xz1" == "2" ]] || [[ "$xz2" == "4" ]]
then
yellow "ok,bye！"
#read aa
sleep 1s
#clear
break 1

elif [[ "$xz2" == "2" ]]
then
yellow "根据更新包文件名的特性，默认会将带1.0.0的文件夹做全量更新处理，没有带1.0.0的文件夹做增量更新处理，如果是合成包，请将文件名结尾处加上.1.0.0"
echo
yellow "检查今日是否存在更新记录"
gx_jc "${ggcz_list_pt2[*]}"
#clear
break 1
elif [[ "$xz2" == "3" ]]
then
yellow "根据更新包文件名的特性，默认会将带1.0.0的文件夹做全量更新处理，没有带1.0.0的文件夹做增量更新处理，如果是合成包，请将文件名结尾处加上.1.0.0"
echo
yellow "检查今日是否存在更新记录"
gx_jc "${gg_list[*]}"
#clear
break 1
else
red "你的选择有误！请重新选择！"
read aa
czwztx

fi

done
}






#更新的函数
gx(){

yellow "开始更新！"

#read -aa	
for gx in ${*}
do
#echo "gx是$gx"
#echo "{!gzwjsz[*]}是${!gzwjsz[*]}"


for gzwjsz_fl in ${!gzwjsz[*]}
do	

#echo "gzwjsz_fl是$gzwjsz_fl"

if [[ ${gzwjsz_fl} =~ ${gx} ]] && [[ ${gx} =~ "wt-mobile" ]] 	
then
yellow "检测到更新的目录是/usr/local/WTQYB/wt-mobile ，将做特殊处理"
#rm -rf /usr/local/WTQYB/wt-mobile/index.html
#rm -rf /usr/local/WTQYB/wt-mobile/static

if [[ $? -eq 0 ]]
then
red "/usr/local/WTQYB/wt-mobile/index.html删除成功！"
red "/usr/local/WTQYB/wt-mobile/staticl删除成功！"
else
red "清理旧文件失败，请确认！"
break 2
fi

elif [[ ${gzwjsz_fl} =~ ${gx} ]] && [[ ${gzwjsz[$gzwjsz_fl]} =~ "1.0.0" ]] && [[ ${gzwjsz_fl} != "" ]]
then
yellow "检测到带有1.0.0后缀，将做全量更新处理！"
#rm -rf $gzwjsz_fl				

if [[ $? -eq 0 ]]
then
red "$gzwjsz_fl删除成功！"
else
red "清理旧文件失败，请确认！"
break 2
fi

fi	

done


done

echo
yellow "开始执行替换文件流程..."

for gzwjsz_fl in ${!gzwjsz[*]}
do
if [[ -d ${gzwjsz_fl} ]] && [[ -d ${gzwjsz[$gzwjsz_fl]} ]]
then

# \cp -r ${gzwjsz[$gzwjsz_fl]} $gzwjsz_fl 
echo "$(date +%Y%m%d)复制${gzwjsz[$gzwjsz_fl]}到$gzwjsz_fl" >>./gx.log

if [[ $? -eq 0 ]]
then
green "$gzwjsz_fl更新完成！"
else
red "$gzwjsz_fl更新失败！请检查！"
read -aa
break 2
fi

else
red "更新文件 ${gzwjsz_fl} 或${gzwjsz[$gzwjsz_fl]}为空！请检查！"
read -aa
break 2
fi

done

green "已经执行完成更新任务，准备重启服务！"


}



#解压压缩包

#这里解压的是上传到指定目录的所有war.zip的文件  
jieya(){



yswj=(`find "$gxwj_mu" -name "*.zip" -o -name "*.war"`)
if [[ ! -z $yswj ]]
then
green "检测到压缩文件的存在，即将开始执行解压程序"

for yswj_fl in ${yswj[*]}
do
unzip -oq "$yswj_fl" -d `echo "$yswj_fl"| awk -F ".war" '{print $1}' |awk -F ".zip" '{print $1}'`

if [[ $? -eq 0 ]]
then
green "$yswj_fl 解压完成！"
else
red "$yswj_fl 解压失败！请检查！"
read aa
fi

done
fi
}








#删除旧文件
delect_oldfile(){

red "警告：将执行删除旧文件的命令！请确定！"
#read -aa
red "请再次确定！"
#read -aa
green "OK let's go！"


# echo "$gxwj是$gxwj"
# echo "$gxwj"
# echo "$gxwj"| awk -F "-1.0.0" '{prinr $1}'

#用查找的方法
#这个是查找的文件名字，截取的更新文件的，比如sbc.web.task
del_old_name=`echo "$gxwj"| awk -F "-1.0.0" '{print $1}'`

#这个是查找的路径，截的更新文件的位置-abc
del_old_czlo=`echo $gxwj_mu| awk -F '/abc' '{print $1}'`
#echo "name是 $del_old_name"

#echo "find $gxwj_mu -name "$del_old_name"| grep "/webapps/""

#echo "name是 $del_old_name"
#echo "find "$del_old_czlo" -name "$del_old_name"| grep "/webapps/" |awk -F $del_old_name '{print $1}'"


del_old_lo=`find "$del_old_czlo" -name "$del_old_name"| grep "/webapps/"`

#echo $del_old_lo

yellow "查询完成 文件的位置是$del_old_lo"


if [[ -d "$del_old_lo" ]]
then
echo $del_old_lo
#rm -rf $del_old_lo

if [[ $? -eq 0 ]]
then
yellow "$del_old_name删除完毕！"
else
red "$del_old_name删除失败！"
fi
else
red "$del_old_lo 不存在，禁止进行危险操作！！！"

fi

}








###########更新文件检查

#######################tomcat的#################

gxwj_jc_tomcat(){


####################

#查找现有的服务 弄个数组框起来 
#fuwj_loca=(`find /usr/local/tomcat/*/webapps -maxdepth 1 |grep  "/webapps/" |sort `)

fuwj_loca=()
for xzd in ${*}
do
fuwj_loca+=(`find ${xzd}/webapps -maxdepth 1 |grep  "/webapps/" |sort` )
done




#echo ${fuwj_loca[*]}
#更新文件数组
gzwjsz=()
qs_gzwjsz=()
declare -A gzwjsz 
for fuwj in ${fuwj_loca[*]}
do  
#j对应的是服务的关键字
fugjz=`echo $fuwj| awk -F "/webapps/" '{print $2}'`
#echo $fugjz

#k对应的是abc更新目录下的所有文件
#k=`find /usr/local/tomcat/abc -maxdepth 1 -name "*$j*" |grep -v "war" | grep -v "zip" |grep -v "log"| sort |awk '{NR==1}'`


#这里通过在abc目录下 查找关键字 然后组合以后呢  可以得到当前abc下面更新文件的信息
#这里api和apiwt两个会重复，先把结果排序，然后awk切掉第二个答案
gxwj=`find $gxwj_mu -maxdepth 1 -name "*$fugjz*" |grep -v "war" | grep -v "zip" |grep -v "log"| sort |awk '{print($NR)}'|awk '{if($1!="") print $1}'`
#echo $gxwj

if [[ $gxwj != "" ]]
then

gzwjsz+=([$fuwj]=$gxwj )
#echo "$i对应的更新文件目录是$k"
else
#echo "$i 对应的更新文件不存在！"
qs_gzwjsz+=($fuwj)

fi
done 


#echo "所有对应的服务目录是："
#echo "${!aaa[*]}" |sed 's/ /\n/g'
#echo "所有对应的更新文件所在目录是："
#echo "${aaa[*]}" |sed 's/ /\n/g'


if [[ $? -eq 0 ]]
then
green "更新文件检查完成！"
else
red "更新文件检查失败！请检查脚本程序！"
read aa
break
fi



for gzwjsz_fl in ${!gzwjsz[*]}
do
green "$gzwjsz_fl对应的更新文件目录是${gzwjsz[$gzwjsz_fl]}"

done

for qs_gzwjsz_fl in ${qs_gzwjsz[*]}
do
red "$qs_gzwjsz_fl对应的更新文件不存在！"
done


if [[ ${qs_gzwjsz[*]} != "" ]]
then
red "更新文件并不完整，确认要继续更新嘛？！"
read aa

fi
echo

gx ${*}

}






##########################
#这个写跳板机的，没办法做到统一，就分开写好了
gxwj_jc_WTQYB(){

fuwj_loca=(`find /usr/local/WTQYB -maxdepth 1 |grep -v "zip" |grep -v "war" | grep -v "tar.gz"| grep "wt-"| sort`)
gxwj_loca=(`find $gxwj_mu -maxdepth 1 | grep -v "war" | grep -v "zip" |grep "/abc/" | sort`)
#gxwj_name=(wt-mobile_ccgr pc-front pc-video)
#更新文件数组
gzwjsz=()
qs_gzwjsz=()

declare -A gzwjsz 
for gxwj in ${gxwj_loca[*]}
do 

if [[ "$gxwj" =~ "wt-mobile_ccgr" ]] 
then
gzwjsz+=(["/usr/local/WTQYB/wt-mobile"]="/usr/local/WTQYB/abc/wt-mobile_ccgr" )	

elif [[ "$gxwj" =~ "pc-video" ]] 
then
gzwjsz+=(["/usr/local/WTQYB/xpe-products-wt-backend-static"]="/usr/local/WTQYB/abc/pc-video/pc-video" )

elif [[ "$gxwj" =~ "pc-front" ]]
then
gzwjsz+=(["/usr/local/WTQYB/xpe-products-wt-front-static"]="/usr/local/WTQYB/abc/pc-front/pc-front" )



fi

done

if [[ ${fuwj_loca[*]} != ${!gzwjsz[*]} ]]
then
#echo "${!gzwjsz[*]}"| sed 's/ /\n/g' |sort



#echo "aaaaa"
#echo "${fuwj_loca[*]}"| sed 's/ /\n/g' |sort
qs_gzwjsz=(`comm -23 <(echo ${fuwj_loca[*]} | sed 's/ /\n/g' |sort) <(echo ${!gzwjsz[*]} |sed 's/ /\n/g'| sort)`)

#qswj_list=(`comm -13 <(echo ${gxwj_list[*]}| sed 's/ /\n/g'| awk -F "-1.0.0" '{print $1}') <(echo ${fwwj_list[*]}| sed 's/ /\n/g')`)
#echo ${qs_gzwjsz[*]}

fi

if [[ $? -eq 0 ]]
then
green "更新文件检查完成！"
else
red "更新文件检查失败！请检查脚本程序！"
read aa
break
fi



for gzwjsz_fl in ${!gzwjsz[*]}
do
green "$gzwjsz_fl对应的更新文件目录是${gzwjsz[$gzwjsz_fl]}"


done

for qs_gzwjsz_fl in ${qs_gzwjsz[*]}
do
red "$qs_gzwjsz_fl对应的更新文件不存在！"
done


if [[ ${qs_gzwjsz[*]} != "" ]]
then
red "更新文件并不完整，确认要继续更新嘛？！"
read aa

fi

echo
gx ${*}





}




#########################


#######jieya



#######这个是当前服务下的文件列表
########blue "`echo ${fwwj_list[*]}| sed 's/ /\n/g' |sort`"




########决定要不要删除旧文件夹（增量还是全量）

##########更新目录abc下面的文件  
# gxwj_list=(`ls $gxwj_mu| grep -v ".war"| grep -v ".zip" |grep -v ".log"|sort`)


############green "`echo ${gxwj_list[*]}| sed 's/ /\n/g'| awk -F "-1.0.0" '{print $1}' |sort`"


############对比下列表 找出共同的文件
# if [[ "`echo ${gxwj_list[*]}| sed 's/ /\n/g'| awk -F "-1.0.0" '{print $1}' |sort`" =~ "`echo ${fwwj_list[*]}| sed 's/ /\n/g' |sort`" ]]
# then
# yellow "更新文件检测为完整，允许更新"

# for gxwj in ${gxwj_list[*]}
# do
# if [[ "$gxwj" =~ "-1.0.0" ]]
# then
# red "检查到$gxwj是全量包，即将删除原始数据，请确认！"
# read aa
# yellow "即将删除原始数据。。。"
# delect_oldfile


# elif [[ "$gxwj" =~ "wt-mobile_ccgr" ]]
# then
# red "检查到$gxwj文件是wt-mobile_ccgr包，即将删除cancel以外的原始数据，请确认！"
# read aa

# else
# yellow "$gxwj是增量包文件,将常规处理！"
# fi


# done	


# else
# qswj_list=(`comm -13 <(echo ${gxwj_list[*]}| sed 's/ /\n/g'| awk -F "-1.0.0" '{print $1}') <(echo ${fwwj_list[*]}| sed 's/ /\n/g')`)
# ##########echo ${qswj_list[*]}
# red "更新文件不完整，还缺少 ${qswj_list[*]} 请确定！"| sed 's/ /\n/g'
# read aa

# fi








# gxwj_jc(){


# yellow "根据更新包文件名的特性，默认会将带1.0.0的文件夹做全量更新处理，没有带1.0.0的文件夹做增量更新处理，如果是合成包，请将文件名结尾处加上.1.0.0"
# echo
# echo
# yellow "今天更新目录中的文件是：(这里仅做展示，如果更新文件不全会在更新过程中体现出来！)"
# ls -l --block-size=m $gxwj_mu |awk -v OFS=' ' 'BEGIN{print "日期\t\t\t时间\t\t\t文件名\t\t\t\t\t文件大小"}{if(NR>1) printf "%-20s%-20s%-20s%+30s\n",$6$7"日",$8,$9,$5}'			
# yellow "请确认！"
# sleep 2s
# yellow "开始解压所有文件。。。"
# #######jieya



# #######这个是当前服务下的文件列表
# ########blue "`echo ${fwwj_list[*]}| sed 's/ /\n/g' |sort`"




# ########决定要不要删除旧文件夹（增量还是全量）

# ##########更新目录abc下面的文件  
# gxwj_list=(`ls $gxwj_mu| grep -v ".war"| grep -v ".zip" |grep -v ".log"|sort`)


# ############green "`echo ${gxwj_list[*]}| sed 's/ /\n/g'| awk -F "-1.0.0" '{print $1}' |sort`"


# ############对比下列表 找出共同的文件
# if [[ "`echo ${gxwj_list[*]}| sed 's/ /\n/g'| awk -F "-1.0.0" '{print $1}' |sort`" =~ "`echo ${fwwj_list[*]}| sed 's/ /\n/g' |sort`" ]]
# then
# yellow "更新文件检测为完整，允许更新"

# for gxwj in ${gxwj_list[*]}
# do
# if [[ "$gxwj" =~ "-1.0.0" ]]
# then
# red "检查到$gxwj是全量包，即将删除原始数据，请确认！"
# read aa
# yellow "即将删除原始数据。。。"
# delect_oldfile


# elif [[ "$gxwj" =~ "wt-mobile_ccgr" ]]
# then
# red "检查到$gxwj文件是wt-mobile_ccgr包，即将删除cancel以外的原始数据，请确认！"
# read aa

# else
# yellow "$gxwj是增量包文件,将常规处理！"
# fi


# done	


# else
# qswj_list=(`comm -13 <(echo ${gxwj_list[*]}| sed 's/ /\n/g'| awk -F "-1.0.0" '{print $1}') <(echo ${fwwj_list[*]}| sed 's/ /\n/g')`)
# ##########echo ${qswj_list[*]}
# red "更新文件不完整，还缺少 ${qswj_list[*]} 请确定！"| sed 's/ /\n/g'
# read aa

# fi

# }








#更新前的准备
gx_zb(){	

#确定位置在跳板机里面
if [[ -d "/usr/local/WTQYB/abc" ]] && [[ ! -d "/usr/local/tomcat/abc" ]]
then
if [[ ! -z `ls -A "/usr/local/WTQYB/abc"` ]]
then

#文件查找目录
gxwj_mu="/usr/local/WTQYB/abc"
jieya
gxwj_jc_WTQYB ${*}



else 
red "$gxwj_mu 目录为空，请上传更新文件！"
read -aa
break 2	


fi


#非跳板机
elif [[ ! -d "/usr/local/WTQYB/abc" ]] && [[ -d "/usr/local/tomcat/abc" ]]
then

if [[ ! -z `ls -A "/usr/local/tomcat/abc"` ]]
then

#文件查找目录
gxwj_mu="/usr/local/tomcat/abc"
jieya
gxwj_jc_tomcat ${*}



else 
red "$gxwj_mu 目录为空，请上传更新文件！"
read -aa
break 2	

fi

else

red "预设的更新目录不存在！请检查！"
read aa
fi






# for gxwj in ${gxwj_list[*]} 	
# do
# {
# for g in ${*} 
# do
# {
# #这个目的是 判断是否带 1.0.0             #这个的目的是确定这个文件是存在的
# if [[ "$gxwj" =~ "1.0.0" ]] && [[ ! -z "find "$g/webapps" -name `echo $gxwj| awk -F "-1.0.0" '{print $1}'`" ]]
# then

# #blue $g
# yellow "检测到带有1.0.0尾缀，$gxwj 将做全量更新处理！"
# gxwjm=`echo $gxwj| awk -F "-1.0.0" '{print $1}'`
# #echo $gxwj| awk -F "-1.0.0" '{print $1}'
# delect_oldfile
# #continue


# elif [[ ! "$gxwj" =~ "1.0.0" ]] && [[ ! -z "find "$g/webapps" -name `echo $gxwj| awk -F "-1.0.0" '{print $1}'`" ]]
# then

# yellow "未检测到带有1.0.0尾缀，$gxwj 将做增量更新处理！"
# gxwjm=`echo $gxwj`
# #echo $gxwj| awk -F "-1.0.0" '{print $1}'
# #continue



# else

# #echo $gxwj
# #echo $gxwj| awk -F "-1.0.0" '{print $1}'
# red "$gxwj 文件无法找到更新路径，请检查！"
# fi
# }&

# wait	
# done


# }&

# wait		
# done


#开更










}


#删除更新文件
del_gxwj(){

if [[ ! -z $gxwj_mu ]]
then

	yellow "是否要删除 $gxwj_mu 下的文件？(y/回车确认；其他按键取消)"
	read tt
	
	case $tt in
			Y)
			echo "rm -rf  $gxwj_mu/*"
			;;
			y)
			echo "rm -rf  $gxwj_mu/*"
			;;
			"")
			echo "rm -rf  $gxwj_mu/*"
			;;
			*)
			yellow "好的，保留了更新文件。"
			#del_gxwj

	esac
fi


}





#三日内是否更新检查！

#三天分别是哪三天 当天 昨天和前天 如果要改 就改3的值 比如前一周  就改为7
gx_jc(){


for ((i=0;i<3;i++));
do
echo $(date -d "$i day ago" +%Y%m%d) >> ./last_gxsj.log
#echo 这里跑过了哦

done






#遍历这三天
for gxsj in `tail -3 ./last_gxsj.log`
do
if [[ ! -f "./gx.log" ]]
then

touch ./gx.log
#echo "gx.log 创建成功！"
fi

sfgx=()
#echo $gxsj
sfgx+=(`tail -3 ./gx.log |grep "$gxsj"` )

#echo "$sfgx" | sed 's/ /\n/g' |sort

if [[ $sfgx == '' ]]
then

yellow "三日内没有更新记录，你确定要继续更新吗？！"
yellow "确定请按回车"
read -aa 
break 2

else
red "近三日内有更新哦，你确定还要继续更新嘛？！"
echo
yellow "更新日志如下:"
echo "${sfgx[*]}" | sed 's/ /\n/g' |sort
echo
yellow "确定请按回车"
read -aa 

fi

yellow "好的，开始关闭tomcat服务！"
echo -e "\n" | killtomcat ${*}
echo
yellow "开始执行备份任务！"
echo -e "\n" | bfwjcx ${*}
echo
yellow "开始文件处理，请稍后。。。"
gx_zb ${*}

yellow "即将启动服务，请等待。。。"
sleep 2s
#再启动服务
echo -e "\n" |start_tomcat ${*}
echo
green "恭喜，更新完成！"
echo

del_gxwj

sleep 2s
break 2



done

}
































###################################################################
#切换nginx
qh_nginx(){
if [[ "$fwqm" =~ "跳板机" ]]
then


while :
do
clear
blue "请选择要切换到nginx配置文件"
yellow "1.切换到http模式"
yellow "2.切换到https 8088端口模式"
yellow "3.退出"
echo
yellow "请输入你要执行的选项："
read qh_ng
case $qh_ng in
1)
\cp -r /home/ccgrsc/pc/js/configa.js-2 /home/ccgrsc/pc/js/config.js
cd /usr/local/nginx/sbin && ./nginx -s stop && ./nginx -c /usr/local/nginx/conf/nginx.conf
if [[ $? -eq 0 ]]
then
sleep 1s
green "切换到HTTP成功,将在1s后退出！"
sleep 1s
break
else
red "切换到HTTP失败！请检查！"
read aa
fi

;;
2)
\cp -r /home/ccgrsc/pc/js/configa.js-1 /home/ccgrsc/pc/js/config.js
cd /usr/local/nginx/sbin && ./nginx -s stop && ./nginx -c /usr/local/nginx/conf/nginx-8088.conf
if [[ $? -eq 0 ]]
then
green "切换到HTTPS(8088)成功！"
sleep 1s
break
else
red "切换到HTTPS(8088)失败！请检查！"
read aa
fi
;;
3)
break 

;;
*)
read "输入错误，请重新输入！"

esac
done

else
red "该功能为长城国瑞测试环境专属，请在跳板机服务器下运行！"
sleep 2s
fi	
}








##########################
#回滚上一个版本的文件


#选择你要回滚的文件
hg_tomcat(){

while :
do

if [[ "$xz1" == "1" ]] || [[ "$xz2" == "1" ]]
then
yellow "当前服务的备份文件目录："
#red "请确定要关闭这个服务吗？(Y/y/回车确认；其他按键取消)"
hg_lv ${ggcz_list_pt1[*]}

break 1

elif [[ "$xz1" == "2" ]] || [[ "$xz2" == "4" ]]
then
yellow "ok,bye！"
sleep 1s

break 1

elif [[ "$xz2" == "2" ]]
then
yellow "当前服务的备份文件目录："
#red "请确定要关闭这个服务吗？(Y/y/回车确认；其他按键取消)"
hg_lv ${ggcz_list_pt2[*]}

break 1
elif [[ "$xz2" == "3" ]]
then
yellow "当前服务的备份文件目录："

hg_lv ${gg_list[*]}


break 1
else
red "你的选择有误！请重新选择！"
read aa
czwztx
fi
done

}






hg_lv(){

#打印出所有可以回滚的文件，让客户输入时间代码 0803 0923 之类的  
#yellow ""
xzhgwjsz=()
hgwj=()
for hg_wj in ${*}
do
	#echo ${hg_wj[*]}
	guanjianzi=`echo $hg_wj| awk -F '/' 'OFS="/" {$NF="";print}'`
	guanjianzi2=`echo $hg_wj| awk -F '/' '{print $NF}'`
	
	#echo $guanjianzi
	#echo $guanjianzi2
	#echo "find $guanjianzi -maxdepth 2 -name "*.tar.gz"| grep "$guanjianzi2-[0-9]{8}""
	
	hgwj+=(`find $guanjianzi -maxdepth 2 -name "*.tar.gz"| grep "$guanjianzi2"| grep "[0-9{8}]"` )
done
	echo "${hgwj[*]}" | sed 's/ /\n/g'
	#echo done

while :
do
	yellow "请输入你要回滚的版本时间(请按20220808格式输入):"
	read hgsj
	echo
	if [[ $hgsj =~ [0-9{8}] ]]
	then
		yellow "你输入的时间是$hgsj"
		
		break 1

	else
		red "输入错误，请重新输入！"
		read aa
	fi	

done

	read aa
	#echo 123
	
	

for xzhgwj in ${hgwj[*]}
do
	#echo "echo $xzhgwj| grep "$hgsj""
	if [[ -a `echo $xzhgwj| grep "$hgsj"` ]]
	then
	
	#更新文件的数组
		xzhgwjsz+=($xzhgwj )
	
		
	fi
done
	
	if [[ ! -z ${xzhgwjsz[*]} ]]
	then
		yellow "通过搜索找到以下备份文件："
		yellow "${xzhgwjsz[*]} "| sed 's/ /\n/g'
		
	else 
		red "你输入的时间节点不存在符合条件的备份文件，请检查！"
		read aa
		echo
		yellow "当前服务的备份文件目录："
		hg_lv ${*}
	fi

	red "你确定要执行以上文件的回滚操作嘛？！"
	red "将会删除掉然后替换文件，请确定！"
	read aa
	
	echo
	yellow "执行删除任务。。。"
	for zcxzhgwj in ${xzhgwjsz[*]}
	do
		if [[ -d `echo $zcxzhgwj| awk -F "-[0-9{8}]" '{if($1!="") print $1}'` ]]
		then
			#rm -rf "`echo $zcxzhgwj| awk -F "-[0-9{8}]" '{if($1!="") print $1}'`/*"
			echo "rm -rf "`echo $zcxzhgwj| awk -F "-[0-9{8}]" '{if($1!="") print $1}'`/*""
		
			if [[ $? -eq 0 ]]
			then
				green "旧文件`echo $zcxzhgwj| awk -F "-[0-9{8}]" '{if($1!="") print $1}'`/*""删除成功！"
			else
				red "旧文件`echo $zcxzhgwj| awk -F "-[0-9{8}]" '{if($1!="") print $1}'`/*""删除失败！"
				read aa
				break 3
			fi
		else
			red "`echo $zcxzhgwj| awk -F "-[0-9{8}]" '{if($1!="") print $1}'`为空，禁止进行危险操作！！！"
			break 3
		fi
	done
	
	echo
	yellow "执行恢复任务。。。"
	for hsxzhgwj in ${xzhgwjsz[*]}
	do
		if [[ ! -z "${hsxzhgwj}" ]]
		then
			# tar -zxvf ${hsxzhgwj} 
			echo "tar -zxvf ${hsxzhgwj} "
			if [[ $? -eq 0 ]]
			then
				green "${hsxzhgwj} 还原完成！"
			else
				red "${hsxzhgwj} 还原失败！"
			fi
			
			
		else
			red "${hsxzhgwj} 为空！请检查！"
		fi
	done
	
	yellow "									#回滚任务执行完成！请确认"
	read aa
	break

	
}


	











while :
do
list
clear
welcome
blue "1.一键备份                             (已经完成)"
blue "2.一键更新                             (已经完成)"
blue "6.切换nginx                            (已经完成)"
blue "7.回滚上一个版本                       (已经完成)"
blue "8.查看当前备份的文件                   (待完成)"
blue "9.一键kill_tomcat                      (已经完成)"
blue "10.一键start_tomcat                    (已经完成)"
blue "11.一键restart_all_tomcat              (已经完成)"
blue "0.退出"
yellow "请选择您要进行的任务："
read aNum
case $aNum in
#备份
1)
yellow "将要进行备份！"
czwztx
xz
;;
2)
czwztx
xz_gx
:
;;
3)
echo "列表是"
#echo $gxwj_list | sed 's/ /\n/g'|sort
read aa
clear
;;
4)
:
;;
5)
:
;;
6)
qh_nginx
;;
7)
czwztx
hg_tomcat

;;
8)
:
;;
#killtomcat
9)
czwztx
xz_kill_tomcat

;;
#启动tomcat
10)
czwztx
xz_start_tomcat
;;
#打印列表
11)
czwztx
red  "即将重启所选的服务，请再次确认(返回按钮失效)，选错请ctrl+c结束！"
yellow "确认无误请回车！"
read -aa
echo -e "\n"| xz_kill_tomcat && sleep 2s &&
echo -e "\n"| xz_start_tomcat
;;
#结束
0)
yellow "OK！bye！"
sleep 2s
clear
break

;;
#输入其他的
*)
red "请输入正确的指令！"
read -aa
clear
esac
done
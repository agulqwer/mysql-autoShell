
# 获取mysql初始密码函数

function getPasswdFunc(){
 	if [[ $(echo $mysqlVer|awk '{print ($0/5.6)==1}') -eq 1 ]] 
	then
		# mysql 5.6版本
		echo ""
	elif [[ $(echo $mysqlVer|awk '{print ($0/5.7)==1}') -eq 1 ]] || [[ $(echo $mysqlVer|awk '{print ($0/8.0)==1}') -eq 1 ]]
	then
		# mysql 5.7版本 mysql 8.0版本

		if [[ -n $installInfo ]]
		then
			passwd=${installInfo#*password:}
			echo $passwd
		else
			mycnf=$(mysqld --verbose --help | grep -A 1 'Default options'|awk 'NR==2{print $0}')
			passwd=" "
			for cnf in $mycnf
			do
				if [[ -f $cnf ]]
				then
					logerror=$(cat $cnf|grep "log-error")
					logerror=${logerror#*=}
					if [[ -f $logerror ]]
					then
						passwd=$(cat $logerror|awk '/localhost/{print $0}')
						passwd=${passwd##*localhost:}
						echo $passwd
					fi
				fi

			done
		fi
	fi

}


# 选择mysql版本函数
function selectMysqlFunc(){
    local ver=$1 
	case $ver in
		"mysql5_6")
			echo "选择mysql 5.6版本"
			mysqlVer=5.6

			# 搜索压缩包
			mysql_tar=($(find $baseDir -regex  ".*mysql.*5.6.*.tar[\.gz]*"))
			# mysql源码包下载路径
			mysqlDown=$mysql5_6Down

			break
			;;
		"mysql5_7")
			echo "选择mysql 5.7版本"
			mysqlVer=5.7

			# 搜索压缩包
			mysql_tar=($(find $baseDir -regex  ".*mysql.*5.7.*.tar[\.gz]*"))

			# mysql源码包下载路径
			mysqlDown=$mysql5_7Down

			break
			;;
		"mysql8_0")
			echo "选择mysql 8.0版本"
			mysqlVer=8.0

			# 搜索压缩包
			mysql_tar=($(find ./ -regex  ".*mysql.*8.0.*.tar[\.(xg)z]*"))

			# mysql源码包下载路径
			mysqlDown=$mysql8_0Down

			break
			;;
		*)
			echo "输入错误，请输入"
	esac
}


# 获取源码包
function getCodeFunc(){
    # 本地查找目录
    getCodeDir=$1

    # 线上文件下载目录
    getCodeDown=$2

    # 获取线上文件路径
    getCodeUrl=$3

    # 匹配文件正则表达式
    getCodeRegex=$4

    # 程序名
    getCodePkgName=$5
    
    # 查询可安装包
    getCodes=($(find $getCodeDir -regex $getCodeRegex))

    # 判断本地是否存在安装包
    if [[ -z $getCodes ]]
    then
        # 下载线上版本
        wget -P $getCodeDown $getCodeUrl
        getCodeTmp=${getCodeUrl##*/}
        getCodeReturn=$(find $getCodeDir -name $getCodeTmp)
        if [[ -z $getCodeReturn ]]
        then
            echo "找不到${getCodePkgName}源码包"
            exit 1
        fi 
    else
        if [[ ${#getCodes[@]} -eq 1 ]]
        then
            # 本地只有一个源码包
            getCodeReturn=${getCodes[0]}
        else
            echo -e "\033[33mYou have ${#getCodes[@]} ${getCodePkgName} package for select\033[0m"
            local count=1
            local readData=""
            local index=0
            for ((i=0;i<${#getCodes[@]};i++))
            do
                ((index+=1))
                if [[ $i -eq 0 ]]
                then
                    count="${index}"
                    echo "${index}: ${getCodes[i]} (default)"
                else
                    count="${count}, ${index}"
                    echo "${index}: ${getCodes[i]}"
                fi
            done
            echo -e "\033[33mEnter your choice (${count}):\033[0m"
            while read  readData
            do
                if [[ $readData -gt 0 ]] && [[ $readData -le ${#getCodes[@]} ]]
                then
                    let readData=$readData-1
                    getCodeReturn=${getCodes[$readData]}
                    break
                elif [[ -z $readData ]]
                then
                    getCodeReturn=${getCodes[0]}
                    break
                fi
            done

        fi
   fi

   if [[ -z $getCodeReturn ]]
   then
        echo -e "\033[31mNot Found ${getCodePkgName}\033[0m"
        exit 1
   fi
}

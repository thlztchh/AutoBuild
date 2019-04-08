# 自动打包并且上传蒲公英
# Test 环境上传到 xxx1@hadlinks.com 账号下
# Beta 环境上传到 xxx2@hadlinks.com 账号下
# Release 环境上传到AppStore
##########################################
#这里面的内容根据实际项目进行更改
##########################################

##########################################
##########################################
#上传后的链接里展示的应用名字
displayName=测试
#project name
projectName=Test
#scheme name
schemeName=Test
#苹果账号
developerAccount='xxx@hadlinks.com'
developerPassword='xxxx'
##########################################
##########################################

#环境设置 (配置了三个环境，为打包准备的是 Test, Beta, Release 三个环境，分别对应 [测试服务器] [正式服务器] [正式服务器])
echo "请选择需要打包的环境：1:Test 2:Beta 3:Release"

read environment
while [[ $environment != 1 ]] && [[ $environment != 2 ]] && [[ $environment != 3 ]]; do
    echo '请选择需要打包的环境：1:Test 2:Beta 3:Release'
    read environment
done

echo '请输入发布说明（直接 Enter 将会设置更新说明为 "Auto build  + Version + Build" ）'
read releaseNote

##########################################
##########################################
if [ $environment == 1 ];then
    buildConfiguration=Test
    #蒲公英上传到 key
    uploadKey=蒲公英账号key
    #信鸽推送的 ACCESS ID
    accessid=信鸽推送ACCESS ID
    #信鸽推送的 SECRET KEY
    secretkey=信鸽推送SECRET KEY
elif [ $environment == 2 ];then
    buildConfiguration=Beta
    #蒲公英上传到 key
    uploadKey=蒲公英账号key
    #信鸽推送的 ACCESS ID
    accessid=信鸽推送ACCESS ID
    #信鸽推送的 SECRET KEY
    secretkey=信鸽推送SECRET KEY
else
    buildConfiguration=Release
fi
##########################################
##########################################

#创建导出文件夹 (请自行在git ignore里加上对这个路径的忽略)
if [ ! -d ./AutoBuild ];then
    mkdir -p AutoBuild
fi

#日期
date=$(date '+%m-%d_%H-%M')
#absolute path
projectPath=$(cd `dirname $0`; pwd)
#与导出 ipa 文件有关的一个配置
exportOptionsPlistPath=$projectPath/File/exportOptions_$buildConfiguration.plist
#.archive 文件存储目录
archiveBuildPath=$projectPath/AutoBuild/$buildConfiguration/$date/Build
#ipa 文件导出目录
archiveExportPath=$projectPath/AutoBuild/$buildConfiguration/$date/Export

CFBundleShortVersionString='1.0.0'
CFBundleVersion='1'

function sendNotification(){

    timestamp=$(date +%s)
    message="{\"aps\":{\"alert\":{\"title\":\"😍版本更新😍\",\"body\":\"😚新版本:${CFBundleShortVersionString}已发布😚请打开应用获取更新😚\"},\"badge\":\"0\",\"category\":\"INVITE_CATEGORY\"}}"
    sign="POSTopenapi.xg.qq.com/v2/push/all_deviceaccess_id=${accessid}environment=1message=${message}message_type=0timestamp=${timestamp}${secretkey}"
    signmd5=$(md5 -qs $sign)

    echo ''
    echo "时间戳::$timestamp"
    echo ''
    echo "签名::$sign"
    echo ''
    echo "MD5::$signmd5"
    echo ''

    curl -i \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "access_id=$accessid" \
    -d "environment=1" \
    -d "message=$message" \
    -d "message_type=0" \
    -d "timestamp=$timestamp" \
    -d "sign=$signmd5" \
    http://openapi.xg.qq.com/v2/push/all_device



    echo ''
    echo ''
}

function uploadIPA(){

    echo '/// ---------- \\\'
    echo '/// 开始上传ipa \\\'
    echo '/// ---------- \\\'
    echo ''

    curl \
    -F "file=@$archiveExportPath/$schemeName.ipa" \
    -F "buildName=$displayName-$buildConfiguration" \
    -F "_api_key=$uploadKey" \
    -F "buildUpdateDescription=$releaseNote" \
    https://www.pgyer.com/apiv2/app/upload

    echo ''
    echo '/// ---------- \\\'
    echo '/// 打包上传成功 \\\'
    echo '/// ---------- \\\'
    echo ''

    sendNotification
}

function itunesConnect(){

    echo ''
    echo '/// ---------------- \\\'
    echo '/// 正在上传到AppStore \\\'
    echo '/// ---------------- \\\'
    echo ''

    /Applications/Xcode.app/Contents/Applications/Application\ Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Support/altool \
    --upload-app \
    -f "$archiveExportPath/$schemeName.ipa" \
    -u $developerAccount \
    -p $developerPassword

    echo ''
    echo '/// ---------- \\\'
    echo '/// 打包上传成功 \\\'
    echo '/// ---------- \\\'
    echo ''
}

function buildIPA(){

    echo '/// ---------- \\\'
    echo '/// 正在生成ipa \\\'
    echo '/// ---------- \\\'
    echo ''

    /usr/libexec/PlistBuddy -c "Print" $exportOptionsPlistPath
    echo ''

    xcodebuild -exportArchive \
    -archivePath $archiveBuildPath/$projectName.xcarchive \
    -exportPath $archiveExportPath \
    -exportOptionsPlist $exportOptionsPlistPath || exit

    if [ -e $archiveExportPath/$schemeName.ipa ];then

    echo '/// ---------- \\\'
    echo '/// ipa已经生成 \\\'
    echo '/// ---------- \\\'
    echo ''

    if [ $environment != 3 ];then
        uploadIPA
    else
        itunesConnect
    fi

    else

    echo '/// ---------- \\\'
    echo '/// ipa生成失败 \\\'
    echo '/// ---------- \\\'
    echo ''

    fi
}

function buildProject(){

    echo '/// ---------- \\\'
    echo '/// 正在编译工程: '$buildConfiguration
    echo '/// ---------- \\\'
    echo ''

    xcodebuild archive \
    -workspace $projectPath/$projectName.xcworkspace \
    -scheme $schemeName \
    -configuration $buildConfiguration \
    -archivePath $archiveBuildPath/$projectName.xcarchive \
    -quiet || exit

    echo '/// ---------- \\\'
    echo '/// 编译工程完成 \\\'
    echo '/// ---------- \\\'
    echo ''

    CFBundleShortVersionString=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleShortVersionString" "$archiveBuildPath/$projectName.xcarchive/Info.plist")
    CFBundleVersion=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleVersion" "$archiveBuildPath/$projectName.xcarchive/Info.plist")

    if [[ $releaseNote == '' ]];then
        releaseNote="Auto build deploy + Version:$CFBundleShortVersionString + Build:$CFBundleVersion"
    fi
}

function cleanProject(){

    echo '/// ---------- \\\'
    echo '/// 正在清理工程 \\\'
    echo '/// ---------- \\\'
    echo ''

    xcodebuild clean \
    -configuration $buildConfiguration \
    -quiet || exit

    echo '/// ---------- \\\'
    echo '/// 清理工程完成 \\\'
    echo '/// ---------- \\\'
    echo ''
}

cleanProject
buildProject
buildIPA








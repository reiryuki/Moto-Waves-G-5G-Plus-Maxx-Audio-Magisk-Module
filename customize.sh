# space
ui_print " "

# magisk
if [ -d /sbin/.magisk ]; then
  MAGISKTMP=/sbin/.magisk
else
  MAGISKTMP=`realpath /dev/*/.magisk`
fi

# path
if [ "$BOOTMODE" == true ]; then
  MIRROR=$MAGISKTMP/mirror
else
  MIRROR=
fi
SYSTEM=`realpath $MIRROR/system`
PRODUCT=`realpath $MIRROR/product`
VENDOR=`realpath $MIRROR/vendor`
SYSTEM_EXT=`realpath $MIRROR/system_ext`
if [ -d $MIRROR/odm ]; then
  ODM=`realpath $MIRROR/odm`
else
  ODM=`realpath /odm`
fi
if [ -d $MIRROR/my_product ]; then
  MY_PRODUCT=`realpath $MIRROR/my_product`
else
  MY_PRODUCT=`realpath /my_product`
fi

# optionals
OPTIONALS=/sdcard/optionals.prop
if [ ! -f $OPTIONALS ]; then
  touch $OPTIONALS
fi

# info
MODVER=`grep_prop version $MODPATH/module.prop`
MODVERCODE=`grep_prop versionCode $MODPATH/module.prop`
ui_print " ID=$MODID"
ui_print " Version=$MODVER"
ui_print " VersionCode=$MODVERCODE"
ui_print " MagiskVersion=$MAGISK_VER"
ui_print " MagiskVersionCode=$MAGISK_VER_CODE"
ui_print " "

# architecture
if [ "$ARCH" == arm64 ] || [ "$ARCH" == arm ]; then
  if [ "`grep_prop waves.32bit $OPTIONALS`" == 1 ]; then
    ARCH=arm
    IS64BIT=false
  fi
  ui_print "- Architecture $ARCH"
  ui_print " "
else
  ui_print "! Unsupported architecture $ARCH. This module is only for"
  ui_print "  arm64 or arm architecture."
  abort
fi

# bit
if [ "$IS64BIT" != true ]; then
  rm -rf `find $MODPATH/system -type d -name *64`
fi

# sdk
NUM=26
NUM2=30
if [ "$API" -lt $NUM ]; then
  ui_print "! Unsupported SDK $API. You have to upgrade your Android"
  ui_print "  version at least SDK API $NUM to use this module."
  abort
else
  if [ "$API" -gt $NUM2 ]; then
    ui_print "! Unsupported SDK $API. This module is only for SDK API"
    ui_print "  $NUM2 and bellow."
  else
    ui_print "- SDK $API"
  fi
  if [ "$API" -lt $NUM2 ]; then
    ui_print "  Using legacy version"
    cp -rf $MODPATH/system_10/* $MODPATH/system
  fi
fi
ui_print " "
rm -rf $MODPATH/system_10

# mount
if [ "$BOOTMODE" != true ]; then
  mount -o rw -t auto /dev/block/bootdevice/by-name/cust /vendor
  mount -o rw -t auto /dev/block/bootdevice/by-name/vendor /vendor
  mount -o rw -t auto /dev/block/bootdevice/by-name/persist /persist
  mount -o rw -t auto /dev/block/bootdevice/by-name/metadata /metadata
fi

# sepolicy
FILE=$MODPATH/sepolicy.rule
DES=$MODPATH/sepolicy.pfsd
if [ "`grep_prop sepolicy.sh $OPTIONALS`" == 1 ]\
&& [ -f $FILE ]; then
  mv -f $FILE $DES
fi

# motocore
if [ ! -d /data/adb/modules_update/MotoCore ]\
&& [ ! -d /data/adb/modules/MotoCore ]; then
  ui_print "- This module requires Moto Core Magisk Module installed"
  ui_print "  except you are in Motorola ROM."
  ui_print "  Please read the installation guide!"
  ui_print " "
else
  rm -f /data/adb/modules/MotoCore/remove
  rm -f /data/adb/modules/MotoCore/disable
fi

# .aml.sh
mv -f $MODPATH/aml.sh $MODPATH/.aml.sh

# function
extract_lib() {
for APPS in $APP; do
  FILE=`find $MODPATH/system -type f -name $APPS.apk`
  if [ -f `dirname $FILE`/extract ]; then
    rm -f `dirname $FILE`/extract
    ui_print "- Extracting..."
    DIR=`dirname $FILE`/lib/$ARCH
    mkdir -p $DIR
    rm -rf $TMPDIR/*
    unzip -d $TMPDIR -o $FILE $DES
    cp -f $TMPDIR/$DES $DIR
    ui_print " "
  fi
done
}

# extract
APP=MotoWaves
if [ "`grep_prop waves.32bit $OPTIONALS`" == 1 ]; then
  PROP=armeabi-v7a
else
  PROP=`getprop ro.product.cpu.abi`
fi
DES=lib/$PROP/*
extract_lib

# extract
APP=WavesService
ARCH=arm
DES=lib/armeabi-v7a/*
extract_lib

# function
check_function() {
ui_print "- Checking"
ui_print "$NAME"
ui_print "  function at"
ui_print "$FILE"
ui_print "  Please wait..."
if ! grep -Eq $NAME $FILE; then
  ui_print "  Using legacy apps"
  cp -rf $MODPATH/system_10/* $MODPATH/system
fi
ui_print " "
}

# check
if [ "$API" -ge 30 ]; then
  NAME=_ZN7android23sp_report_stack_pointerEv
  TARGET=libandroidaudioeffect_Android11.so
  LISTS=`strings $MODPATH/system/priv-app/WavesService/lib/arm/$TARGET | grep ^lib | grep .so | sed "s/$TARGET//" | sed 's/libc++_shared.so//'`
  FILE=`for LIST in $LISTS; do echo $SYSTEM/lib/$LIST; done`
  check_function
fi
rm -rf $MODPATH/system_10

# config
if [ "`grep_prop waves.config $OPTIONALS`" == pstar ]; then
  ui_print "- Using Moto Waves Edge 30 Pro (pstar) config"
  cp -rf $MODPATH/system_pstar/* $MODPATH/system
  ui_print " "
elif [ "`grep_prop waves.config $OPTIONALS`" == nio ]; then
  ui_print "- Using Moto Waves XT2125-4 (nio) config"
  cp -rf $MODPATH/system_nio/* $MODPATH/system
  ui_print " "
elif [ "`grep_prop waves.config $OPTIONALS`" == racer ]; then
  ui_print "- Using Moto Waves Edge (racer) config"
  cp -rf $MODPATH/system_racer/* $MODPATH/system
  ui_print " "
fi
rm -rf $MODPATH/system_pstar
rm -rf $MODPATH/system_nio
rm -rf $MODPATH/system_racer

# mod ui
if [ "`grep_prop mod.ui $OPTIONALS`" == 1 ]; then
  APP=MotoWaves
  FILE=/sdcard/$APP.apk
  DIR=`find $MODPATH/system -type d -name $APP`
  ui_print "- Using modified UI apk..."
  if [ -f $FILE ]; then
    cp -f $FILE $DIR
    chmod 0644 $DIR/$APP.apk
    ui_print "  Applied"
  else
    ui_print "  ! There is no $FILE file."
    ui_print "    Please place the apk to your internal storage first"
    ui_print "    and reflash!"
  fi
  ui_print " "
fi

# cleaning
ui_print "- Cleaning..."
PKG=`cat $MODPATH/package.txt`
if [ "$BOOTMODE" == true ]; then
  for PKGS in $PKG; do
    RES=`pm uninstall $PKGS 2>/dev/null`
  done
fi
rm -rf /metadata/magisk/$MODID
rm -rf /mnt/vendor/persist/magisk/$MODID
rm -rf /persist/magisk/$MODID
rm -rf /data/unencrypted/magisk/$MODID
rm -rf /cache/magisk/$MODID
ui_print " "

# power save
FILE=$MODPATH/system/etc/sysconfig/*
if [ "`grep_prop power.save $OPTIONALS`" == 1 ]; then
  ui_print "- $MODNAME will not be allowed in power save."
  ui_print "  It may save your battery but decreasing $MODNAME performance."
  for PKGS in $PKG; do
    sed -i "s/<allow-in-power-save package=\"$PKGS\"\/>//g" $FILE
    sed -i "s/<allow-in-power-save package=\"$PKGS\" \/>//g" $FILE
  done
  ui_print " "
fi

# function
cleanup() {
if [ -f $DIR/uninstall.sh ]; then
  sh $DIR/uninstall.sh
fi
DIR=/data/adb/modules_update/$MODID
if [ -f $DIR/uninstall.sh ]; then
  sh $DIR/uninstall.sh
fi
}

# cleanup
DIR=/data/adb/modules/$MODID
FILE=$DIR/module.prop
if [ "`grep_prop data.cleanup $OPTIONALS`" == 1 ]; then
  sed -i 's/^data.cleanup=1/data.cleanup=0/' $OPTIONALS
  ui_print "- Cleaning-up $MODID data..."
  cleanup
  ui_print " "
elif [ -d $DIR ] && ! grep -Eq "$MODNAME" $FILE; then
  ui_print "- Different version detected"
  ui_print "  Cleaning-up $MODID data..."
  cleanup
  ui_print " "
fi

# function
permissive_2() {
sed -i '1i\
SELINUX=`getenforce`\
if [ "$SELINUX" == Enforcing ]; then\
  magiskpolicy --live "permissive *"\
fi\' $MODPATH/post-fs-data.sh
}
permissive() {
SELINUX=`getenforce`
if [ "$SELINUX" == Enforcing ]; then
  setenforce 0
  SELINUX=`getenforce`
  if [ "$SELINUX" == Enforcing ]; then
    ui_print "  Your device can't be turned to Permissive state."
    ui_print "  Using Magisk Permissive mode instead."
    permissive_2
  else
    setenforce 1
    sed -i '1i\
SELINUX=`getenforce`\
if [ "$SELINUX" == Enforcing ]; then\
  setenforce 0\
fi\' $MODPATH/post-fs-data.sh
  fi
fi
}

# permissive
if [ "`grep_prop permissive.mode $OPTIONALS`" == 1 ]; then
  ui_print "- Using device Permissive mode."
  rm -f $MODPATH/sepolicy.rule
  permissive
  ui_print " "
elif [ "`grep_prop permissive.mode $OPTIONALS`" == 2 ]; then
  ui_print "- Using Magisk Permissive mode."
  rm -f $MODPATH/sepolicy.rule
  permissive_2
  ui_print " "
fi

# function
hide_oat() {
for APPS in $APP; do
  mkdir -p `find $MODPATH/system -type d -name $APPS`/oat
  touch `find $MODPATH/system -type d -name $APPS`/oat/.replace
done
}
replace_dir() {
if [ -d $DIR ]; then
  mkdir -p $MODDIR
  touch $MODDIR/.replace
fi
}
hide_app() {
DIR=$SYSTEM/app/$APPS
MODDIR=$MODPATH/system/app/$APPS
replace_dir
DIR=$SYSTEM/priv-app/$APPS
MODDIR=$MODPATH/system/priv-app/$APPS
replace_dir
DIR=$PRODUCT/app/$APPS
MODDIR=$MODPATH/system/product/app/$APPS
replace_dir
DIR=$PRODUCT/priv-app/$APPS
MODDIR=$MODPATH/system/product/priv-app/$APPS
replace_dir
DIR=$MY_PRODUCT/app/$APPS
MODDIR=$MODPATH/system/product/app/$APPS
replace_dir
DIR=$MY_PRODUCT/priv-app/$APPS
MODDIR=$MODPATH/system/product/priv-app/$APPS
replace_dir
DIR=$PRODUCT/preinstall/$APPS
MODDIR=$MODPATH/system/product/preinstall/$APPS
replace_dir
DIR=$SYSTEM_EXT/app/$APPS
MODDIR=$MODPATH/system/system_ext/app/$APPS
replace_dir
DIR=$SYSTEM_EXT/priv-app/$APPS
MODDIR=$MODPATH/system/system_ext/priv-app/$APPS
replace_dir
DIR=$VENDOR/app/$APPS
MODDIR=$MODPATH/system/vendor/app/$APPS
replace_dir
DIR=$VENDOR/euclid/product/app/$APPS
MODDIR=$MODPATH/system/vendor/euclid/product/app/$APPS
replace_dir
}

# hide
APP="`ls $MODPATH/system/priv-app` `ls $MODPATH/system/app`"
hide_oat
APP="MusicFX MotoWavesV2 WavesServiceV2"
for APPS in $APP; do
  hide_app
done

# stream mode
FILE=$MODPATH/.aml.sh
PROP=`grep_prop stream.mode $OPTIONALS`
if echo "$PROP" | grep -Eq m; then
  ui_print "- Activating music stream..."
  sed -i 's/#m//g' $FILE
  sed -i 's/musicstream=/musicstream=true/g' $MODPATH/acdb.conf
  ui_print " "
else
  APP=AudioFX
  for APPS in $APP; do
    hide_app
  done
fi
if echo "$PROP" | grep -Eq r; then
  ui_print "- Activating ring stream..."
  sed -i 's/#r//g' $FILE
  ui_print " "
fi
if echo "$PROP" | grep -Eq a; then
  ui_print "- Activating alarm stream..."
  sed -i 's/#a//g' $FILE
  ui_print " "
fi
if echo "$PROP" | grep -Eq s; then
  ui_print "- Activating system stream..."
  sed -i 's/#s//g' $FILE
  ui_print " "
fi
if echo "$PROP" | grep -Eq v; then
  ui_print "- Activating voice_call stream..."
  sed -i 's/#v//g' $FILE
  ui_print " "
fi
if echo "$PROP" | grep -Eq n; then
  ui_print "- Activating notification stream..."
  sed -i 's/#n//g' $FILE
  ui_print " "
fi

# copy
NAME=libadspd.so
APP=MotoWaves
DIR=`find $MODPATH/system -type d -name $APP`/lib/arm
cp -f $SYSTEM/lib/$NAME $DIR
cp -f $VENDOR/lib/$NAME $DIR
cp -f $ODM/lib/$NAME $DIR
if [ "$IS64BIT" == true ]; then
  DIR=`find $MODPATH/system -type d -name $APP`/lib/arm64
  cp -f $SYSTEM/lib64/$NAME $DIR
  cp -f $VENDOR/lib64/$NAME $DIR
  cp -f $ODM/lib64/$NAME $DIR
fi

# check
NAME=libc++_shared.so
for NAMES in $NAME; do
  FILE=$VENDOR/lib/$NAMES
  if [ -f $FILE ]; then
    ui_print "- Detected $NAMES"
    ui_print " "
    rm -f $MODPATH/system/vendor/lib/$NAMES
  fi
done

# audio rotation
FILE=$MODPATH/service.sh
if [ "`grep_prop audio.rotation $OPTIONALS`" == 1 ]; then
  ui_print "- Activating ro.audio.monitorRotation=true"
  sed -i '1i\
resetprop ro.audio.monitorRotation true' $FILE
  ui_print " "
fi

# raw
FILE=$MODPATH/.aml.sh
if [ "`grep_prop disable.raw $OPTIONALS`" == 0 ]; then
  ui_print "- Not disabling Ultra Low Latency playback (RAW)"
  ui_print " "
else
  sed -i 's/#u//g' $FILE
fi

# other
FILE=$MODPATH/service.sh
if [ "`grep_prop other.etc $OPTIONALS`" == 1 ]; then
  ui_print "- Activating other etc files bind mount..."
  sed -i 's/#p//g' $FILE
  ui_print " "
fi

# permission
ui_print "- Setting permission..."
DIR=`find $MODPATH/system/vendor -type d`
for DIRS in $DIR; do
  chown 0.2000 $DIRS
done
ui_print " "






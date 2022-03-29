(

mount /data
mount -o rw,remount /data
MODPATH=${0%/*}

# debug
magiskpolicy --live "dontaudit system_server system_file file write"
magiskpolicy --live "allow     system_server system_file file write"
exec 2>$MODPATH/debug-pfsd.log
set -x

# run
FILE=$MODPATH/sepolicy.sh
if [ -f $FILE ]; then
  sh $FILE
fi

# etc
if [ -d /sbin/.magisk ]; then
  MAGISKTMP=/sbin/.magisk
else
  MAGISKTMP=`find /dev -mindepth 2 -maxdepth 2 -type d -name .magisk`
fi
ETC=$MAGISKTMP/mirror/system/etc
VETC=$MAGISKTMP/mirror/system/vendor/etc
VOETC=$MAGISKTMP/mirror/system/vendor/odm/etc
MODETC=$MODPATH/system/etc
MODVETC=$MODPATH/system/vendor/etc
MODVOETC=$MODPATH/system/vendor/odm/etc

# conflicts
MOD=/data/adb/modules
AML=$MOD/aml
ACDB=$MOD/acdb
if [ -d $AML ] && [ -d $ACDB ]; then
  rm -rf $ACDB
fi
XML=`find $MOD/*/system -type f -name com.motorola.gamemode.xml`
APK=`find $MOD/*/system -type f -name MotoGametime.apk`
if [ "$XML" ] && [ ! "$APK" ]; then
  mv -f $XML $MOD
fi
rm -f /data/adb/modules/*/system/app/MotoSignatureApp/.replace

# directory
SKU=`ls $VETC/audio | grep sku_`
if [ "$SKU" ]; then
  for SKUS in $SKU; do
    mkdir -p $MODVETC/audio/$SKUS
  done
fi
PROP=`getprop ro.build.product`
if [ -d $VETC/audio/"$PROP" ]; then
  mkdir -p $MODVETC/audio/"$PROP"
fi

# audio effects
NAME=*audio*effects*
rm -f `find $MODPATH/system -type f -name $NAME.conf -o -name $NAME.xml`
if [ ! -d $ACDB ] || [ -f $ACDB/disable ]; then
  AE=`find $ETC -maxdepth 1 -type f -name $NAME.conf -o -name $NAME.xml`
  VAE=`find $VETC -maxdepth 1 -type f -name $NAME.conf -o -name $NAME.xml`
  VOAE=`find $VOETC -maxdepth 1 -type f -name $NAME.conf -o -name $NAME.xml`
  if [ "$AE" ]; then
    cp -f $AE $MODETC
  fi
  if [ "$VAE" ]; then
    cp -f $VAE $MODVETC
  fi
  if [ "$VOAE" ]; then
    cp -f $VOAE $MODVOETC
  fi
  if [ "$SKU" ]; then
    for SKUS in $SKU; do
      VSAE=`find $VETC/audio/$SKUS -maxdepth 1 -type f -name $NAME.conf -o -name $NAME.xml`
      if [ "$VSAE" ]; then
        cp -f $VSAE $MODVETC/audio/$SKUS
      fi
    done
  fi
  if [ -d $VETC/audio/"$PROP" ]; then
    VBAE=`find $VETC/audio/"$PROP" -maxdepth 1 -type f -name $NAME.conf -o -name $NAME.xml`
    if [ "$VBAE" ]; then
      cp -f $VBAE $MODVETC/audio/"$PROP"
    fi
  fi
fi

# audio policy
NAME=*policy*
rm -f `find $MODPATH/system -type f -name $NAME.conf -o -name $NAME.xml`
AP=`find $ETC -maxdepth 1 -type f -name $NAME.conf -o -name $NAME.xml`
VAP=`find $VETC -maxdepth 1 -type f -name $NAME.conf -o -name $NAME.xml`
VAAP=`find $VETC/audio -maxdepth 1 -type f -name $NAME.conf -o -name $NAME.xml`
VOAP=`find $VOETC -maxdepth 1 -type f -name $NAME.conf -o -name $NAME.xml`
if [ "$AP" ]; then
  cp -f $AP $MODETC
fi
if [ "$VAP" ]; then
  cp -f $VAP $MODVETC
fi
if [ "$VAAP" ]; then
  cp -f $VAAP $MODVETC/audio
fi
if [ "$VOAP" ]; then
  cp -f $VOAP $MODVOETC
fi
if [ "$SKU" ]; then
  for SKUS in $SKU; do
    VSAP=`find $VETC/audio/$SKUS -maxdepth 1 -type f -name $NAME.conf -o -name $NAME.xml`
    if [ "$VSAP" ]; then
      cp -f $VSAP $MODVETC/audio/$SKUS
    fi
  done
fi
if [ -d $VETC/audio/"$PROP" ]; then
  VBAP=`find $VETC/audio/"$PROP" -maxdepth 1 -type f -name $NAME.conf -o -name $NAME.xml`
  if [ "$VBAP" ]; then
    cp -f $VBAP $MODVETC/audio/"$PROP"
  fi
fi

# aml fix
DIR=$AML/system/vendor/odm/etc
if [ "$VOAE" ] || [ "$VOAP" ]; then
  if [ -d $AML ] && [ ! -d $DIR ]; then
    mkdir -p $DIR
    if [ "$VOAE" ]; then
      cp -f $VOAE $DIR
    fi
    if [ "$VOAP" ]; then
      cp -f $VOAP $DIR
    fi
  fi
fi
magiskpolicy --live "dontaudit vendor_configs_file labeledfs filesystem associate"
magiskpolicy --live "allow     vendor_configs_file labeledfs filesystem associate"
magiskpolicy --live "dontaudit init vendor_configs_file dir relabelfrom"
magiskpolicy --live "allow     init vendor_configs_file dir relabelfrom"
magiskpolicy --live "dontaudit init vendor_configs_file file relabelfrom"
magiskpolicy --live "allow     init vendor_configs_file file relabelfrom"
chcon -R u:object_r:vendor_configs_file:s0 $DIR

# run
sh $MODPATH/.aml.sh

# directory
DIR=/data/waves
if [ ! -d $DIR ]; then
  mkdir -p $DIR
  chown 1013.1013 $DIR
fi

# cleaning
FILE=$MODPATH/cleaner.sh
if [ -f $FILE ]; then
  sh $FILE
  rm -f $FILE
fi

) 2>/dev/null



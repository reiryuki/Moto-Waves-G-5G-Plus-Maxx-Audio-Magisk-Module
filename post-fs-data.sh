mount -o rw,remount /data
MODPATH=${0%/*}

# log
exec 2>$MODPATH/debug-pfsd.log
set -x

# var
ABI=`getprop ro.product.cpu.abi`
FIRARCH=`getprop ro.bionic.arch`
SECARCH=`getprop ro.bionic.2nd_arch`
ABILIST=`getprop ro.product.cpu.abilist`
if [ ! "$ABILIST" ]; then
  ABILIST=`getprop ro.system.product.cpu.abilist`
fi
if [ "$FIRARCH" == arm64 ]\
&& ! echo "$ABILIST" | grep -q arm64-v8a; then
  if [ "$ABILIST" ]; then
    ABILIST="$ABILIST,arm64-v8a"
  else
    ABILIST=arm64-v8a
  fi
fi
if [ "$FIRARCH" == x64 ]\
&& ! echo "$ABILIST" | grep -q x86_64; then
  if [ "$ABILIST" ]; then
    ABILIST="$ABILIST,x86_64"
  else
    ABILIST=x86_64
  fi
fi
if [ "$SECARCH" == arm ]\
&& ! echo "$ABILIST" | grep -q armeabi; then
  if [ "$ABILIST" ]; then
    ABILIST="$ABILIST,armeabi"
  else
    ABILIST=armeabi
  fi
fi
if [ "$SECARCH" == arm ]\
&& ! echo "$ABILIST" | grep -q armeabi-v7a; then
  if [ "$ABILIST" ]; then
    ABILIST="$ABILIST,armeabi-v7a"
  else
    ABILIST=armeabi-v7a
  fi
fi
if [ "$SECARCH" == x86 ]\
&& ! echo "$ABILIST" | grep -q x86; then
  if [ "$ABILIST" ]; then
    ABILIST="$ABILIST,x86"
  else
    ABILIST=x86
  fi
fi

# function
permissive() {
if [ "`toybox cat $FILE`" = 1 ]; then
  chmod 640 $FILE
  chmod 440 $FILE2
  echo 0 > $FILE
fi
}
magisk_permissive() {
if [ "`toybox cat $FILE`" = 1 ]; then
  if [ -x "`command -v magiskpolicy`" ]; then
	magiskpolicy --live "permissive *"
  else
	$MODPATH/$ABI/libmagiskpolicy.so --live "permissive *"
  fi
fi
}
sepolicy_sh() {
if [ -f $FILE ]; then
  if [ -x "`command -v magiskpolicy`" ]; then
    magiskpolicy --live --apply $FILE 2>/dev/null
  else
    $MODPATH/$ABI/libmagiskpolicy.so --live --apply $FILE 2>/dev/null
  fi
fi
}

# selinux
FILE=/sys/fs/selinux/enforce
FILE2=/sys/fs/selinux/policy
#1permissive
chmod 0755 $MODPATH/*/libmagiskpolicy.so
#2magisk_permissive
FILE=$MODPATH/sepolicy.rule
#ksepolicy_sh
FILE=$MODPATH/sepolicy.pfsd
sepolicy_sh

# conflict
MOD=/data/adb/modules
XML=`find $MOD -type f -name com.motorola.gamemode.xml`
APK=`find $MOD -type f -name MotoGametime.apk`
if [ "$XML" ] && [ ! "$APK" ]; then
  rm -f $XML
fi

# run
. $MODPATH/copy.sh

# conflict
AML=/data/adb/modules/aml
ACDB=/data/adb/modules/acdb
if [ -d $ACDB ] && [ ! -f $ACDB/disable ]; then
  if [ ! -d $AML ] || [ -f $AML/disable ]; then
    rm -f `find $MODPATH/system/etc $MODPATH/vendor/etc\
     $MODPATH/system/vendor/etc -maxdepth 1 -type f -name\
     *audio*effects*.conf -o -name *audio*effects*.xml`
  fi
fi

# run
. $MODPATH/.aml.sh

# directory
DIR=/data/waves
mkdir -p $DIR
chown 1013.1013 $DIR

# permission
DIRS=`find $MODPATH/vendor\
           $MODPATH/system/vendor -type d`
for DIR in $DIRS; do
  chown 0.2000 $DIR
done
chcon -R u:object_r:system_lib_file:s0 $MODPATH/system/lib*
chcon -R u:object_r:vendor_configs_file:s0 $MODPATH/system/odm/etc
if [ -L $MODPATH/system/vendor ]\
&& [ -d $MODPATH/vendor ]; then
  FILES=`find $MODPATH/vendor/lib* -type f`
  for FILE in $FILES; do
    chmod 0644 $FILE
    chown 0.0 $FILE
  done
  chcon -R u:object_r:vendor_file:s0 $MODPATH/vendor
  chcon -R u:object_r:vendor_configs_file:s0 $MODPATH/vendor/etc
  chcon -R u:object_r:vendor_configs_file:s0 $MODPATH/vendor/odm/etc
else
  FILES=`find $MODPATH/system/vendor/lib* -type f`
  for FILE in $FILES; do
    chmod 0644 $FILE
    chown 0.0 $FILE
  done
  chcon -R u:object_r:vendor_file:s0 $MODPATH/system/vendor
  chcon -R u:object_r:vendor_configs_file:s0 $MODPATH/system/vendor/etc
  chcon -R u:object_r:vendor_configs_file:s0 $MODPATH/system/vendor/odm/etc
fi

# function
patch_public_libraries() {
for NAME in $NAMES; do
  for FILE in $FILES; do
    if ! grep $NAME $FILE; then
      if echo "$ABILIST" | grep arm64-v8a\
      && ! echo "$ABILIST" | grep armeabi-v7a; then
        echo "$NAME 64" >> $FILE
      else
        echo $NAME >> $FILE
      fi
    fi
  done
done
if [ ! "$DUPS" ]; then
  for FILE in $FILES; do
    chmod 0644 $FILE
  done
fi
}

# check & patch
NAMES=libadspd.so
for NAME in $NAMES; do
  FILES=`find $MODPATH/system -type f -path "*/lib/arm64/$NAME*"`
  if [ -f /system/lib64/$NAME ]\
  || [ -f /vendor/lib64/$NAME ]\
  || [ -f /odm/lib64/$NAME ]; then
    for FILE in $FILES; do
      mv -f $FILE $FILE.unused
    done
  else
    for FILE in $FILES; do
      mv -f $FILE.unused $FILE
    done
  fi
  FILE=`find $MODPATH/system -type f -path "*/lib/arm/$NAME*"`
  if [ -f /system/lib/$NAME ]\
  || [ -f /vendor/lib/$NAME ]\
  || [ -f /odm/lib/$NAME ]; then
    for FILE in $FILES; do
      mv -f $FILE $FILE.unused
    done
  else
    for FILE in $FILES; do
      mv -f $FILE.unused $FILE
    done
  fi
done
MODID=`basename "$MODPATH"`
VETC=/vendor/etc
if [ -L $MODPATH/system/vendor ]\
&& [ -d $MODPATH/vendor ]; then
  MODVETC=$MODPATH$VETC
else
  MODVETC=$MODPATH/system$VETC
fi
DES=public.libraries.txt
rm -f `find $MODPATH -type f -name $DES`
if [ -L $MODPATH/system/vendor ]\
&& [ -d $MODPATH/vendor ]; then
  DUPS=`find /data/adb/modules/*$VETC ! -path "*/$MODID/*" -maxdepth 1 -type f -name $DES`
else
  DUPS=`find /data/adb/modules/*/system$VETC ! -path "*/$MODID/*" -maxdepth 1 -type f -name $DES`
fi
if [ "$DUPS" ]; then
  FILES=$DUPS
else
#p  cp -af $VETC/$DES $MODVETC
  FILES=$MODVETC/$DES
fi
#ppatch_public_libraries
for NAME in $NAMES; do
  CON=u:object_r:same_process_hal_file:s0
  if [ -L $MODPATH/system/vendor ]\
  && [ -d $MODPATH/vendor ]; then
    rm -f $MODPATH/vendor/lib*/$NAME
    if ! ls -Z /vendor/lib64/$NAME | grep $CON; then
      cp -af /vendor/lib64/$NAME $MODPATH/vendor/lib64
    fi
    if ! ls -Z /vendor/lib/$NAME | grep $CON; then
      cp -af /vendor/lib/$NAME $MODPATH/vendor/lib
    fi
    chcon $CON $MODPATH/vendor/lib*/$NAME
  else
    rm -f $MODPATH/system/vendor/lib*/$NAME
    if ! ls -Z /vendor/lib64/$NAME | grep $CON; then
      cp -af /vendor/lib64/$NAME $MODPATH/system/vendor/lib64
    fi
    if ! ls -Z /vendor/lib/$NAME | grep $CON; then
      cp -af /vendor/lib/$NAME $MODPATH/system/vendor/lib
    fi
    chcon $CON $MODPATH/system/vendor/lib*/$NAME
  fi
done
if [ ! "$DUPS" ]; then
  for FILE in $FILES; do
    chcon u:object_r:vendor_configs_file:s0 $FILE
  done
fi

# function
mount_odm() {
DIR=$MODPATH/system/odm
FILES=`find $DIR -type f -name $AUD`
for FILE in $FILES; do
  DES=/odm`echo $FILE | sed "s|$DIR||g"`
  if [ -f $DES ]; then
    umount $DES
    mount -o bind $FILE $DES
  fi
done
}
mount_my_product() {
DIR=$MODPATH/system/my_product
FILES=`find $DIR -type f -name $AUD`
for FILE in $FILES; do
  DES=/my_product`echo $FILE | sed "s|$DIR||g"`
  if [ -f $DES ]; then
    umount $DES
    mount -o bind $FILE $DES
  fi
done
}

# mount
if [ -d /odm ] && [ "`realpath /odm/etc`" == /odm/etc ]\
&& ! grep /odm /data/adb/magisk/magisk\
&& ! grep /odm /data/adb/magisk/magisk64\
&& ! grep /odm /data/adb/magisk/magisk32; then
  mount_odm
fi
if [ -d /my_product ]\
&& ! grep /my_product /data/adb/magisk/magisk\
&& ! grep /my_product /data/adb/magisk/magisk64\
&& ! grep /my_product /data/adb/magisk/magisk32; then
  mount_my_product
fi

# cleaning
FILE=$MODPATH/cleaner.sh
if [ -f $FILE ]; then
  . $FILE
  mv -f $FILE $FILE.txt
fi











mount -o rw,remount /data
MODPATH=${0%/*}

# log
exec 2>$MODPATH/debug-pfsd.log
set -x

# function
set_perm() {
  chown $2:$3 $1 || return 1
  chmod $4 $1 || return 1
  local CON=$5
  [ -z $CON ] && CON=u:object_r:system_file:s0
  chcon $CON $1 || return 1
}
set_perm_recursive() {
  find $1 -type d 2>/dev/null | while read dir; do
    set_perm $dir $2 $3 $4 $6
  done
  find $1 -type f -o -type l 2>/dev/null | while read file; do
    set_perm $file $2 $3 $5 $6
  done
}

# permission
set_perm_recursive $MODPATH 0 0 0755 0644

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
if [ ! -d $MODPATH/vendor ]\
|| [ -L $MODPATH/vendor ]; then
  MODSYSTEM=/system
fi
MOD=/data/adb/modules/nomount
NM=$MOD/bin/nm
NOMOUNT=false
[ ! -f $MOD/disable ] && [ -x $NM ] && $NM v >/dev/null 2>&1 && NOMOUNT=true

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

# conflict
NAMES="ainur_narsil zyx_ainur_silmaril"
for NAME in $NAMES; do
  DIR=/data/adb/modules/$NAME
  if [ -d $DIR ] && [ ! -f $DIR/remove ]; then
    touch $DIR/remove
  fi
done

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
chcon -R u:object_r:vendor_file:s0 $MODPATH$MODSYSTEM/vendor
chcon -R u:object_r:vendor_configs_file:s0 $MODPATH$MODSYSTEM/vendor/etc
chcon -R u:object_r:vendor_configs_file:s0 $MODPATH$MODSYSTEM/vendor/odm/etc

# function
check_library() {
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
}
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
#pcheck_library
MODID=`basename "$MODPATH"`
VETC=/vendor/etc
MODVETC=$MODPATH$MODSYSTEM$VETC
DES=public.libraries.txt
rm -f `find $MODPATH -type f -name $DES`
DUPS=`find /data/adb/modules/*$MODSYSTEM$VETC ! -path "*/$MODID/*" -maxdepth 1 -type f -name $DES`
if [ "$DUPS" ]; then
  FILES=$DUPS
else
#p  cp -af $VETC/$DES $MODVETC
  FILES=$MODVETC/$DES
fi
#ppatch_public_libraries
for NAME in $NAMES; do
  rm -f $MODPATH$MODSYSTEM/vendor/lib*/$NAME
  CON=u:object_r:same_process_hal_file:s0
  if [ -f /vendor/lib64/$NAME ]\
  && ! ls -Z /vendor/lib64/$NAME | grep $CON; then
    cp -af /vendor/lib64/$NAME $MODPATH$MODSYSTEM/vendor/lib64
  elif [ -f /odm/lib64/$NAME ]\
  && ! ls -Z /odm/lib64/$NAME | grep $CON; then
    cp -af /odm/lib64/$NAME $MODPATH$MODSYSTEM/vendor/lib64
  fi
  if [ -f /vendor/lib/$NAME ]\
  && ! ls -Z /vendor/lib/$NAME | grep $CON; then
    cp -af /vendor/lib/$NAME $MODPATH$MODSYSTEM/vendor/lib
  elif [ -f /odm/lib/$NAME ]\
  && ! ls -Z /odm/lib/$NAME | grep $CON; then
    cp -af /odm/lib/$NAME $MODPATH$MODSYSTEM/vendor/lib
  fi
  chcon $CON $MODPATH$MODSYSTEM/vendor/lib*/$NAME
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
  RDES=`realpath $DES`
  if [ -f $RDES ]; then
    if $NOMOUNT; then
      $NM del $RDES 2>/dev/null || true
      $NM add $RDES $FILE
    else
      umount $RDES
      mount -o bind $FILE $RDES
    fi
  fi
done
}
mount_my_product() {
DIR=$MODPATH/system/my_product
FILES=`find $DIR -type f -name $AUD`
for FILE in $FILES; do
  DES=/my_product`echo $FILE | sed "s|$DIR||g"`
  RDES=`realpath $DES`
  if [ -f $RDES ]; then
    if $NOMOUNT; then
      $NM del $RDES 2>/dev/null || true
      $NM add $RDES $FILE
    else
      umount $RDES
      mount -o bind $FILE $RDES
    fi
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











mount -o rw,remount /data
[ -z $MODPATH ] && MODPATH=${0%/*}
[ -z $MODID ] && MODID=`basename "$MODPATH"`

# log
exec 2>/data/media/0/$MODID\_uninstall.log
set -x

# run
. $MODPATH/function.sh

# cleaning
APPS="`ls $MODPATH/system/priv-app` `ls $MODPATH/system/app`"
for APP in $APPS; do
  rm -f `find /data/system/package_cache -type f -name *$APP*`
  rm -f `find /data/dalvik-cache /data/resource-cache -type f -name *$APP*.apk`
done
PKGS=`cat $MODPATH/package.txt`
for PKG in $PKGS; do
  rm -rf /data/user*/*/$PKG
done
remove_sepolicy_rule
rm -rf /data/waves
resetprop -p --delete persist.vendor.audio_fx.current
resetprop -p --delete persist.vendor.audio_fx.waves.maxxsense
resetprop -p --delete persist.vendor.audio_fx.waves.processing
resetprop -p --delete persist.vendor.audio_fx.waves.proc_twks
resetprop -p --delete persist.vendor.audio_fx.waves.systrace
resetprop -p --delete persist.vendor.audio_fx.force_waves_enabled











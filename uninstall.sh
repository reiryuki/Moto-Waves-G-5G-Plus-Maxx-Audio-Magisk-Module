mount -o rw,remount /data
if [ ! "$MODPATH" ]; then
  MODPATH=${0%/*}
fi
if [ ! "$MODID" ]; then
  MODID=`echo "$MODPATH" | sed 's|/data/adb/modules/||' | sed 's|/data/adb/modules_update/||'`
fi

# cleaning
APP="`ls $MODPATH/system/priv-app` `ls $MODPATH/system/app`"
for APPS in $APP; do
  rm -f `find /data/system/package_cache -type f -name *$APPS*`
  rm -f `find /data/dalvik-cache /data/resource-cache -type f -name *$APPS*.apk`
done
PKG=`cat $MODPATH/package.txt`
for PKGS in $PKG; do
  rm -rf /data/user*/*/$PKGS
done
rm -rf /data/waves
resetprop -p --delete persist.vendor.audio_fx.current
resetprop -p --delete persist.vendor.audio_fx.waves.maxxsense
resetprop -p --delete persist.vendor.audio_fx.waves.processing
resetprop -p --delete persist.vendor.audio_fx.waves.proc_twks
resetprop -p --delete persist.vendor.audio_fx.waves.systrace
resetprop -p --delete persist.vendor.audio_fx.force_waves_enabled



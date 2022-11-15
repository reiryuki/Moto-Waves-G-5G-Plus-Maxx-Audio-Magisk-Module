mount -o rw,remount /data
MODPATH=${0%/*}
MODID=`echo "$MODPATH" | sed 's|/data/adb/modules/||'`
APP="`ls $MODPATH/system/priv-app` `ls $MODPATH/system/app`"
PKG="com.motorola.motowaves
     com.waves.maxxservice
     com.motorola.motosignature.app"
for PKGS in $PKG; do
  rm -rf /data/user/*/$PKGS
done
for APPS in $APP; do
  rm -f `find /data/system/package_cache -type f -name *$APPS*`
  rm -f `find /data/dalvik-cache /data/resource-cache -type f -name *$APPS*.apk`
done
rm -rf /data/waves
resetprop -p --delete persist.vendor.audio_fx.current
resetprop -p --delete persist.vendor.audio_fx.waves.maxxsense
resetprop -p --delete persist.vendor.audio_fx.waves.processing
resetprop -p --delete persist.vendor.audio_fx.waves.proc_twks
resetprop -p --delete persist.vendor.audio_fx.waves.systrace
resetprop -p --delete persist.vendor.audio_fx.force_waves_enabled



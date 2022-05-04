MODPATH=${0%/*}
API=`getprop ro.build.version.sdk`
AML=/data/adb/modules/aml

# debug
exec 2>$MODPATH/debug.log
set -x

# properties
resetprop vendor.audio.feature.maxx_audio.enable false
resetprop -p --delete persist.vendor.audio_fx.current
resetprop -n persist.vendor.audio_fx.current waves
resetprop -p --delete persist.vendor.audio_fx.waves.maxxsense
resetprop -n persist.vendor.audio_fx.waves.maxxsense true
resetprop -p --delete persist.vendor.audio_fx.waves.processing
resetprop -n persist.vendor.audio_fx.waves.processing true
resetprop -p --delete persist.vendor.audio_fx.waves.proc_twks
resetprop -n persist.vendor.audio_fx.waves.proc_twks true
resetprop -p --delete persist.vendor.audio_fx.waves.systrace
resetprop -n persist.vendor.audio_fx.waves.systrace true
resetprop -p --delete persist.vendor.audio_fx.force_waves_enabled
resetprop -n persist.vendor.audio_fx.force_waves_enabled true

# restart
killall audioserver

# wait
sleep 20

# aml fix
DIR=$AML/system/vendor/odm/etc
if [ -d $DIR ] && [ ! -f $AML/disable ]; then
  chcon -R u:object_r:vendor_configs_file:s0 $DIR
fi

# mount
NAME="*audio*effects*.conf -o -name *audio*effects*.xml -o -name *policy*.conf -o -name *policy*.xml"
if [ ! -d $AML ] || [ -f $AML/disable ]; then
  DIR=$MODPATH/system/vendor
else
  DIR=$AML/system/vendor
fi
FILE=`find $DIR/etc -maxdepth 1 -type f -name $NAME`
if [ `realpath /odm/etc` == /odm/etc ] && [ "$FILE" ]; then
  for i in $FILE; do
    j="/odm$(echo $i | sed "s|$DIR||")"
    if [ -f $j ]; then
      umount $j
      mount -o bind $i $j
    fi
  done
fi
if [ -d /my_product/etc ] && [ "$FILE" ]; then
  for i in $FILE; do
    j="/my_product$(echo $i | sed "s|$DIR||")"
    if [ -f $j ]; then
      umount $j
      mount -o bind $i $j
    fi
  done
fi
if ( [ `realpath /odm/etc` == /odm/etc ] && [ "$FILE" ] )\
|| ( [ -d /my_product/etc ] && [ "$FILE" ] ); then
  killall audioserver
fi

# wait
sleep 40

# function
grant_permission() {
if [ "$API" -ge 31 ]; then
  pm grant $PKG android.permission.BLUETOOTH_CONNECT
fi
if [ "$API" -ge 30 ]; then
  appops set $PKG AUTO_REVOKE_PERMISSIONS_IF_UNUSED ignore
fi
}

# grant
PKG=com.waves.maxxservice
grant_permission

# grant
PKG=com.motorola.motowaves
grant_permission
appops set $PKG SYSTEM_ALERT_WINDOW allow



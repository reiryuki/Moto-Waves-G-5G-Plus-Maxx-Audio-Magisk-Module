mount -o rw,remount /data
[ ! "$MODPATH" ] && MODPATH=${0%/*}
[ ! "$MODID" ] && MODID=`basename "$MODPATH"`
UID=`id -u`

# log
exec 2>/data/media/"$UID"/$MODID\_uninstall.log
set -x

# run
. $MODPATH/function.sh

# cleaning
remove_cache
PKGS=`cat $MODPATH/package.txt`
for PKG in $PKGS; do
  rm -rf /data/user*/"$UID"/$PKG
done
remove_sepolicy_rule
rm -rf /data/waves
resetprop -p --delete persist.vendor.audio_fx.current
resetprop -p --delete persist.vendor.audio_fx.waves.maxxsense
resetprop -p --delete persist.vendor.audio_fx.waves.processing
resetprop -p --delete persist.vendor.audio_fx.waves.proc_twks
resetprop -p --delete persist.vendor.audio_fx.waves.systrace
resetprop -p --delete persist.vendor.audio_fx.force_waves_enabled











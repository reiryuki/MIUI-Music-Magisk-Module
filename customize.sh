# space
if [ "$BOOTMODE" == true ]; then
  ui_print " "
fi

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
SYSTEM_EXT=`realpath $MIRROR/system/system_ext`
ODM=`realpath /odm`
MY_PRODUCT=`realpath /my_product`

# optionals
OPTIONALS=/sdcard/optionals.prop

# info
MODVER=`grep_prop version $MODPATH/module.prop`
MODVERCODE=`grep_prop versionCode $MODPATH/module.prop`
ui_print " ID=$MODID"
ui_print " Version=$MODVER"
ui_print " VersionCode=$MODVERCODE"
ui_print " MagiskVersion=$MAGISK_VER"
ui_print " MagiskVersionCode=$MAGISK_VER_CODE"
ui_print " "

# sdk
NUM=21
if [ "$API" -lt $NUM ]; then
  ui_print "! Unsupported SDK $API."
  ui_print "  You have to upgrade your Android version"
  ui_print "  at least SDK API $NUM to use this module."
  abort
else
  ui_print "- SDK $API"
  ui_print " "
fi

# mount
if [ "$BOOTMODE" != true ]; then
  mount -o rw -t auto /dev/block/bootdevice/by-name/cust /vendor
  mount -o rw -t auto /dev/block/bootdevice/by-name/vendor /vendor
  mount -o rw -t auto /dev/block/bootdevice/by-name/persist /persist
  mount -o rw -t auto /dev/block/bootdevice/by-name/metadata /metadata
fi

# sepolicy.rule
FILE=$MODPATH/sepolicy.sh
DES=$MODPATH/sepolicy.rule
if [ -f $FILE ] && [ "`grep_prop sepolicy.sh $OPTIONALS`" != 1 ]; then
  mv -f $FILE $DES
  sed -i 's/magiskpolicy --live "//g' $DES
  sed -i 's/"//g' $DES
fi

# miuicore
if [ ! -d /data/adb/modules_update/MiuiCore ] && [ ! -d /data/adb/modules/MiuiCore ]; then
  ui_print "! Miui Core Magisk Module is not installed."
  ui_print "  Please read github installation guide!"
  abort
else
  rm -f /data/adb/modules/MiuiCore/remove
  rm -f /data/adb/modules/MiuiCore/disable
fi

# cleaning
ui_print "- Cleaning..."
PKG=com.miui.player
if [ "$BOOTMODE" == true ]; then
  for PKGS in $PKG; do
    RES=`pm uninstall $PKGS`
  done
fi
rm -rf /metadata/magisk/$MODID
rm -rf /mnt/vendor/persist/magisk/$MODID
rm -rf /persist/magisk/$MODID
rm -rf /data/unencrypted/magisk/$MODID
rm -rf /cache/magisk/$MODID
ui_print " "

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
check_library() {
NAME=miui-stat.jar
if ! pm list libraries | grep -Eq $NAME; then
  echo 'rm -rf /data/user/*/com.android.vending/*' > $MODPATH/cleaner.sh
  ui_print "- Play Store data will be cleared automatically on"
  ui_print "  next reboot for app updates"
  ui_print " "
fi
}





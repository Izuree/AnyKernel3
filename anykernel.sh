# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers
#
# E404R kernel custom installer by 113
# What are you looking for ?

properties() { '
kernel.string=E404R Kernel by Project 113
do.modules=0
do.systemless=1
'; }

devicecheck() {
  [ "$(file_getprop anykernel.sh devicecheck)" == 1 ] || return 1;
  local device devicename match product testname vendordevice vendorproduct;
  device=$(getprop ro.product.device 2>/dev/null);
  product=$(getprop ro.build.product 2>/dev/null);
  vendordevice=$(getprop ro.product.vendor.device 2>/dev/null);
  vendorproduct=$(getprop ro.vendor.product.device 2>/dev/null);
  for testname in $(grep 'devicename' anykernel.sh | cut -d= -f2-); do
    for devicename in $device $product $vendordevice $vendorproduct; do
      if [ "$devicename" == *"$testname"* ]; then
        match=1;
        break;
      fi;
    done;
  done;
  if [ ! "$match" ]; then
    abort " " "Unsupported device. Aborting...";
  fi;
}

manual_configuration(){
  sleep 0.5;
  ui_print " " " - ROM or DTBO Type :";
  ui_print "  (Vol +)  AOSP/CLO ";
  ui_print "  (Vol -)  MIUI/HyperOS ";
  while true; do
  ev=$(getevent -lt 2>/dev/null | grep -m1 "KEY_VOLUME.*DOWN")
  case $ev in
    *KEY_VOLUMEUP*)
      if [[ "$oplus" == "0" ]]; then
        rom="rom_aosp"
      else
        rom="rom_port";
      fi
      dtbo="dtbo_def";
      break;
      ;;
    *KEY_VOLUMEDOWN*)
      if [[ "$oplus" == "0" ]]; then
        rom="rom_oem"
      else
        rom="rom_port";
      fi
      dtbo="dtbo_oem";
      break;
      ;;
  esac
  done
  sleep 0.5;

  ui_print " " " - KernelSU Root :";
  ui_print "  (Vol +)  Yes ";
  ui_print "  (Vol -)  No/Default ";
  while true; do
  ev=$(getevent -lt 2>/dev/null | grep -m1 "KEY_VOLUME.*DOWN")
  case $ev in
    *KEY_VOLUMEUP*)
      sleep 0.5;
        ui_print " " " - SUSFS4KSU :";
        ui_print "  (Vol +)  Yes ";
        ui_print "  (Vol -)  No/Default ";
        while true; do
        ev=$(getevent -lt 2>/dev/null | grep -m1 "KEY_VOLUME.*DOWN")
        case $ev in
          *KEY_VOLUMEUP*)
            rm -f *-NOSUSFS-Image;
            break;
            ;;
          *KEY_VOLUMEDOWN*)
            rm -f *-SUSFS-Image;
            break;
            ;;
        esac
        done
      root="root_ksu";
      break;
      ;;
    *KEY_VOLUMEDOWN*)
      root="root_noksu";
      break;
      ;;
  esac
  done
  sleep 0.5;

  if [[ "$devicename" == "alioth" ]]; then
    ui_print " " " - Battery Profile :";
    ui_print "  (Vol +)  5000 mAh (Vol +) ";
    ui_print "  (Vol +)  Default (Vol -) ";
    while true; do
    ev=$(getevent -lt 2>/dev/null | grep -m1 "KEY_VOLUME.*DOWN")
    case $ev in
      *KEY_VOLUMEUP*)
        ui_print "--> Skipping KernelSU, Configuring...";
        batt="batt_5k";
        break;
        ;;
      *KEY_VOLUMEDOWN*)
        batt="batt_def";
        break;
        ;;
    esac
    done
    sleep 0.5;
  else
    batt="batt_def";
  fi
  sleep 0.5;
  ui_print " " " Manual Configuration Done ! ";
}

auto_configuration(){
  ui_print " " " Running Auto Configuration... ";
  sleep 0.5;
  miprops="$(file_getprop /vendor/build.prop "ro.vendor.miui.build.region")";
  if [[ "$oplus" == "1" ]]; then
    ui_print "--> OPLUS Port ROM detected, Configuring...";
    rom="rom_port";
    dtbo="dtbo_def";
  elif [[ -z "$miprops" ]]; then
    miprops="$(file_getprop /product/etc/build.prop "ro.miui.build.region")"
    case "$miprops" in
      cn|in|ru|id|eu|tr|tw|gb|global|mx|jp|kr|lm|cl|mi)
          ui_print "--> Miui/HyperOS ROM detected, Configuring...";
          rom="rom_oem";
          dtbo=dtbo_oem;
        ;;
    esac
  else
    ui_print "--> AOSP/CLO ROM detected, Configuring...";
    rom="rom_aosp";
    dtbo=dtbo_def;
  fi

  sleep 0.5;
    case "$ZIPFILE" in
      *ksu*|*KSU*|*Ksu*)
        ui_print "--> KernelSU detected, Configuring...";
        root="root_ksu";
      ;;
      *)
        if [[ -d /data/adb/ksu ]] && [[ -f /data/adb/ksud ]]; then
          ui_print "--> KernelSU detected, Configuring...";
          root="root_ksu";
        else
          ui_print "--> Skip KernelSU, Configuring...";
          root="root_noksu";
        fi
        if [[ -d /data/adb/susfs4ksu ]] && [[ -d /data/adb/ksu/susfs4ksu ]] && [[ -d /data/adb/modules/susfs4ksu ]]; then
          ui_print "--> SUSFS4KSU detected, Configuring...";
          rm -f *-NOSUSFS-Image;
        else
          ui_print "--> Skip SUSFS4KSU, Configuring...";
          rm -f *-SUSFS-Image;
        fi
      ;;
    esac

    sleep 0.5;
    case "$ZIPFILE" in
      *5K*|*5k*)
        if [[ "$is_alioth" == "1" ]]; then
          ui_print "--> Alioth 5000mAh Battery Profile, Configuring...";
          batt="batt_5k";
        else
          ui_print "--> Default Battery Profile, Configuring...";
          batt="batt_def";
        fi
      ;;
      *)
        batt="batt_def";
      ;;
    esac
    sleep 0.5;
    ui_print " " " Auto Configuration Done ! ";
}

#
# Start installation
# 

# Variables
devicename=lmi;
case "$devicename" in
  munch|alioth|pipa)
    is_slot_device=1;
  ;;
  apollo|lmi)
    is_slot_device=0;
  ;;
esac
block=/dev/block/bootdevice/by-name/boot;
ramdisk_compression=auto
patch_vbmeta_flag=auto

# Import AnyKernel core functions
. tools/ak3-core.sh

#
# Main Installation Logic
#

if [[ -f /vendor/OemPorts10T.prop ]] ||
  [[ -f /vendor/etc/init/OemPorts10T.rc ]]; then
  ui_print " ! Detected OPLUS Port ROM by Dandaa ! ";
  ui_print " ! Manual Configuration is Recommended !";
  ui_print " Note : Port ROM Usually Need KernelSU Root !";
  oplus=1;
else
  oplus=0;
  devicecheck;
fi
  
if [[ "$SIDELOAD" == "1" ]]; then
  ui_print " " " ! Sideloading Detected, Overriding to Manual Configuration !";
  manual_configuration;
else
  ui_print " " "Select Kernel Configuration :";
  ui_print "  (Vol +) Manual Configuration ";
  ui_print "  (Vol -) Auto Configuration ";
  while true; do
  ev=$(getevent -lt 2>/dev/null | grep -m1 "KEY_VOLUME.*DOWN")
    case $ev in
        *KEY_VOLUMEUP*)
          manual_configuration;
          break;
          ;;
        *KEY_VOLUMEDOWN*)
          auto_configuration;
          break;
          ;;
    esac
  done
fi
sleep 0.5;
ui_print " Installing... ";

mv *-Image $home/Image;
mv *-dtb $home/dtb;
mv *-dtbo.img $home/dtbo.img;

patch_cmdline "e404_args" "e404_args="$root,$rom,$dtbo,$batt""

if [ ! -f /vendor/etc/task_profiles.json ]; then
	ui_print " " " Note : Uclamp Task Profile Not Found ! " " ";
fi

dump_boot;
write_boot;

if [ $is_slot_device == 1 ]; then 
  block=/dev/block/bootdevice/by-name/vendor_boot;
  ramdisk_compression=auto;
  patch_vbmeta_flag=auto;
  reset_ak;
  dump_boot;
  write_boot;
fi

ui_print " " "--- Installation Done ! --- ";

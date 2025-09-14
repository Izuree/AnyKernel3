# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

# E404R kernel custom installer by 113

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
  ui_print " " " - ROM Type :";
  ui_print "  (Vol +)  AOSP/CLO/OPLUS ";
  ui_print "  (Vol -)  MIUI/HyperOS ";
  while true; do
  ev=$(getevent -lt 2>/dev/null | grep -m1 "KEY_VOLUME.*DOWN")
  case $ev in
    *KEY_VOLUMEUP*)
      [[ "$oplus" != "1" ]] && rom="aosp" || rom="port";
      dtbo="dtbo_def";
      break;
      ;;
    *KEY_VOLUMEDOWN*)
      rom="miui"
      dtbo="dtbo_oem";
      break;
      ;;
  esac
  done
  sleep 1;

  ui_print " " " - KernelSU Root :";
  ui_print "  (Vol +)  Yes ";
  ui_print "  (Vol -)  No/Default ";
  while true; do
  ev=$(getevent -lt 2>/dev/null | grep -m1 "KEY_VOLUME.*DOWN")
  case $ev in
    *KEY_VOLUMEUP*)
      root="root_ksu";
      break;
      ;;
    *KEY_VOLUMEDOWN*)
      root="root_noksu";
      break;
      ;;
  esac
  done
  sleep 1;

  ui_print " " " - DTB CPU Frequency : ";
  ui_print "  (Vol +)  EFFCPU ";
  ui_print "  (Vol -)  Default ";
  while true; do
  ev=$(getevent -lt 2>/dev/null | grep -m1 "KEY_VOLUME.*DOWN")
  case $ev in
    *KEY_VOLUMEUP*)
      dtb="dtb_effcpu";
      break;
      ;;
    *KEY_VOLUMEDOWN*)
      dtb="dtb_def";
      break;
      ;;
  esac
  done
  sleep 1;

  if [[ "$devicename" == "alioth" ]]; then
    ui_print " " " - Battery Profile :";
    ui_print "  (Vol +)  5000 mAh (Vol +) ";
    ui_print "  (Vol +)  Default (Vol -) ";
    while true; do
    ev=$(getevent -lt 2>/dev/null | grep -m1 "KEY_VOLUME.*DOWN")
    case $ev in
      *KEY_VOLUMEUP*)
        batt="batt_5k";
        break;
        ;;
      *KEY_VOLUMEDOWN*)
        batt="batt_def";
        break;
        ;;
    esac
    done
    sleep 1;
  else
    batt="batt_def";
  fi
  ui_print " " " Manual Configuration Done ! ";
}

auto_configuration(){
  sleep 0.5;
  ui_print " " " Running Auto Configuration... ";
  miprops="$(file_getprop /vendor/build.prop "ro.vendor.miui.build.region")";
  if [[ "$oplus" == "1" ]]; then
    ui_print "--> OPLUS Port ROM detected, Configuring...";
    rom="port";
    dtbo="dtbo_def";
  elif [[ -z "$miprops" ]]; then
    miprops="$(file_getprop /product/etc/build.prop "ro.miui.build.region")"
    case "$miprops" in
      cn|in|ru|id|eu|tr|tw|gb|global|mx|jp|kr|lm|cl|mi)
          ui_print "--> Miui/HyperOS ROM detected, Configuring...";
          rom="miui";
          dtbo=dtbo_oem;
        ;;
    esac
  else
    ui_print "--> AOSP/CLO ROM detected, Configuring...";
    rom="aosp";
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
          root="root_noksu";
        fi
      ;;
    esac
    case "$ZIPFILE" in
      *effcpu*|*EFFCPU*|*Effcpu*)
        ui_print "--> Configuring EFFCPUFreq DTB...";
        dtb="dtb_effcpu";
      ;;
      *)
        dtb="dtb_def";
      ;;
    esac
    case "$ZIPFILE" in
      *5K*|*5k*)
        if [[ "$is_alioth" == "1" ]]; then
          ui_print "--> Configuring Alioth 5000mAh Battery Profile...";
          batt="batt_5k";
        else
          batt="batt_def";
        fi
      ;;
      *)
        batt="batt_def";
      ;;
    esac
    ui_print " " " Auto Configuration Done ! ";
}

#
# Start installation
# 

devicename=apollo;
e404_args="";
block=/dev/block/bootdevice/by-name/boot;
ramdisk_compression=auto;

case "$devicename" in
  munch|alioth)
    is_slot_device=1;
  ;;
  apollo|*mi)
    is_slot_device=0;
  ;;
esac

. tools/ak3-core.sh;
set_perm_recursive 0 0 750 750 $ramdisk/*;

if [[ "$(getprop | grep oemports10t)" == *oemports10t* ]] ||
  [[ -f /vendor/OemPorts10T.prop ]] ||
  [[ -f /vendor/etc/init/OemPorts10T.rc ]]; then
  ui_print " ! Detected OPLUS Port ROM by Dandaa ! ";
  ui_print " Note : Port ROM Usually Need KernelSU Root !";
  oplus=1;
else
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

mv *-Image* $home/Image;
if [[ "$batt" == "batt_5k" ]]; then
  mv *-dtbo-5k.img $home/dtbo.img;
else
  mv *-dtbo.img $home/dtbo.img;
fi
mv *-dtb $home/dtb;

if [ ! -f /vendor/etc/task_profiles.json ]; then
	ui_print " " " Note : Uclamp Task Profile Not Found ! " " ";
fi

dump_boot;

patch_cmdline "e404_args" "e404_args="$root,$rom,$dtbo,$dtb,$batt""
# ui_print " E404R Cmdline Args : e404_args="$root,$rom,$dtbo,$dtb,$batt"";

if [ -d $ramdisk/overlay ]; then
  rm -rf $ramdisk/overlay;
fi

write_boot;

if [ $is_slot_device == 1 ]; then 
  block=/dev/block/bootdevice/by-name/vendor_boot;
  ramdisk_compression=auto;
  patch_vbmeta_flag=auto;
  reset_ak;
  dump_boot;
  write_boot;
fi
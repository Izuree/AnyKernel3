# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

# E404R kernel custom installer by 113

properties() { '
kernel.string=E404R Kernel by Project 113
do.modules=0
do.systemless=1
'; }

devicecheck=1;
romcheck="$(file_getprop /vendor/build.prop "ro.vendor.miui.build.region")"
devicename=munch;

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

ui_print " ";

manual_install(){
  ui_print " ";
  ui_print "- KernelSU Root : Yes (Vol +) || No/Default (Vol -)";
  case "$ZIPFILE" in
    *port*|*PORT*|*Port*)
    ui_print " Note : Port ROM Usually Need KernelSU Root !";
  ;;
  esac
  while true; do
  ev=$(getevent -lt 2>/dev/null | grep -m1 "KEY_VOLUME.*DOWN")
  case $ev in
    *KEY_VOLUMEUP*)
      root="root_ksu";
      ui_print " > Selected KernelSU Root.";
      break;
      ;;
    *KEY_VOLUMEDOWN*)
      root="root_noksu";
      ui_print " > Selected Default Root.";
      break;
      ;;
  esac
  done
  sleep 1;
  ui_print " ";

  ui_print "- DTB : EFFCPU (Vol +) || Default (Vol -)";
  while true; do
  ev=$(getevent -lt 2>/dev/null | grep -m1 "KEY_VOLUME.*DOWN")
  case $ev in
    *KEY_VOLUMEUP*)
      dtb="dtb_effcpu";
      ui_print " > Selected EFFCPU DTB.";
      break;
      ;;
    *KEY_VOLUMEDOWN*)
      dtb="dtb_def";
      ui_print " > Selected Default DTB.";
      break;
      ;;
  esac
  done
  sleep 1;
  ui_print " ";

  if [[ "$devicename" == "alioth" ]]; then
    ui_print "- Batt Profile: 5K mAh (Vol +) || Default (Vol -)";
    while true; do
    ev=$(getevent -lt 2>/dev/null | grep -m1 "KEY_VOLUME.*DOWN")
    case $ev in
      *KEY_VOLUMEUP*)
        batt="batt_5k";
        ui_print " > Selected 5K mAh Batt Profile.";
        break;
        ;;
      *KEY_VOLUMEDOWN*)
        batt="batt_def";
        ui_print " > Selected Default Batt Profile.";
        break;
        ;;
    esac
    done
    sleep 1;
    ui_print " ";
  else
    batt="batt_def";
  fi
}

auto_install(){
  ui_print " ";
    case "$ZIPFILE" in
      *ksu*|*KSU*|*Ksu*|*port*|*PORT*|*Port*)
        ui_print "--> Patching KernelSU.";
        root="root_ksu";
      ;;
      *)
        root="root_noksu";
      ;;
    esac
    case "$ZIPFILE" in
      *effcpu*|*EFFCPU*|*Effcpu*)
        ui_print "--> Patching EFFCPU DTB.";
        dtb="dtb_effcpu";
      ;;
      *)
        dtb="dtb_def";
      ;;
    esac
    case "$ZIPFILE" in
      *5K*|*5k*)
        if [[ "$is_alioth" == "1" ]]; then
          ui_print "--> Patching 5000mAh Battery Profile.";
          batt="batt_5k";
        else
          batt="batt_def";
        fi
      ;;
      *)
        batt="batt_def";
      ;;
    esac
}

if [[ "$SIDELOAD" == "1" ]]; then
  ui_print " ! Sideloading detected, using manual install !";
  manual_install;
else
  ui_print " ! Select Installation Method :";
  ui_print " - Manual Install (Vol +) || Auto Install (Vol -) !";
  while true; do
  ev=$(getevent -lt 2>/dev/null | grep -m1 "KEY_VOLUME.*DOWN")
    case $ev in
        *KEY_VOLUMEUP*)
          ui_print "  > Manual Install Selected.";
          sleep 1;
          manual_install;
          break;
          ;;
        *KEY_VOLUMEDOWN*)
          ui_print "  > Auto Install Selected.";
          sleep 1;
          auto_install;
          break;
          ;;
      esac
  done
fi

if [[ "$devicecheck" == "0" ]]; then
    rom=port
    dtbo=dtbo_oem;
else
    rom=aosp
    dtbo=dtbo_def;
fi

if [[ -z "$romcheck" ]]; then
  romcheck="$(file_getprop /product/etc/build.prop "ro.miui.build.region")"
fi

case "$romcheck" in
  cn|in|ru|id|eu|tr|tw|gb|global|mx|jp|kr|lm|cl|mi)
      ui_print " "
      ui_print " --> Patching MIUI/HyperOS DTBO...";
      dtbo=dtbo_oem;
      rom="miui";
    ;;
esac

mv *-Image* $home/Image;
if [[ "$batt" == "batt_5k" ]]; then
  mv *-dtbo-5k.img $home/dtbo.img;
else
  mv *-dtbo.img $home/dtbo.img;
fi
mv *-dtb $home/dtb;

if [ ! -f /vendor/etc/task_profiles.json ] && [ ! -f /system/vendor/etc/task_profiles.json ]; then
  ui_print " ";
	ui_print " ! Your rom does not have Uclamp task profiles !";
	ui_print " ! Please install Uclamp task profiles module !";
  ui_print " ! Ignore this if you already have !";
fi

dump_boot;

patch_cmdline "e404_args" "e404_args="$root,$rom,$dtbo,$dtb,$batt""

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
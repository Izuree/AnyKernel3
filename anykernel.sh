# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

# E404 kernel custom installer by 113

properties() { '
kernel.string=E404 Kernel by Project 113
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=munch
device.name2=munchin
supported.versions=
'; }

is_apollo=0;
is_munch=1;
is_alioth=0;

e404_args="";

block=/dev/block/bootdevice/by-name/boot;
ramdisk_compression=auto;

if [ $is_apollo == "1" ]; then
  is_slot_device=0;
elif [ $is_munch == "1" ]; then
  is_slot_device=1;
elif [ $is_alioth == "1" ]; then
  is_slot_device=1;
fi;

. tools/ak3-core.sh;
set_perm_recursive 0 0 750 750 $ramdisk/*;

ui_print " ";

manual_install(){
  ui_print " ";
  ui_print "- KernelSU Root : Yes (Vol +) || No/Default (Vol -)";
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
  sleep 2;
  ui_print " ";

  ui_print "- DTBO : Miui/HyperOS (Vol +) || AOSP/CLO/Default (Vol -)";
  while true; do
  ev=$(getevent -lt 2>/dev/null | grep -m1 "KEY_VOLUME.*DOWN")
  case $ev in
    *KEY_VOLUMEUP*)
      dtbo="dtbo_oem";
      ir="ir_blaster_def";
      ui_print " > Selected Miui/HyperOS DTBO.";
      break;
      ;;
    *KEY_VOLUMEDOWN*)
      dtbo="dtbo_def";
      ui_print " > Selected AOSP/CLO/Default DTBO.";
      break;
      ;;
  esac
  done
  sleep 2;
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
  sleep 2;
  ui_print " ";

  ui_print "- IR Blaster : LOS Based (Vol +) || Default (Vol -)";
  while true; do
  ev=$(getevent -lt 2>/dev/null | grep -m1 "KEY_VOLUME.*DOWN")
  case $ev in
    *KEY_VOLUMEUP*)
      ir="ir_blaster_mi";
      ui_print " > Selected LOS Based IR.";
      break;
      ;;
    *KEY_VOLUMEDOWN*)
      ir="ir_blaster_def";
      ui_print " > Selected Default IR.";
      break;
      ;;
  esac
  done
  sleep 2;
  ui_print " ";

  if [[ "$is_alioth" == "1" ]]; then
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
    sleep 2;
    ui_print " ";
  else
    batt="batt_def";
  fi
}

auto_install(){
  ui_print " ";
    case "$ZIPFILE" in
      *-ksu*|*-KSU*|*-Ksu*)
        ui_print "--> Patching KernelSU.";
        root="root_ksu";
      ;;
      *)
        root="root_noksu";
      ;;
    esac
    sleep 1;
    case "$ZIPFILE" in
      *-miui*|*-MIUI*|*-Miui|*-hyper*|*-HYPER*|*-Hyper*)
        ui_print "--> Patching MIUI/HyperOS DTBO.";
        dtbo="dtbo_oem";
        ir="ir_blaster_def";
      ;;
      *aosp*|*AOSP*|*Aosp|*clo*|*CLO*|*Clo*|*)
        dtbo="dtbo_def";
      ;;
    esac
    sleep 1;
    case "$ZIPFILE" in
      *-effcpu*|*-EFFCPU*|*-Effcpu*)
        ui_print "--> Patching EFFCPU DTB.";
        dtb="dtb_effcpu";
      ;;
      *)
        dtb="dtb_def";
      ;;
    esac
    sleep 1;
    case "$ZIPFILE" in
      *-ir*|*-IR*|*-Ir*)
        ui_print "--> Patching IR Blaster.";
        ir="ir_blaster_mi";
      ;;
      *)
        ir="ir_blaster_def";
      ;;
    esac
    sleep 1;
    case "$ZIPFILE" in
      *-5K*|*-5k*)
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
    sleep 1;
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
          sleep 2;
          manual_install;
          break;
          ;;
        *KEY_VOLUMEDOWN*)
          ui_print "  > Auto Install Selected.";
          sleep 2;
          auto_install;
          break;
          ;;
      esac
  done
fi

if [ ! -f /vendor/etc/task_profiles.json ] && [ ! -f /system/vendor/etc/task_profiles.json ]; then
  ui_print " ";
	ui_print " ! Your rom does not have Uclamp task profiles !";
	ui_print " ! Please install Uclamp task profiles module !";
  ui_print " ! Ignore this if you already have !";
fi;

mv *-Image.gz $home/Image.gz;
if [[ "$batt" == "batt_5k" ]]; then
  mv *-dtbo-5k.img $home/dtbo.img;
else
  mv *-dtbo.img $home/dtbo.img;
fi;
mv *-dtb $home/dtb;

dump_boot;

#Remove older patches
patch_cmdline "e404_kernelsu" ""
patch_cmdline "e404_rom_type" ""
patch_cmdline "e404_effcpu" ""
patch_cmdline "e404_ir_type" ""
patch_cmdline "e404_panel_height" ""
patch_cmdline "e404_panel_width" ""
patch_cmdline "e404_args" ""

# Patch in one line
patch_cmdline "e404_args" "e404_args="$root,$dtbo,$dtb,$ir,$batt""

if [ -d $ramdisk/overlay ]; then
  rm -rf $ramdisk/overlay;
fi;

write_boot;

if [ $is_apollo == "0" ]; then 
  block=/dev/block/bootdevice/by-name/vendor_boot;
  is_slot_device=1;
  ramdisk_compression=auto;
  patch_vbmeta_flag=auto;
  reset_ak;
  dump_boot;
  write_boot;
fi;
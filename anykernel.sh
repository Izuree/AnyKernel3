# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers


# E404 kernel custom installer by 113

# What'supp kangers ? looking for what i am cooking ?
# Anything you do or if you are taking a peek and going to use it
# PUT A FUCKING PROPER CREDITS !!!

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

block=/dev/block/bootdevice/by-name/boot;
ramdisk_compression=auto;

if [ $is_apollo == "1" ]; then
  is_slot_device=0;
elif [ $is_munch == "1" ]; then
  is_slot_device=1;
elif [ $is_alioth == "1" ]; then
  is_slot_device=1;
fi;

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;

## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
set_perm_recursive 0 0 750 750 $ramdisk/*;

ui_print " ";
ui_print "-> Kernel Naming :";
ui_print "--> "$ZIPFILE" ";
ui_print " ";

case "$ZIPFILE" in
  *noksu*|*NOKSU*)
    ui_print "-> Non-KernelSU variant selected,";
    E404_KSU=0;
  ;;
  *ksu*|*KSU*)
    ui_print "-> KernelSU variant selected,";
    E404_KSU=1;
  ;;
  *)
    ui_print "-> KernelSU is not specified !!!";
    E404_KSU=0;
  ;;
esac
ui_print "--> Patching KernelSU cmdline...";
mv *-Image $home/Image;
rm *-Image;
ui_print " ";

case "$ZIPFILE" in
  *miui*|*MIUI*|*hyper*|*HYPER*)
    ui_print "-> MIUI/HyperOS variant selected,";
    ui_print "--> Patching MIUI/HyperOS kernel cmdline...";
    E404_ROM_TYPE=2;
  ;;
  *aosp*|*AOSP*|*clo*|*CLO*)
    ui_print "-> AOSP/CLO variant selected,";
    ui_print "--> Patching AOSP/CLO kernel cmdline... ";
    E404_ROM_TYPE=1;
  ;;
  *)
    ui_print "-> ROM is not specified !!!";
    ui_print "--> Patching default kernel cmdline... ";
    E404_ROM_TYPE=0;
  ;;
esac
ui_print " ";

case "$ZIPFILE" in
  *effcpu*|*EFFCPU*)
    ui_print "-> Efficient CPUFreq variant selected,";
    ui_print "--> Patching efficient CPUFreq cmdline...";
    E404_EFFCPU=1;
  ;;
  *)
    ui_print "-> Normal CPUFreq variant selected,";
    ui_print "--> Patching normal CPUFreq cmdline...";
    E404_EFFCPU=0;
  ;;
esac

if [ ! -f /vendor/etc/task_profiles.json ] && [ ! -f /system/vendor/etc/task_profiles.json ]; then
  ui_print " ";
	ui_print "-> Your rom does not have Uclamp task profiles !";
	ui_print "-> Please install Uclamp task profiles module !";
  ui_print "--> Ignore this if you already have.";
fi;

mv *-dtbo.img $home/dtbo.img;
mv *-dtb $home/dtb;

## AnyKernel install
dump_boot;

# Begin Ramdisk Changes
if [ "$E404_KSU" == "1" ]; then
  patch_cmdline "e404_kernelsu" "e404_kernelsu=1";
else
  patch_cmdline "e404_kernelsu" "e404_kernelsu=0";
fi

if [ "$E404_ROM_TYPE" == "2" ]; then
  patch_cmdline "e404_rom_type" "e404_rom_type=2";
elif [ "$E404_ROM_TYPE" == "1" ]; then
  patch_cmdline "e404_rom_type" "e404_rom_type=1";
else
  patch_cmdline "e404_rom_type" "e404_rom_type=0";
fi

if [ "$E404_EFFCPU" == "1" ]; then
  patch_cmdline "e404_effcpu" "e404_effcpu=1";
else
  patch_cmdline "e404_effcpu" "e404_effcpu=0";
fi

# migrate from /overlay to /overlay.d to enable SAR Magisk
if [ -d $ramdisk/overlay ]; then
  rm -rf $ramdisk/overlay;
fi;

write_boot;
## end install

if [ $is_apollo == "0" ]; then 
  ## vendor_boot shell variables
  block=/dev/block/bootdevice/by-name/vendor_boot;
  is_slot_device=1;
  ramdisk_compression=auto;
  patch_vbmeta_flag=auto;

  # reset for vendor_boot patching
  reset_ak;

  # vendor_boot install
  dump_boot;

  write_boot;
  ## end vendor_boot install
fi;
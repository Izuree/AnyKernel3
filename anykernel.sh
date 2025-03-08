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
ui_print "Kernel Naming :";
ui_print "--> "$ZIPFILE" ";
ui_print " ";

case "$ZIPFILE" in
  *miui*|*MIUI*)
    ui_print "MIUI/HyperOS DTBO variant detected,";
    ui_print "--> Using MIUI/HyperOS DTBO... ";
    mv *-miui-dtbo.img $home/dtbo.img;
    rm *-normal-dtbo.img;
  ;;
  *aosp*|*AOSP*)
    ui_print "Normal DTBO variant detected,";
    ui_print "--> Using Normal DTBO... ";
    mv *-normal-dtbo.img $home/dtbo.img;
    rm *-miui-dtbo.img;
  ;;
  *)
    ui_print "DTBO is not specified !!!";
    ui_print "--> Using Normal DTBO... ";
    mv *-normal-dtbo.img $home/dtbo.img;
    rm *-miui-dtbo.img;
  ;;
esac
ui_print " ";

case "$ZIPFILE" in
  *noksu*|*NOKSU*)
    ui_print "Non-KernelSU variant detected,";
    ui_print "--> Using Non-KernelSU Kernel Image...";
    mv *-noksu-Image $home/Image;
    rm *-ksu-Image;
  ;;
  *ksu*|*KSU*)
    ui_print "KernelSU variant detected,";
    ui_print "--> Using KernelSU Kernel Image...";
    mv *-ksu-Image $home/Image;
    rm *-noksu-Image;
  ;;
  *)
    ui_print "KernelSU is not specified !!!";
    ui_print "--> Using Non-KernelSU Kernel Image...";
    mv *-noksu-Image $home/Image;
    rm *-ksu-Image;
  ;;
esac
ui_print " ";

case "$ZIPFILE" in
  *effcpu*|*EFFCPU*)
    ui_print "Efficient CPUFreq variant detected,";
    ui_print "--> Using Efficient CPUFreq DTB...";
    mv *-effcpu-dtb $home/dtb;
    rm *-normal-dtb;
  ;;
  *)
    ui_print "Normal CPUFreq variant detected,";
    ui_print "--> Using Normal CPUFreq DTB...";
    mv *-normal-dtb $home/dtb;
    rm *-effcpu-dtb;
  ;;
esac

if [ ! -f /vendor/etc/task_profiles.json ]; then
  ui_print " ";
	ui_print "Your rom does not have Uclamp task profiles,";
	ui_print "Please install Uclamp task profiles module !";
  ui_print "--> Ignore this if you already have.";
fi;

## AnyKernel install
dump_boot;

# Begin Ramdisk Changes

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
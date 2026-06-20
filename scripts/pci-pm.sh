#!/usr/bin/env bash
# PCI runtime PM, USB autosuspend, and audio codec PM
# Supplements [audio]/[usb] TuneD plugins with direct sysfs writes so that
# already-connected devices and AMD SOF audio codecs are covered.
case "$1" in
  start)
    for f in /sys/bus/pci/devices/*/power/control; do
      echo auto > "$f" 2>/dev/null
    done
    for f in /sys/bus/usb/devices/*/power/control; do
      echo auto > "$f" 2>/dev/null
    done
    echo 1 > /sys/module/snd_hda_intel/parameters/power_save 2>/dev/null
    echo Y > /sys/module/snd_hda_intel/parameters/power_save_controller 2>/dev/null
    ;;
  stop)
    for f in /sys/bus/pci/devices/*/power/control; do
      echo on > "$f" 2>/dev/null
    done
    for f in /sys/bus/usb/devices/*/power/control; do
      echo on > "$f" 2>/dev/null
    done
    echo 0 > /sys/module/snd_hda_intel/parameters/power_save 2>/dev/null
    ;;
esac

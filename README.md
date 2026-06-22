# Moto Waves G 5G Plus Magisk Module

## DISCLAIMER
- Motorola and Waves apps and blobs are owned by Motorola™ and Waves™.
- The MIT license specified here is for the Magisk Module only, not for Motorola and Waves apps and blobs.

## Descriptions
- Equalizer sound effect ported from Motorola G 5G Plus (nairo) and integrated as a Magisk Module for all supported and rooted devices with Magisk
- Global type sound effect

## Sources
- https://dumps.tadiphone.dev/dumps/motorola/nairo msi-user-11-RPNS31.Q4U-39-27-9-2-8-cd477-release-keys
- system_10: https://dumps.tadiphone.dev/dumps/motorola/nairo msi-user-10-QP1A.191005.002-2a371-release-keys
- MotoWaves.apk system_10: https://play.google.com/store/apps/details?id=com.motorola.motowaves
- system_nio: https://dumps.tadiphone.dev/dumps/motorola/nio msi_prc-user-11-RRN31.Q3-1-11-1-919e2-release-keys
- system_pstar: https://dumps.tadiphone.dev/dumps/motorola/pstar msi-user-11-RRAS31.Q3-19-86-4-01582-release-keys
- system_racer: https://dumps.tadiphone.dev/dumps/motorola/racer msi-user-11-RPD31.Q4U-39-26-4-3c874-release-keys
- libmagiskpolicy.so: Magisk (stable) 30.7 (30700)

## Changelog

v6.19
- Support NoMount metamodule
- Update libmagiskpolicy.so from Magisk (stable) 30.7 (30700)
- Resets module folders/files permissions at post-fs-data
- Move _uninstall.log to /data/adb/logs/
- Removes conflicted weird modules
- Does not disable raw playback (You can use Audio Compatibility Patch Reborn Magisk Module instead)

v6.18
- Fix wrong target in latest KernelSU
- Improve detections

v6.17-R
- Tidy up aml.sh
- Exclude \*audio\*effects\*haptic\*.xml
- Abort installation if fail to mount mirror system
- Fix wrong file permissions in some ROMs
- Using libadspd.so built-in ROM if available

v6.16
- Fix isAtLeast methods
- Improve /odm and /my_product support detection

v6.15
- Add Action button to clear apps caches
- Fix architecture detection in some weird ROMs
- Fix bug in uninstall.sh
- Apply effect to rerouting and patch stream by default for game apps

v6.14
- Allow installation in Android Emulator
- Fix architecture detection

v6.13
- persistent="true" for quick settings tile responsiveness
- Improve \*audio\*effects\*.xml patch detection
- Fix conflict with modules_update while installing via recovery if Magisk installed
- Fix architecture detection
- Fix MagiskHide & SUList
- Fix selinux denials

v6.12
- Fix a script bug

v6.11
- Fix script bug
- Fix auto reboot
- Update blobs from msi-user-11-RPNS31.Q4U-39-27-9-2-8-cd477-release-keys
- Redirect /sdcard to /data/media/"$UID"
- Add new Magisk and Kitsune Mask support (independent mirror)
- Remount partitions before mounting mirror to prevent mount failure caused by device/resource busy
- Sets system property ro.audio.monitorWindowRotation to true if audio.rotation=1 at optionals.prop
- Fix MagiskHide & SUList
- Kitsune Mask detection

v6.10
- Specify UID at script
- Add optional debug.log=1 for more detailed install log
- Abort installation if ROM doesn't support 32 bit library
- Fix mount partition"

## Screenshots
https://reiryuki.blogspot.com/2020/09/motorola-waves-maxx-audio-fx-magisk.html?m=1

## Requirements
- armeabi-v7a or arm64-v8a with armeabi-v7a support architecture
- 32 bit HIDL audio service
- Android 8 (SDK 26) until 11 (SDK 30) initial builds only (Android 11 newer builds probably not supported)
- Magisk or Kitsune Mask or KernelSU or Apatch installed
- Moto Core Magisk Module installed https://github.com/reiryuki/Moto-Core-Magisk-Module except you are in Motorola ROM

## Installation Guide & Download Link
- If you are using KernelSU, you need to disable Unmount Modules by Default in KernelSU app settings and install https://github.com/KernelSU-Modules-Repo/meta-overlayfs or https://github.com/KernelSU-Modules-Repo/magic_mount_rs or https://github.com/KernelSU-Modules-Repo/hybrid_mount or https://github.com/maxsteeel/nomount first depending on ROM compatibility
- Remove any other else Moto Waves MAGISK MODULE with different name and reboot first (No need to remove if it's the same name)
- Install Moto Core Magisk Module first: https://github.com/reiryuki/Moto-Core-Magisk-Module except you are in Motorola ROM
- Install this module https://devuploads.com/tsh9u2gl12jc via Magisk app or Kitsune Mask app or KernelSU app or Apatch app or Recovery if Magisk or Kitsune Mask installed
- Install AML Magisk Module https://t.me/ryukinotes/34 only if using any other else audio mod module
- Reboot
- If you are using KernelSU, you need to allow superuser list manually all package name listed in package.txt (and your home launcher app also) (enable show system apps) and reboot afterwards
- If you are using SUList, you need to allow list manually your home launcher app (enable show system apps) and reboot afterwards
- Open Moto Audio app via quick settings and tap 'Show icon in the app tray' to show Moto Audio app icon launcher
- Tap 'About' then tap multiple times the image if you want to disable sound effect for loudspeaker

## Optionals
- https://t.me/ryukinotes/59
- Global: https://t.me/ryukinotes/35
- Stream: https://t.me/ryukinotes/52

## Troubleshootings
- https://t.me/ryukinotes/59
- Global: https://t.me/ryukinotes/34

## Support & Bug Report
- https://t.me/ryukinotes/54
- If you don't do above, issues will be closed immediately

## Credits and Contributors
- @HuskyDG
- https://t.me/viperatmos
- https://t.me/androidryukimodsdiscussions
- You can contribute ideas about this Magisk Module here: https://t.me/androidappsportdevelopment

## Sponsors
https://t.me/ryukinotes/25



/*++

Copyright (c) 2015 Minoca Corp.

    This file is licensed under the terms of the GNU General Public License
    version 3. Alternative licensing terms are available. Contact
    info@minocacorp.com for details. See the LICENSE file at the root of this
    project for complete licensing information.

Module Name:

    Raspberry Pi 2 UEFI Firmware

Abstract:

    This module implements UEFI firmware for the Raspberry Pi 2.

Author:

    Chris Stevens 19-Mar-2015

Environment:

    Firmware

--*/

from menv import executable, uefiFwvol, flattenedBinary;

function build() {
    var commonLibs;
    var elf;
    var entries;
    var ffs;
    var flattened;
    var fwVolume;
    var includes;
    var libs;
    var linkConfig;
    var linkLdflags;
    var plat = "rpi2";
    var platfw;
    var sources;
    var sourcesConfig;
    var textAddress = "0x00008000";

    sources = [
        "armv7/entry.S",
        "armv7/smpa.S",
        "armv7/timera.S",
        "debug.c",
        "fwvol.c",
        "intr.c",
        "main.c",
        "memmap.c",
        "ramdenum.c",
        ":" + plat + "fwv.o",
        "smbios.c",
        "smp.c",
        "timer.c",
    ];

    includes = [
        "$S/uefi/include"
    ];

    sourcesConfig = {
        "CFLAGS": ["-fshort-wchar"]
    };

    linkLdflags = [
        "-nostdlib",
        "-Wl,--no-wchar-size-warning",
        "-static"
    ];

    linkConfig = {
        "LDFLAGS": linkLdflags
    };

    commonLibs = [
        "uefi/core:ueficore",
        "kernel/kd:kdboot",
        "uefi/core:ueficore",
        "uefi/archlib:uefiarch",
        "lib/fatlib:fat",
        "lib/basevid:basevid",
        "lib/rtl/base:basertlb",
        "kernel/kd/kdusb:kdnousb",
        "kernel:archboot",
        "uefi/core:emptyrd",
    ];

    libs = [
        "uefi/dev/pl11:pl11",
        "uefi/dev/bcm2709:bcm2709",
        "uefi/dev/sd/core:sd",
    ];

    libs += commonLibs;
    platfw = plat + "fw";
    elf = {
        "label": platfw + ".elf",
        "inputs": sources + libs,
        "sources_config": sourcesConfig,
        "includes": includes,
        "config": linkConfig,
        "text_address": textAddress
    };

    entries = executable(elf);

    //
    // Build the firmware volume.
    //

    ffs = [
        "uefi/core/runtime:rtbase.ffs",
        "uefi/plat/" + plat + "/runtime:" + plat + "rt.ffs",
        "uefi/plat/" + plat + "/acpi:acpi.ffs"
    ];

    fwVolume = uefiFwvol("uefi/plat/rpi2", plat, ffs);
    entries += fwVolume;

    //
    // Flatten the firmware image.
    //

    flattened = {
        "label": platfw,
        "inputs": [":" + platfw + ".elf"],
        "implicit": ["uefi/plat/rpi2/blobs:blobs"],
        "binplace": "bin"
    };

    entries += flattenedBinary(flattened);
    return entries;
}


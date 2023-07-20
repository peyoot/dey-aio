# Copyright (C) 2018 Digi International Inc.
SUMMARY = "Home Addons" 
DESCRIPTION = "Adding optional files to homedir" 
LICENSE = "CLOSED" 
FILESEXTRAPATHS_prepend := "${THISDIR}/files:" 
RPROVIDES_${PN} += "${PN}" 
SRC_URI = "file://.profile \
        file://myfile.txt"
# Specify where to get the files
S = "${WORKDIR}" 
do_configure[noexec] = "1" 
do_compile[noexec] = "1" 
do_install() {
        # creating the destination directories
        install -d ${D}/home/root
        # extra files need to go in the respective directories
        install -m 0644 ${WORKDIR}/.profile ${D}/home/root/
        install -m 0644 ${WORKDIR}/myfile.txt ${D}/home/root/
}

FILES_${PN} += "/home/root/* \
        /home/root/.profile"

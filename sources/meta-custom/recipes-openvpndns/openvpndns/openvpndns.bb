# Copyright (C) 2018 Digi International Inc.
SUMMARY = "Openvpn Config" 
DESCRIPTION = "Adding config files to openvpn" 
LICENSE = "CLOSED" 
FILESEXTRAPATHS:prepend := "${THISDIR}/files:" 
RPROVIDES:${PN} += "${PN}" 
SRC_URI = "file://update-systemd-resolved"
# Specify where to get the files
S = "${WORKDIR}" 
do_configure[noexec] = "1" 
do_compile[noexec] = "1" 
do_install() {
        # creating the destination directories
        install -d ${D}/etc/openvpn
        # extra files need to go in the respective directories
        install -m 0644 ${WORKDIR}/update-systemd-resolved ${D}/etc/openvpn/
}

FILES:${PN} += "/ect/openvpn/* \
        /etc/openvpn/update-systemd-resolved"

SUMMARY = "pvpn daemon"
DESCRIPTION = "adding pvpn service file to systemd"
FILEEXTRAPATHS:prepend := "${THISDIR}/files:"
PROVIDERS:{PN} += "{PN}"
PVPN_GIT_URI = "gitsm://github.com/peyoot/pvpn.git;branch=dey-openvpn;protocol=https"

LICENSE = "CLOSED"
inherit systemd

SYSTEMD_AUTO_ENABLE = "disable"
SYSTEMD_SERVICE_${PN} = "stunnel.service openvpn-client@.service"


SRC_URI:append = " \
                   PVPN_GIT_URI \
                   file://stunnel.service \
                   file://openvpn-client@.service"
FILES:${PN} += "${systemd_unitdir}/system/stunnel.service \
                ${systemd_unitdir}/system/openvpn-client@.service \
                /usr/local/bin/install_vpn.sh"

do_install:append() {
  install -d ${D}/${systemd_unitdir}/system
  install -d ${D}/usr/local/bin
  install -m 0644 ${WORKDIR}/stunnel.service ${D}/${systemd_unitdir}/system/
  install -m 0644 ${WORKDIR}/openvpn-client@.service ${D}/${systemd_unitdir}/system/
  install -m 0644 ${WORKDIR}/install_vpn.sh ${D}/usr/local/bin/
}

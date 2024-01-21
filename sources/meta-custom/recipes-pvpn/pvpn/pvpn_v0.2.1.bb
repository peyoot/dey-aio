SUMMARY = "pvpn daemon"
DESCRIPTION = "adding pvpn service file to systemd"
FILEEXTRAPATHS:prepend := "${THISDIR}/files:"
PROVIDERS:{PN} += "{PN}"
PVPN_GIT_URI = "https://github.com/peyoot/pvpn/archive/refs/tags/${PV}.zip;protocol=https"
PVPN_GIT_URI[md5sum] = "112233445566"
PVPN_GIT_URI[sha256sum] = "665544332211"

LICENSE = "CLOSED"
inherit systemd

SYSTEMD_AUTO_ENABLE = "disable"
SYSTEMD_SERVICE_${PN} = "stunnel.service openvpn-client@.service"


SRC_URI:append = " \
                   ${PVPN_GIT_URI} \
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
  install -m 0644 ${WORKDIR}/${PN}-${PV}install_vpn.sh ${D}/usr/local/bin/
}

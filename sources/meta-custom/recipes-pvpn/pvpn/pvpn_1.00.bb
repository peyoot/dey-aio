SUMMARY = "pvpn daemon"
DESCRIPTION = "adding pvpn service file to systemd"
FILEEXTRAPATHS:prepend := "${THISDIR}/files:"
PROVIDERS:{PN} += "{PN}"

LICENSE = "CLOSED"
inherit systemd

SYSTEMD_AUTO_ENABLE = "disable"
SYSTEMD_SERVICE_${PN} = "stunnel.service openvpn-client@.service"

SRC_URI:append = " file://stunnel.service \
                   file://openvpn-client@.service"
FILES:${PN} += "${systemd_unitdir}/system/stunnel.service \
                ${systemd_unitdir}/system/openvpn-client@.service"

do_install_append() {
  install -d ${D}/${systemd_unitdir}/system
  install -m 0644 ${WORKDIR}/stunnel.service ${D}/${systemd_unitdir}/system/
  install -m 0644 ${WORKDIR}/openvpn-client@.service ${D}/${systemd_unitdir}/system/
}

# NobiTerminal build

This repository is a fork of robertkirkman/termux-generator used to build
**NobiTerminal** — a Termux fork rebuilt from source for the custom package
name `com.nobiterminal` (prefix `/data/data/com.nobiterminal/files/usr`),
app label `NobiTerminal`.

Build is run with the "Generate Termux application" GitHub Actions workflow
with these inputs:

- name: `com.nobiterminal`
- architectures: `aarch64`
- type: `f-droid`
- plugin: `nobiterminal` (sets the app label to NobiTerminal — see
  `plugins/nobiterminal/f-droid-patches/app-patches/nobiterminal-app-name.patch`)
- Addon apps disabled (tasker, float, widget, api, boot, styling, gui, x11)

Termux is open source (GPLv3, see the upstream projects termux/termux-app and
termux/termux-packages). All upstream attribution and license notices are kept
intact; this fork only changes the package name, installation prefix and app
label through the generator's supported name-change mechanism.

# SQUISH

[![Build Status](https://drone.owncloud.com/api/badges/owncloud-ci/squish/status.svg)](https://drone.owncloud.com/owncloud-ci/squish)

Container with all parts needed to run GUI tests of the ownCloud desktop client in CI.

This container is not maintained nor used by froglogic, or the Qt company. It's not intended for public use but purely for CI runs.

## Stack
- Ubuntu
- Xfce
- VNC
- noVNC
- squish

## Environment Variables

| variable                   | usage|
|----------------------------|----|
| LICENSEKEY                 | squish license key or license server URL |
| CLIENT_REPO                | full path to the root of the client code | 
| MIDDLEWARE_URL             | URL of the [testing middleware](https://github.com/owncloud/owncloud-test-middleware) |
| BACKEND_HOST               | URL of the owncloud server |
| SERVER_INI                 | full path of the `server.ini` file to be used |
| SQUISH_PARAMETERS          | further [squishrunner cli parameters](https://doc.froglogic.com/squish/latest/rg-cmdline.html#rg-squishrunner-cli) |

## Update squish
1. upload new version to https://minio.owncloud.com/minio/packages/squish/
2. set `squishversion` to match the uploaded filename. E.g. if the filename is `squish-6.7.0-qt512x-linux64.run` the version in drone must be set to `6.7.0-qt512x-linux64`

## Acknowledgment

This project is mostly a fork of https://github.com/accetto/xubuntu-vnc-novnc with some tweaks for the ownCloud use case.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


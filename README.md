# squish

[![Build Status](https://img.shields.io/drone/build/owncloud-ci/squish?logo=drone&server=https%3A%2F%2Fdrone.owncloud.com)](https://drone.owncloud.com/owncloud-ci/squish)
[![Docker Hub](https://img.shields.io/docker/v/owncloudci/squish?logo=docker&label=dockerhub&sort=semver&logoColor=white)](https://hub.docker.com/r/owncloudci/squish)
[![GitHub contributors](https://img.shields.io/github/contributors/owncloud-ci/squish)](https://github.com/owncloud-ci/squish/graphs/contributors)
[![Source: GitHub](https://img.shields.io/badge/source-github-blue.svg?logo=github&logoColor=white)](https://github.com/owncloud-ci/squish)
[![License: MIT](https://img.shields.io/github/license/owncloud-ci/squish)](https://github.com/owncloud-ci/squish/blob/master/LICENSE)

Container with all parts needed to run GUI tests of the ownCloud desktop client in CI.

This container is not maintained nor used by froglogic, or the Qt company. It's not intended for public use but purely for CI runs.

## Stack

- Ubuntu
- Xfce
- VNC
- noVNC
- squish

## Environment Variables

| variable            | usage                                                                                                                    |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| LICENSEKEY          | squish license key or license server URL                                                                                 |
| CLIENT_REPO         | full path to the root of the client code                                                                                 |
| MIDDLEWARE_URL      | URL of the [testing middleware](https://github.com/owncloud/owncloud-test-middleware)                                    |
| BACKEND_HOST        | URL of the owncloud server                                                                                               |
| SERVER_INI          | full path of the `server.ini` file to be used                                                                            |
| SQUISH_PARAMETERS   | further [squishrunner cli parameters](https://doc.froglogic.com/squish/latest/cli-squishrunner.html#rg-squishrunner-cli) |
| GUI_TEST_REPORT_DIR | directory to store GUI test report files                                                                                 |

## Update squish

1. upload new version to https://minio.owncloud.com/minio/packages/squish/
2. set `squishversion` to match the uploaded filename. E.g. if the filename is `squish-6.7.0-qt512x-linux64.run` the version in drone must be set to `6.7.0-qt512x-linux64`

## Acknowledgment

This project is mostly a fork of https://github.com/accetto/xubuntu-vnc-novnc with some tweaks for the ownCloud use case.

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/owncloud-ci/squish/blob/master/LICENSE) file for details.

## Copyright

```Text
Copyright (c) 2022 ownCloud GmbH
```

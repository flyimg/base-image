# Flyimg Changelog

## [1.8.1](https://github.com/flyimg/base-image/compare/1.8.0...1.8.1) (2025-07-03)


### Bug Fixes

* update Dockerfile to conditionally install pillow-avif-plugin based on TARGETPLATFORM and set PORT environment variable correctly ([d1bfe64](https://github.com/flyimg/base-image/commit/d1bfe64cb1c2d231e7860aec7e9c911455589939))

# [1.8.0](https://github.com/flyimg/base-image/compare/1.7.2...1.8.0) (2025-07-03)


### Features

* streamline Dockerfile and update build process by using multi-stage build ([4519b1a](https://github.com/flyimg/base-image/commit/4519b1aad194f6e5dffd1aaff1d4e57f000068b8))

## [1.7.2](https://github.com/flyimg/base-image/compare/1.7.1...1.7.2) (2025-07-03)


### Bug Fixes

* update dependencies in Dockerfile ([ae613ba](https://github.com/flyimg/base-image/commit/ae613ba7aa925ea874a24f5ff31716e3739cdd50))

## [1.7.1](https://github.com/flyimg/base-image/compare/1.7.0...1.7.1) (2024-10-28)


### Bug Fixes

* remove default nginx config ([3a035be](https://github.com/flyimg/base-image/commit/3a035bed015fa82e0790fd4ee21ed304328c1bd7))

# [1.7.0](https://github.com/flyimg/base-image/compare/1.6.1...1.7.0) (2024-10-28)


### Bug Fixes

* update imagemagick library version and AOM, WEBP, LIBJXL ([a8e5dba](https://github.com/flyimg/base-image/commit/a8e5dba6e47a820f5973a712bd14371b79ee8916))


### Features

* update to the latest nginx stable version: ([7b0e17f](https://github.com/flyimg/base-image/commit/7b0e17fb69f33e66745eea9475142c92db275b32))

## [1.6.1](https://github.com/flyimg/base-image/compare/1.6.0...1.6.1) (2024-09-11)


### Bug Fixes

* remove facedetect and smartcrop installation ([fd356bc](https://github.com/flyimg/base-image/commit/fd356bcc0cb2abb33ef92dc3e008e0eac8e9dcdd))

# [1.6.0](https://github.com/flyimg/base-image/compare/1.5.1...1.6.0) (2024-08-29)


### Features

* upgrade imagemagick library + HEIF, AOM, LIBJXL ([4095c89](https://github.com/flyimg/base-image/commit/4095c894f238e58789df6929bb517a423ff417f0))

## [1.5.1](https://github.com/flyimg/base-image/compare/1.5.0...1.5.1) (2024-08-28)


### Bug Fixes

* add cron service ([0a52586](https://github.com/flyimg/base-image/commit/0a525864e3cad3e6d0e6b25a574bd1f3501840bc))

# [1.5.0](https://github.com/flyimg/base-image/compare/1.4.5...1.5.0) (2024-05-10)


### Features

* update base image ([56e17f8](https://github.com/flyimg/base-image/commit/56e17f8939bbe21a85f516cc7517f1c1e28bfdc7))
* update main libraries and add multi platform build ([5f54cdd](https://github.com/flyimg/base-image/commit/5f54cdd46957143cb33a998bb310d117859889d6))

# [1.5.0](https://github.com/flyimg/base-image/compare/1.4.5...1.5.0) (2024-05-09)


### Features

* update main libraries and add multi platform build ([5f54cdd](https://github.com/flyimg/base-image/commit/5f54cdd46957143cb33a998bb310d117859889d6))

## [1.4.5](https://github.com/flyimg/base-image/compare/1.4.4...1.4.5) (2024-02-27)


### Bug Fixes

* fixing cd workflow, add DAOM_TARGET_CPU=generic ([7c532da](https://github.com/flyimg/base-image/commit/7c532dae33b575954d6d97498583901e44b1799d))

## [1.4.4](https://github.com/flyimg/base-image/compare/1.4.3...1.4.4) (2024-02-27)


### Bug Fixes

* fixing broken libomp lib and replace it with libompl-dev ([48d6f64](https://github.com/flyimg/base-image/commit/48d6f646200e43b208b7e3f737a0794070159c38))

## [1.4.3](https://github.com/flyimg/base-image/compare/1.4.2...1.4.3) (2024-02-27)


### Bug Fixes

* replace libomp-dev by libomp-11-dev ([1954213](https://github.com/flyimg/base-image/commit/1954213e0def83d0ca9b2eb1b7200cec81b66253))

## [1.4.2](https://github.com/flyimg/base-image/compare/1.4.1...1.4.2) (2024-02-27)


### Bug Fixes

* add Changelog file + releaserc file ([26f94f6](https://github.com/flyimg/base-image/commit/26f94f672e75079f00c6150dd0868f7f56b3f89e))
* refactor github workflow to add semantic-release + multi-arch docker image build ([14da30e](https://github.com/flyimg/base-image/commit/14da30e91d8ff52593f481b3083dcf7aa49e2ffc))

# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
### Changed
### Removed
### Fixed

## [0.4.0] - 2021-02-25
### Added
* Support for publishing messages in JSON protobuf format. The `#publish` macro now takes an optional second argument which indicates the message format to use. The value can be either `"json_protobuf"` or `"binary_protobuf"`. If the argument is omitted, `"binary_protobuf"` is used.

### Changed
* Use own our copy of protobuf library. The master branch of the protobuf library we use has the code for handling JSON protobufs properly. However, there has not been an official release. We've opted to fork the official repo, tag it, and point Railway to use our tagged version. Once the protobuf library publishes an official release, we'll switch back to using it.

## [0.3.2] - 2021-02-22
### Fixed
* Fixed issue where protobuf `data` fields were not properly decoded when using JSON protobufs. This is a short term fix until the protobuf library we're using cuts a release with the JSON support we need.

## [0.3.1] - 2021-02-19
### Changed
* Reduce Payload module coupling. Have the `Payload#encode` and `Payload#decode` functions return the type as part of their tuple.
* Moved `Repo` to `test/support`. It's only used by tests; having it in `lib` is confusing.

### Fixed
* Ensure protobuf message context maps have string keys when decoding JSON protobufs.

## [0.3.0] - 2021-02-08
### Added
* Support for decoding JSON protobufs
* [dev] End to end smoke tests
* [dev] New test helpers (`DataCase`, `wait_for_true`, etc.)
* [dev] CircleCI build with checks for Credo, formatting, etc.

### Changed
* [BREAKING CHANGE] Remove all features that are present only to support Railway UI. These are:
    - command messages
    - message re-publishing
    - direct message publishing
* [dev] Various internal refactorings to cleanup the codebase

## [0.2.7] - ???
No changes were recorded for this release, nor was it tagged.

## [0.2.2] - 2020-03-10
### Changed
* Messages can be consumed multiple times if the same message comes in on different queues
* See README section "Consuming the same message on multiple queues" for upgrade migration instructions
* Migrations have been configured so that theres one for each table and they are up to date

### Fixed
* Locks consumed messages for processing to avoid unintentional processing duplication
* Ignore re-consumption of previously successful message instead of crashing

## [0.2.1] - 2020-01-28
### Changed
* Update install instructions
* Allow migrations to be written to custom path
* [dev] Code formatted the project

### Fixed
* Publishing messages with UUIDs in the event that a message UUID is not passed in
* [dev] Update config so that tests run locally

[Unreleased]: https://github.com/learn-co/railway_ipc/compare/0.4.0...HEAD
[0.4.0]: https://github.com/learn-co/railway_ipc/compare/0.3.2...0.4.0
[0.3.2]: https://github.com/learn-co/railway_ipc/compare/0.3.1...0.3.2
[0.3.1]: https://github.com/learn-co/railway_ipc/compare/0.3.0...0.3.1
[0.3.0]: https://github.com/learn-co/railway_ipc/compare/6dddf529e2e41d46ce567a1d572a4bd227049d66...0.3.0
[0.2.7]: https://github.com/learn-co/railway_ipc/compare/bac8e1f8ce1d4a5ad515f274abce7813ce25c7e7..6dddf529e2e41d46ce567a1d572a4bd227049d66
[0.2.2]: https://github.com/learn-co/railway_ipc/compare/0.2.1...0.2.2
[0.2.1]: https://github.com/learn-co/railway_ipc/releases/tag/0.2.1

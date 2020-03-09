# Changelog for v0.x

## v0.2.2 (TBD)

### Enhancements

  * Messages can be consumed multiple times if the same message comes in on different queues
  * Migrations have been configured so that theres one for each table and they are up to date

## v0.2.1 (2020-01-28)

### Enhancements

  * Update install instructions
  * Allow migrations to be written to custom path
  * [dev] Code formatted the project

### Bug fixes

  * Publishing messages with UUIDs in the event that a message UUID is not passed in
  * [dev] Update config so that tests run locally

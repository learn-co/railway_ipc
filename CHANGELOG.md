# Changelog for v0.x

## v0.2.2 (2020-03-10)

### Enhancements

  * Messages can be consumed multiple times if the same message comes in on different queues
    * See README section "Consuming the same message on multiple queues" for upgrade migration instructions
  * Migrations have been configured so that theres one for each table and they are up to date

### Bug fixes

  * Locks consumed messages for processing to avoid unintentional processing duplication
  * Ignore re-consumption of previously successful message instead of crashing

## v0.2.1 (2020-01-28)

### Enhancements

  * Update install instructions
  * Allow migrations to be written to custom path
  * [dev] Code formatted the project

### Bug fixes

  * Publishing messages with UUIDs in the event that a message UUID is not passed in
  * [dev] Update config so that tests run locally

# Dataset ingestion management

This repository is for tracking of data issues seen during data ingestion processes. It contains a number of issues automatically logged when dataset ingestions are paused.

The main issues detected and logged are change in occurrenceIDs. This is in order to improve occurrence stability: https://www.gbif.org/news/2M3n65fHOhvq4ek5oVOskc/new-processing-routine-improves-stability-of-gbif-occurrence-ids

For each issue:
 1. we check if there is any indication that the change was on purpose (we look for comments in the IPT or send an email to the data provider or technical contatc or Node)
 2. if the change was on purpose and the data providers are able to provide us with a table of old and new occurrenceID, we can update those on GBIF's side (https://github.com/gbif/pipelines/tree/dev/gbif/identifiers/diagnostics)
 3. if the change was on purpose and there is no such table, we resume ingestion and new gbifid will be created
 4. if the changes was accidental, we wait until the data provider rolls back the changes

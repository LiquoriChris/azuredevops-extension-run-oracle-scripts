# Run Oracle Database Scripts

Executes Oracle database scripts using sqlplus commandline tool.

## Details

Task can run multiple database scripts during a release.

## How it works

Task will look for .sql files in a specified directory to run sqlplus against a database. Options can be added to the sql file to enhance functionality of the script.

## Note

Sqlplus.exe must be available before running this task.

Run Pester test located under "Tests" folder to verify sqlplus is installed.

If using self-hosted pipelines, a user-defined capability may have to be added to each build server (sqlplus.exe).
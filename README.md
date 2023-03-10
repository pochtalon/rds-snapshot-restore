# RDS Snapshot Restore

The goal of this script is to restore a RDS snapshot based on the original RDS instance. <br />
It can be executed from both terminal (putty) or CloudShell.

## Limitations
Not all AWS regions have access to CloudShell. <br />
https://docs.aws.amazon.com/general/latest/gr/cloudshell.html

## Instructions
After executed the script, you will have to provide:
* Region **ID**.
* The RDS **DB identifier** you want to keep the configuration from (e.g. engine, instance class, security group, license model, etc) on the restored instance.
* **Snapshot name** that will be used to restore.
* New RDS DB identifier.

## Restored instance features
* No multi-AZ.
* No public access.
* Tags will be copied from snapshot.
* Make sure you modify Parameter Group after restore is completed.

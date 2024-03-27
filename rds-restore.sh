#!/bin/bash  
##################################################
########  SCRIPT TO RESTORE A SNAPSHOT  ##########
############  FROM AN EXISTING RDS  ##############
##################################################

clear

region="eu-central-1"

echo "Available RDS instances"
aws rds describe-db-instances --query DBInstances[].DBInstanceIdentifier

read -p "Enter RDS instance name to restore the configuration from: " RDSDbIdentifier
rds=$(aws rds describe-db-instances --db-instance-identifier $RDSDbIdentifier --region $region --query DBInstances[].DBInstanceIdentifier 2>/dev/null)

# Check if the original RDS instance exist
if [ -z "$rds" ]; then
        echo -e "RDS Instance $RDSDbIdentifier does not exist or region is not correct!"
else
        aws rds describe-db-snapshots --db-instance-identifier $RDSDbIdentifier --max-records 20 --query "DBSnapshots[*].[DBSnapshotIdentifier, SnapshotCreateTime]" --output table

        read -p "Enter Snapshot name to be restored: " SnapshotName
        snapshot=$(aws rds describe-db-snapshots --db-snapshot-identifier $SnapshotName --region $region --query DBSnapshots[].DBSnapshotIdentifier 2>/dev/null)
        # Check if the snapshot to be restored exist
        if [ -z "$snapshot" ]; then
                echo "Snapshot name $SnapshotName does not exist!"
        else
                read -p "Enter new RDS name: " NewRDSInstanceName
                #Create a JSON file from the original RDS instance
                aws rds describe-db-instances --db-instance-identifier $RDSDbIdentifier --region $region >$RDSDbIdentifier.json

                #Declare variables
                engine=$(cat $RDSDbIdentifier.json | grep -w Engine | cut -d "\"" -f4)
                license=$(cat $RDSDbIdentifier.json | grep LicenseModel | cut -d "\"" -f4)
                DBSubnetGroupName=$(cat $RDSDbIdentifier.json | grep DBSubnetGroupName | cut -d "\"" -f4)
                VpcSGId=$(cat $RDSDbIdentifier.json | grep VpcSecurityGroupId | cut -d "\"" -f4)
                port=$(cat $RDSDbIdentifier.json | grep -w Port | cut -d ":" -f2 | cut -d "," -f1)
                DBInstanceClass=$(cat $RDSDbIdentifier.json | grep DBInstanceClass | cut -d "\"" -f4)
                license=$(cat $RDSDbIdentifier.json | grep LicenseModel | cut -d "\"" -f4)
                multiaz=$(cat $RDSDbIdentifier.json | grep -w MultiAZ |egrep -o "true|false")
                if [ $multiaz == false ]; then
                        multiazresult="--no-multi-az"
                else
                        multiazresult="--multi-az"
                fi
                publicaccess=$(cat $RDSDbIdentifier.json | grep -w PubliclyAccessible |egrep -o "true|false")
                if [ $publicaccess == false ]; then
                        publicaccessresult="--no-publicly-accessible"
                else
                        publicaccessresult="--publicly-accessible"
                fi


                #Restore snapshot command
                aws rds restore-db-instance-from-db-snapshot --db-snapshot-identifier $SnapshotName --engine $engine --license-model $license --db-instance-identifier $NewRDSInstanceName --no-multi-az --db-subnet-group-name $DBSubnetGroupName --no-publicly-accessible --vpc-security-group-ids $VpcSGId --port $port --db-instance-class $DBInstanceClass --copy-tags-to-snapshot $multiazresult $publicaccessresult --region $region


                echo "Host name for new rds instance:"

                hostname=""
                while [ -z "$hostname" ]; do
                        #Get new RDS instance hostname
                        hostname=$(aws rds describe-db-instances --db-instance-identifier $NewRDSInstanceName --query 'DBInstances[*].Endpoint.Address' --output text)
                        if [ -z "$hostname" ]; then
                                echo "Waiting for RDS instance to be available..."
                                sleep 10
                        fi
                done

                #Get list of EC2 instances' names and IPs
                aws ec2 describe-instances --instance-ids i-0d1f628bfbc743d0a --query "Reservations[].Instances[].[PublicIpAddress,Tags[?Key==`Name`].Value]"

                echo "RDS instance hostname: $hostname"


                #Delete the JSON file
                rm -rf $RDSDbIdentifier.json
        fi
fi
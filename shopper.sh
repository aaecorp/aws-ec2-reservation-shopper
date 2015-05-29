#!/bin/bash

clear;

# This tool interviews the user to determine current EC2 reservation costs and the hourly rates associated with them.

# Check for presence of jq
JQ_VERSION="$(jq --version)"
if [[ "$JQ_VERSION" == "jq-1."* ]]; then
      # installed
      echo ""
    else
      # missing
      echo "jq is not installed. Please run 'yum install jq' or 'apt-get install jq'"
      exit 0;
fi

# Check for presence of aws-cli
AWS_VERSION="$(aws --version)"
if [[ "$AWS_VERSION" == "aws-cli"* ]]; then
      # installed
      echo ""
    else
      # missing
      # echo "aws-cli is not installed. Please make sure you have python-pip installed and then run 'pip install aws-cli'"
      echo ""
      # exit 0;
fi

##### GATHER INPUT
echo ""
echo "    What AWS region do you want to search for reservations in? (Enter US-East-1, US-West-2, etc., then press [ENTER]):"
echo "        1. US-East-1"
echo "        2. US-West-1"
echo "        3. US-West-2"
read region
echo ""
echo "    What OS do you want to reserve an instance for? (Enter 1 or 2, then press [ENTER]):"
echo "        1. Linux/Unix"
echo "        2. Windows"
read ostype
echo ""
echo "    What instance type do you want to reserve? (Enter m3.medium, r3.xlarge, etc., then press [ENTER]):"
echo "        1. t2.micro"
echo "        2. t2.small"
echo "        3. t2.medium"
echo "        4. m3.medium"
echo "        5. m3.large"
echo "        6. m3.xlarge"
echo "        7. c3.large"
echo "        8. c3.xlarge"
echo "        9. c3.2xlarge"
echo "        10. r3.large"
echo "        11. r3.xlarge"
echo "        12. r3.2xlarge"
read instancetype
echo ""
echo "    What reservation type would you like to purchase? (Enter 'No Upfront', 'Partial Upfront' or 'All Upfront' and then press [ENTER]):"
echo "        1. No Upfront"
echo "        2. Partial Upfront"
echo "        3. All Upfront"
read restype
echo ""
echo "    Do you want a 1 or 3-year reservation? (Enter 1 or 3 then press [ENTER]):"
read length

# Parse some things
if [ $region -eq 1 ]; then
    regionsel="us-east-1"
elif [ $region -eq 2 ]; then
    regionsel="us-west-1"
elif [ $region -eq 3 ]; then
    regionsel="us-west-2"
fi

if [ $ostype -eq 1 ]; then
    ostypesel="Linux/Unix (Amazon VPC)"
elif [ $ostype -eq 2 ]; then
    ostypesel="Windows (Amazon VPC)"
fi

if [ $length -eq 1 ]; then
    lengthsel="31536000"
elif [ $length -eq 3 ]; then
    lengthsel="94608000"
fi

if [ $instancetype -eq 1 ]; then
    instancetypesel="t2.micro"
elif [ $instancetype -eq 2 ]; then
    instancetypesel="t2.small"
elif [ $instancetype -eq 3 ]; then
    instancetypesel="t2.medium"
elif [ $instancetype -eq 4 ]; then
    instancetypesel="m3.large"
elif [ $instancetype -eq 5 ]; then
    instancetypesel="m3.xlarge"
elif [ $instancetype -eq 6 ]; then
    instancetypesel="m3.large"
elif [ $instancetype -eq 7 ]; then
    instancetypesel="c3.large"
elif [ $instancetype -eq 8 ]; then
    instancetypesel="c3.xlarge"
elif [ $instancetype -eq 9 ]; then
    instancetypesel="c3.2xlarge"
elif [ $instancetype -eq 10 ]; then
    instancetypesel="r3.large"
elif [ $instancetype -eq 11 ]; then
    instancetypesel="r3.xlarge"
elif [ $instancetype -eq 12 ]; then
    instancetypesel="r3.2xlarge"
fi

if [ $restype -eq 1 ]; then
    restypesel="No Upfront"
elif [ $restype -eq 2 ]; then
    restypesel="Partial Upfront"
elif [ $restype -eq 3 ]; then
    restypesel="All Upfront"
fi

aws ec2 describe-reserved-instances-offerings --instance-type $instancetypesel --product-description "$ostypesel" --offering-type "$restypesel" --instance-tenancy default --no-include-marketplace --max-duration $lengthsel --output json > output.json

fixedprice=`cat output.json | jq -r .ReservedInstancesOfferings[0].FixedPrice`

if [ $restype -eq 1 ]; then
    # No Upfront
    usageprice=`cat output.json | jq -r .ReservedInstancesOfferings[0].RecurringCharges[0].Amount`
elif [ $restype -eq 2 ]; then
    # Partial Upfront
    usageprice=`cat output.json | jq -r .ReservedInstancesOfferings[0].RecurringCharges[0].Amount`
elif [ $restype -eq 3 ]; then
    # All Upfront
    usageprice=`cat output.json | jq -r .ReservedInstancesOfferings[0].UsagePrice`
fi

yearusage=`echo "scale=2; $usageprice*8760" | bc`
yeartotal=`echo "scale=2; $yearusage+$fixedprice" | bc`

# Show the user these same values
echo "---------------------------------------------------------";
echo "   Your EC2 Reservation details are:";
echo "---------------------------------------------------------";
echo "     Reservation Region:              $regionsel";
echo "     Reservation OS Type:             $ostypesel";
echo "     Reservation Instance Type:       $instancetypesel";
echo "     Reservation Type:                $restypesel";
echo "     Reservation Duration (yrs):      $length";
echo "     Fixed Price (to buy):            $ $fixedprice";
echo "     Usage Price (hourly):            $ $usageprice";
echo "     Yearly Operation (8760 hrs):     $ $yearusage";
echo "     Yearly TOTAL:                    $ $yeartotal";
echo "---------------------------------------------------------";

exit 0;


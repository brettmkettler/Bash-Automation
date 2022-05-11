#！/bin/bash

###############################
## EIP MDMS CONSOLE UI       ##
## Created by: Brett Kettler ## 
##                           ##
###############################
##
## ToDo
## 1. Add MasterDataTxnLog Error Checker : select * from EIP.PROCESS_EXCP where ARG_3_VALUE in ('27787590') order by INSERT_TIME desc;
##    "Assett has invalid state" means device does not have location ID. ## AM11680966 ##
## 2. 
##
##
##
export ORACLE_HOME=/u01/oracle/app/oracle/product/12.1.0/db_1
export PATH=/u01/oracle/app/oracle/product/12.1.0/db_1/bin:/usr/java/jdk1.8.0_121/jre/bin:/usr/java/jdk1.8.0_121/jre/jre/bin:/opt/python27/bin:/usr/lib64/qt-3.3/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/eip/bin:/home/eip/bin:/home/eip/bin

edb="eip/jmR12dN87cB6"
bdb="BKETTLE/4esesg}}"
proddb="enteiprd.prod.entergy.com:1521/enteiprd.world"

#########METER CHECK#########################################################################################################

menu_option_one() {
#cat meters.csv |while read udc_id
#do


echo Please type the BADGE_ID of the meter: 
read badge_id

ct=$(date "+%Y.%m.%d-%H.%M.%S")

meterlog=METER_$badge_id-$ct.txt

udc_id=$(sqlplus -s $edb@//$proddb <<- EOF
@sql/udc_id.sql $badge_id
exit;	
EOF
)

channels=$(sqlplus -s $edb@//$proddb <<- EOF
@sql/check.sql $badge_id
exit;	
EOF
)
activity=$(sqlplus -s $edb@//$proddb <<- EOF
@sql/activity.sql $badge_id
exit;
EOF
)

meterstatus=$(sqlplus -s $edb@//$proddb << EOF
@sql/status_cd_badge.sql $badge_id
exit;
EOF
)
location=$(sqlplus -s $edb@//$proddb << EOF
@sql/location.sql $badge_id
exit;
EOF
)

dataservices=$(sqlplus -s $edb@//$proddb << EOF
@sql/dataservices.sql $badge_id
exit;
EOF
)

sdp=$(sqlplus -s $edb@//$proddb << EOF
@sql/sdp_ref.sql $badge_id
exit;
EOF
)

device_id=$(sqlplus -s $edb@//$proddb << EOF
@sql/device_id.sql $badge_id
exit;
EOF
)



echo ""
echo ""
#echo $channels
echo "------~ METER INFORMATION ~-------"
echo ""
echo "BADGE_ID:"
echo "$badge_id"
echo ""
echo "UDC_ID: $udc_id"
echo ""
echo "Device ID: $device_id"
echo ""
echo "SDP REF ID: $sdp"
echo ""

#printf "------~ METER INFORMATION ~-------" >> $meterlog
#printf "BADGE_ID: $badge_id\n" >> $meterlog
#printf "UDC_ID: $udc_id\n" >> $meterlog

echo "-------~METER STATUS~-------"
echo "Meter $badge_id is in $meterstatus status."


echo ""
echo "-------~DATA SERVICES~-------"

if [[ "$dataservices" == *6* ]]; then 
echo "Meter $badge_id has 6 Data Services. Data Service Check good."

else
echo "Meter has $dataservices Data Services. Please check"
fi

echo ""
echo "-------~CHANNELS~-------"

if [[ "$channels" == *22* ]]; then 
echo "Meter $badge_id is Commercial and has 22 Channels."
elif [[ "$channels" == *13* ]]; then
echo "Meter $badge_id is Residential and has 13 Channels."
elif [[ "$channels" == *24* ]]; then
echo "Meter $badge_id is Commercial and has 24 Channels."
else
echo "Channels: $channels "
echo "Meter has a problem with channels. Please check."
fi

echo ""
echo "-------~METER MULTIPLIER~-------"
sqlplus -s $edb@//$proddb << EOF
@sql/metermultiplier.sql $badge_id
exit;
EOF


echo ""
echo "-------~LOCATION~-------"
echo ""

sqlplus -s $edb@//$proddb << EOF
@sql/location_check.sql $badge_id
exit;
EOF

echo ""
echo ""

if [ -z "$location" ]; then 

echo "Meter does not have location, please check above table meter could have been ended."
echo ""
else

echo "Current Location:"
echo "$location"
echo ""

fi
#################################

echo ""
echo "------------------------------"
echo "-------~METER HISTORY~-------"
echo "-----------------------------"

sqlplus -s $bdb@//$proddb << EOF
@sql/sdp_meter_history.sql $sdp
exit;
EOF


echo ""
echo "-------------------------------"
echo "-------~CHANNEL HISTORY~-------"
echo "-------------------------------"

sqlplus -s $bdb@//$proddb << EOF
@sql/channel_history_badge.sql $badge_id
exit;
EOF


echo ""
echo "---------------------------------"
echo "-------~REG MEAS HISTORY~-------"
echo "--------------------------------"
echo "Make sure records are ended here if this"
echo "is previous device at this location."
echo ""
sqlplus -s $bdb@//$proddb << EOF
@sql/meas_check_badge.sql $badge_id
exit;
EOF



echo ""
echo "------------------------"
echo "-------~ACTIVITY~-------"
echo "------------------------"

sqlplus -s $edb@//$proddb << EOF
@sql/activity.sql $badge_id
exit;
EOF

echo ""

echo ""
echo "---------------------------"
echo "-------~MASTER DATA~-------"
echo "---------------------------"

sqlplus -s $bdb@//$proddb << EOF
@sql/master_data_txn.sql $badge_id
exit;
EOF

echo ""
echo "Type Codes: *Not full list*"
echo "1 = SAP Meter Create"
echo "2 = SAP Meter Change"
echo "3 = SAP Location Notification"
echo "4 = SAP Register Create"
echo "5 = SAP Register Change"
echo "6 = SAP Rel Notification-Communication Module"
echo "7 = SAP MeasTask Change"
echo "8 = SAP TimeSeries MeasTask Assignment Change"
echo "9 = SAP Device Assignment Notification"
echo "10 = SAP PointOfDelivery Assigned Notification"
echo "41 = SAP INDV METER REPLICATION"
echo ""
echo "Status Codes *Not full list*"
echo "1 = open"
echo "2 = pending"
echo "3 = failed"
echo "4 = done"
echo "9 = ignored"

}

#######################################################################################################3





menu_option_twenty() {
####SETUP####

ct=$(date "+%Y.%m.%d-%H.%M.%S")

xml="xml/MasterDataTxn_FORMATTED_XML_$ct.xml"
xml_temp="bin/xmltemp.html"

##LATER - sharelocation="\\cctfsetsp001\home\bkettle\XML_EXPORT\"

truncate -s 0 $xml_temp

#############
echo ""
echo "Payload Exporter"
echo ""
echo "Grab MasterDataTxnID before pressing enter."
echo ""
##echo ""
##echo "1. "
##echo ""
##echo "2. "
echo Please type the MasterDataTxnID for Transaction: 
read mdt_id
#############
##printf "============XML=============" >> $xml
echo "XML Out"
echo ""

xml_out=$(sqlplus -s $bdb@//$proddb << EOF
@sql/xml_export.sql $mdt_id
exit;
EOF
)


#echo "$xml_out"

printf "$xml_out" >> $xml

sed -i -e 's!&lt;!<!g' -e 's!&gt;!>!g' -e 's!&amp;!&!g' -e 's!&quot;!"!g' $xml

echo "FORMATTED: "

cat $xml

echo ""
echo ""

#printf "$xml_file" >> $xml

##test 25764335











}





###################################
#######################################
#########END LEGACY METER#########################################################################################################
menu_option_six() {
####SETUP####

ct=$(date "+%Y.%m.%d-%H.%M.%S")
edb="eip/jmR12dN87cB6"
bdb="BKETTLE/4esesg}}"
db="eip_dba/eegla$1a3 "
proddb="enteiprd.prod.entergy.com:1521/enteiprd.world"
meters_terminated="/home/eip/capgemini/scripts/EIP_UI/logs/LegacyMetersTerminated-$ct.csv"

#############
echo ""
echo "END LEGACY METER"
echo ""
echo ""
echo ""
##echo ""
##echo "1. "
##echo ""
##echo "2. "
echo ""
read -p "Press enter to continue"
echo ""
#############

echo Please type the LEGACY METER BADGE ID: 
read badge_id

## Check if legacy is already ended
meterstatus=$(sqlplus -s $edb@//$proddb << EOF
@sql/status_cd_badge.sql $badge_id
exit;
EOF
)



if [[ $badge_id == "AM"* ]]; then 
echo "Invalid Meter Number, must NOT comtain AM or be a AMI Meter."

elif [[ $meterstatus == *Meter*Shop* ]]; then 

echo "Legacy Meter already ended, please check or continue replication on AMI device." 

else

##PASSED CHECKS
echo "Please type the END DATE of LEGACY DEVICE (FORMAT: 01-SEP-15) DAY-MON-YEAR": 
read date_end


device_id=$(sqlplus -s $edb@//$proddb << EOF
@sql/device_id.sql $badge_id
exit;
EOF
)

sdp=$(sqlplus -s $edb@//$proddb << EOF
@sql/sdp_ref.sql $badge_id
exit;
EOF
)


echo "Badge ID: $badge_id"
echo "Device ID: $device_id"
echo "Date to End: $date_end"

##VERIFY
echo "Please verify information is complete."
echo ""
read -p "Press enter to continue or CTRL + Z to quit."
echo ""

echo "Ending Meas IDs..." 
#
meas_update=$(sqlplus -s $edb@//$proddb << EOF
@sql/end_meas.sql $date_end $device_id
exit;
EOF
)

echo "$meas_update"
echo ""
echo "Ending Channels..." 
#
channel_update=$(sqlplus -s $edb@//$proddb << EOF
@sql/end_channels.sql $date_end $device_id
exit;
EOF
)
echo "$channel_update"
echo ""
echo "Ending Multipliers..." 
#
multiplier_update=$(sqlplus -s $edb@//$proddb << EOF
@sql/end_devicemulti.sql $date_end $device_id
exit;
EOF
)
echo "$multiplier_update"
echo ""

#
echo "Ending Service Point Relationship..." 
svc_pt_rel=$(sqlplus -s $edb@//$proddb << EOF
@sql/end_svc_pt_rel.sql $date_end $sdp
exit;
EOF
)
echo "$svc_pt_rel"
echo ""

#
echo "Ending Service Point Device Relationship..." 
svc_pt_rel_device=$(sqlplus -s $edb@//$proddb << EOF
@sql/end_svc_pt_device_rel.sql $date_end $sdp
exit;
EOF
)
echo "$svc_pt_rel_device"
echo ""

#
echo "Ending Service Point Relationship Parameters..." 
svc_pt_rel_params=$(sqlplus -s $edb@//$proddb << EOF
@sql/end_svc_pt_re_params.sql $date_end $sdp
exit;
EOF
)
echo "$svc_pt_rel_params"
echo ""

echo "Ending Service Agreement..." 
service_agreement=$(sqlplus -s $edb@//$proddb << EOF
@sql/end_sa.sql $date_end $sdp
exit;
EOF
)
echo "$service_agreement"
echo ""

###
echo "Ending Data Services..." 
end_data_services=$(sqlplus -s $edb@//$proddb << EOF
@sql/end_dataservices.sql $date_end $sdp
exit;
EOF
)
echo "$end_data_services"
echo ""
###

###
echo "Ending Power Load Billing..." 
end_powerloadbilling=$(sqlplus -s $edb@//$proddb << EOF
@sql/end_powerloadbilling.sql $sdp
exit;
EOF
)
echo "$end_powerloadbilling"
echo ""
###


echo "Ending Location..." 
#
location_update=$(sqlplus -s $edb@//$proddb << EOF
@sql/end_location.sql $date_end $device_id
exit;
EOF
)
echo "$location_update"


echo "Changing Legacy Meter to METERSHOP status..." 
#
metershop_status_update=$(sqlplus -s $edb@//$proddb << EOF
@sql/metershop_status.sql $badge_id
exit;
EOF
)
echo "$metershop_status_update"

#################END
echo ""
echo "Done, please check meter: $badge_id with option 1."


fi



}


###################################
#######################################
#########END LEGACY METER#########################################################################################################
menu_option_seven() {
####SETUP####

ct=$(date "+%Y.%m.%d-%H.%M.%S")
edb="eip/jmR12dN87cB6"
bdb="BKETTLE/4esesg}}"
db="eip_dba/eegla$1a3 "
proddb="enteiprd.prod.entergy.com:1521/enteiprd.world"
meters_terminated="/home/eip/capgemini/scripts/EIP_UI/logs/LegacyMetersTerminated-$ct.csv"

#############
echo ""
echo "END LEGACY METER - Forceful Remove (No Checks)"
echo ""
echo "Will need the old locations SDP REF ID."
echo ""
##echo ""
##echo "1. "
##echo ""
##echo "2. "
echo ""
read -p "Press enter to continue"
echo ""
#############

echo Please type the LEGACY METER BADGE ID: 
read badge_id




if [[ $badge_id == "AM"* ]]; then 
echo "Invalid Meter Number, must NOT comtain AM or be a AMI Meter."

else

##PASSED CHECKS
echo "Please type the END DATE of LEGACY DEVICE (FORMAT: 01-SEP-15) DAY-MON-YEAR": 
read date_end


echo "Please type the Service Point ID or SDP REF ID (SDP ID of the old location): ": 
read sdp


device_id=$(sqlplus -s $edb@//$proddb << EOF
@sql/device_id.sql $badge_id
exit;
EOF
)



echo "Badge ID: $badge_id"
echo "Device ID: $device_id"
echo "Date to End: $date_end"

##VERIFY
echo "Please verify information is complete."
echo ""
read -p "Press enter to continue or CTRL + Z to quit."
echo ""

echo "Ending Meas IDs..." 
#
meas_update=$(sqlplus -s $edb@//$proddb << EOF
@sql/end_meas.sql $date_end $device_id
exit;
EOF
)

echo "$meas_update"
echo ""
echo "Ending Channels..." 
#
channel_update=$(sqlplus -s $edb@//$proddb << EOF
@sql/end_channels.sql $date_end $device_id
exit;
EOF
)
echo "$channel_update"
echo ""
echo "Ending Multipliers..." 
#
multiplier_update=$(sqlplus -s $edb@//$proddb << EOF
@sql/end_devicemulti.sql $date_end $device_id
exit;
EOF
)
echo "$multiplier_update"
echo ""

#
echo "Ending Service Point Relationship..." 
svc_pt_rel=$(sqlplus -s $edb@//$proddb << EOF
@sql/end_svc_pt_rel.sql $date_end $sdp
exit;
EOF
)
echo "$svc_pt_rel"
echo ""

#
echo "Ending Service Point Device Relationship..." 
svc_pt_rel_device=$(sqlplus -s $edb@//$proddb << EOF
@sql/end_svc_pt_device_rel.sql $date_end $sdp
exit;
EOF
)
echo "$svc_pt_rel_device"
echo ""

#
echo "Ending Service Point Relationship Parameters..." 
svc_pt_rel_params=$(sqlplus -s $edb@//$proddb << EOF
@sql/end_svc_pt_re_params.sql $date_end $sdp
exit;
EOF
)
echo "$svc_pt_rel_params"
echo ""

echo "Ending Service Agreement..." 
service_agreement=$(sqlplus -s $edb@//$proddb << EOF
@sql/end_sa.sql $date_end $sdp
exit;
EOF
)
echo "$service_agreement"
echo ""

###
echo "Ending Data Services..." 
end_data_services=$(sqlplus -s $edb@//$proddb << EOF
@sql/end_dataservices.sql $date_end $sdp
exit;
EOF
)
echo "$end_data_services"
echo ""
###

###
echo "Ending Power Load Billing..." 
end_powerloadbilling=$(sqlplus -s $edb@//$proddb << EOF
@sql/end_powerloadbilling.sql $sdp
exit;
EOF
)
echo "$end_powerloadbilling"
echo ""
###


echo "Ending Location..." 
#
location_update=$(sqlplus -s $edb@//$proddb << EOF
@sql/end_location.sql $date_end $device_id
exit;
EOF
)
echo "$location_update"


echo "Changing Legacy Meter to METERSHOP status..." 
#
metershop_status_update=$(sqlplus -s $edb@//$proddb << EOF
@sql/metershop_status.sql $badge_id
exit;
EOF
)
echo "$metershop_status_update"

#################END
echo ""
echo "Done, please check meter: $badge_id with option 1."


fi



}

#####FLEXSYNC CHECK  - CSV ############################################################################################################
## 1. device table
## 2. udc id (id from device table , EIP.ACTIVITY table)

## select * from eip.activity where SUB_TYPE='Meter - Add'and STATUS_CD='Done' and OUTCOME_CD='Success'and DEVICE_ID='10125395'; (This ## device ID is  id from eip.device table after querrying the device id)

## The receive UDC_ID from CCS


menu_option_eight() {

ct=$(date "+%Y.%m.%d-%H.%M.%S")
##flexsync_out=flexsync_out_$ct.txt
flexsync_check_error=flexsync_check_error_$ct.csv
flexsync_complete=flexsync_completed_list_$ct.csv
flexsync_other_status=flexsync_other_status_$ct.csv
count=0
total=0
failed=0
other=0
#############
echo ""
echo "FLEXSYNC CHECKER"
echo ""
echo "Be sure to load the meters.csv file before pressing enter."
echo ""
##echo ""
##echo "1. "
##echo ""
##echo "2. "
echo ""
read -p "Press enter to continue"
echo ""
#############

printf "BADGE_ID\n" >> $flexsync_check_error
printf "BADGE_ID\n" >> $flexsync_complete
printf "BADGE_ID\n" >> $flexsync_other_status

echo "Checking FLEXSYNC..."
cat meters.csv |while read badge_id
do
udc_id=$(sqlplus -s $edb@//$proddb << EOF
@sql/get_udc.sql $badge_id
exit;
EOF
)

echo ""
flexsync=$(sqlplus -s $edb@//$proddb << EOF
@sql/flexsync_check_udc.sql $udc_id
exit;
EOF
)

if [[ "$flexsync" == *Success* ]]; then 
printf "$badge_id\n" >> $flexsync_complete
echo "Flexsync is complete, added $badge_id , $flexsync record to: $flexsync_complete "
total=$((total+1))
count=$((count+1))
elif [[ "$flexsync" == *Failed* ]]; then
printf "$badge_id\n" >> $flexsync_check_error
echo "Flexsync has failed, please check the reason. Added $badge_id , $flexsync  record to: $flexsync_check_error"
total=$((total+1))
failed=$((failed+1))
else
printf "$badge_id\n" >> $flexsync_other_status
echo "Flexsync is status: $flexsync Please check. Added $badge_id , $flexsync  record to: $flexsync_other_status"
echo $flexsync
total=$((total+1))
other=$((other+1))
fi

echo "-----------------------"
echo "TOTAL Meters in file: $total"
echo "TOTAL Success Flexsync: $count"
echo "TOTAL Failed Flexsync: $failed"
echo "TOTAL Flexsync Other: $other"
echo "-----------------------"
echo ""

echo "$flexsync"

done

}
#####################################
##################### FLEXSYNC ERROR CHECK  - CSV 
###################################

menu_option_nine() {

ct=$(date "+%Y.%m.%d-%H.%M.%S")
flexsync_failure_outfile=flexsync_out_$ct.txt
#############
echo ""
echo "FLEXSYNC ERROR CHECKER"
echo ""
echo "Be sure to load the flexsync_error.csv file before pressing enter."
echo ""
##echo ""
##echo "1. "
##echo ""
##echo "2. "
echo ""
read -p "Press enter to continue"
echo ""
#############

cat flexsync_error.csv |while read udc_id
do
echo ""
echo " **INFO** Next queries will take 3-4 minutes to run... Please Wait."
echo ""
location=$(sqlplus -s $edb@//$proddb << EOF
@sql/location_udc.sql $udc_id
exit;
EOF
)
flexsync_error=$(sqlplus -s $edb@//$proddb << EOF
@sql/flexsync_errorcheck.sql $location
exit;
EOF
)

echo "FLEXSYNC ERRORS: "
echo $flexsync_error

if [ -z "$flexsync_error" ] ## Add if flexsync null
then

echo "No records in Flexsync Table. Flexsync was not triggered for this record, please resend to CCS to trigger Flexsync."
printf "$udc_id\n" >> $flexsync_failure_outfile
printf "NO FLEXSYNC RECORDS\n" >> $flexsync_failure_outfile

#IGNORE DUPLICATE
#elif [[ "$flexsync_error" == *Enter*value*for*1* ]]; then
#echo "DUPLICATE - Removing Duplicate..."

else
printf "$udc_id\n" >> $flexsync_failure_outfile
printf "$flexsync_error\n" >> $flexsync_failure_outfile
fi
done



}

##################################################################################################################################################################################
##################################################################################################################################################################################
##########################################################
##########################################################   SINGLE METER RUNS
##################################################################################################################################################################################
##################################################################################################################################################################################
#########REPLICATION CHECK#########################################################################################################
##################################################################################################################################################################################
##################################################################################################################################################################################

menu_option_two() {


echo Please type the UDC_ID of the meter: 
read udc_id

ct=$(date "+%Y.%m.%d-%H.%M.%S")

####GET BADGE_ID for UDC

badge_id=$(sqlplus -s $edb@//$proddb <<- EOF
@sql/get_badge_id.sql $udc_id
exit;	
EOF
)

channels=$(sqlplus -s $edb@//$proddb <<- EOF
@sql/check.sql $badge_id
exit;	
EOF
)
activity=$(sqlplus -s $edb@//$proddb <<- EOF
@sql/activity.sql $badge_id
exit;
EOF
)

meterstatus=$(sqlplus -s $edb@//$proddb << EOF
@sql/status_cd_badge.sql $badge_id
exit;
EOF
)
location=$(sqlplus -s $edb@//$proddb << EOF
@sql/location.sql $badge_id
exit;
EOF
)

dataservices=$(sqlplus -s $edb@//$proddb << EOF
@sql/dataservices.sql $badge_id
exit;
EOF
)

echo ""
echo ""
echo "------~ METER INFORMATION ~-------"
echo ""
echo "BADGE_ID:"
echo "$badge_id"
echo ""
echo "UDC_ID: $udc_id"
echo ""



echo "-------~METER STATUS~-------"
#printf "-------~METER STATUS~-------" >> $meterlog
if [[ "$meterstatus" == *Meter*Shop* ]]; then 
echo "Meter $badge_id is still in METER SHOP status."
#printf "Meter $badge_id is still in METER SHOP status." >> $meterlog
elif [[ "$meterstatus" == *Installed* ]]; then
echo "Meter $badge_id is INSTALLED"
#printf "Meter $badge_id is INSTALLED" >> $meterlog

else
echo $meterstatus
echo "Please check."
fi

echo ""
echo "-------~DATA SERVICES~-------"

if [[ "$dataservices" == *6* ]]; then 
echo "Meter $badge_id has 6 Data Services. Data Service Check good."

else
echo "Meter has $dataservices Data Services. Please check"
fi


echo ""
echo "-------~CHANNELS~-------"

if [[ "$channels" == *22* ]]; then 
echo "Meter $badge_id is Commercial and has 22 Channels."
elif [[ "$channels" == *13* ]]; then
echo "Meter $badge_id is Residential and has 13 Channels."
else
echo "Channes: $channels"
echo "Meter has a problem with channels. Please check."
fi

echo ""
echo "-------~METER MULTIPLIER~-------"
sqlplus -s $edb@//$proddb << EOF
@sql/metermultiplier.sql $badge_id
exit;
EOF

echo ""
echo "-------~LOCATION~-------"
echo ""

sqlplus -s $edb@//$proddb << EOF
@sql/location_check.sql $badge_id
exit;
EOF

echo ""
echo ""

if [ -z "$location" ]; then 

echo "Meter does not have location, please check above table meter could have been ended."
echo ""
else

echo "Current Location:"
echo "$location"
echo ""

fi
#################################

echo ""
echo "------------------------"
echo "-------~ACTIVITY~-------"
echo "------------------------"

sqlplus -s $edb@//$proddb << EOF
@sql/activity.sql $badge_id
exit;
EOF

echo ""

echo ""
echo "---------------------------"
echo "-------~MASTER DATA~-------"
echo "---------------------------"

sqlplus -s $bdb@//$proddb << EOF
@sql/master_data_txn.sql $badge_id
exit;
EOF

echo ""
echo "Type Codes: *Not full list*"
echo "1 = SAP Meter Create"
echo "2 = SAP Meter Change"
echo "3 = SAP Location Notification"
echo "4 = SAP Register Create"
echo "5 = SAP Register Change"
echo "6 = SAP Rel Notification-Communication Module"
echo "7 = SAP MeasTask Change"
echo "8 = SAP TimeSeries MeasTask Assignment Change"
echo "9 = SAP Device Assignment Notification"
echo "10 = SAP PointOfDelivery Assigned Notification"
echo "41 = SAP INDV METER REPLICATION"
echo ""
echo "Status Codes *Not full list*"
echo "1 = open"
echo "2 = pending"
echo "3 = failed"
echo "4 = done"
echo "9 = ignored"

}


###########################
###########################
###########################
###########################
#########LOCATION FINDER - SINGLE #########################################################################################################
menu_option_three() {
ct=$(date "+%Y.%m.%d-%H.%M.%S")

#############



echo "Location Information"
echo Please type the LOCATION of the meter: 
read location_id

location_check=$(sqlplus -s $bdb@//$proddb << EOF
@sql/finding_active_devices_for_location.sql $location_id
exit;
EOF
)


echo "$location_check"

#================================================================WORK HERE

## Need to write query to match the CCS output file that includes (UDC ID and the location) then possibly have a seperate database
## 1. Write query to read udc_id and location id from csv
## 2. Query would put both values into the query, and if badge_id was like AM% then success,
## the meter needs to go to flexsync.
##
## If value is not like AM%, then send to CCS those to end legacy (UDC_ID only)


## IF AM% there
## write to txt file all rows if AM is there

## 1. If AM% is there we need to CHECK for flexsync and if not run ask for flexsync (in format email) to CCS

## If badge id null, send for replication? or what?

## ==============================================================================WORK HERE
## IF LEGACY is there, END LEGACY DEVICE_ID
## 1. Print out list of legacy
## 2. Send email to CCS to end legacy meter (UDC_ID from device table) if it is not AM%



}

##### MasterDataTxn ID Check - Process Exception Check ############################################################################################################

#Put Master Data Txn ID

menu_option_four() {

ct=$(date "+%Y.%m.%d-%H.%M.%S")

echo "Grab MasterDataTxnID from failed TXN."
echo ""
echo Please type the MasterDataTxnID: 
read masterdatatxn

echo ""
sqlplus -s $edb@//$proddb << EOF
@sql/masterdatatxn_check_process.sql $masterdatatxn
exit;
EOF



}


#####################################
##################### FLEXSYNC ERROR CHECK  - SINGLE 
###################################

menu_option_five() {

ct=$(date "+%Y.%m.%d-%H.%M.%S")

echo "NOTE: Location_ID is the UDC_ID of SDP..."
echo ""
echo Please type the UDC_ID or Location_ID of the meter: 
read udc_id

echo ""
echo " **INFO** Next queries will take 3-4 minutes to run... Please Wait."
echo ""

location=$(sqlplus -s $edb@//$proddb << EOF
@sql/location_udc.sql $udc_id
exit;
EOF
)
flexsync_error=$(sqlplus -s $edb@//$proddb << EOF
@sql/flexsync_errorcheck.sql $location
exit;
EOF
)

echo "FLEXSYNC ERRORS: "
echo $flexsync_error

if [ -z "$flexsync_error" ] ## Add if flexsync null
then

echo "No records in Flexsync Table. Flexsync was not triggered for this record, please resend to CCS to trigger Flexsync."


#IGNORE DUPLICATE
#elif [[ "$flexsync_error" == *Enter*value*for*1* ]]; then
#echo "DUPLICATE - Removing Duplicate..."

else

echo "Please Investigate."

fi




}

menu_option_ten() {

files1=$(ls /home/eip/data/meterreads/UtilityIQ414/in | wc -l)

files2=`ssh jdcupmdmseip2.entergy.com "ls /home/eip/data/meterreads/UtilityIQ414/in | wc -l"`

files3=`ssh jdcupmdmseip3.entergy.com "ls /home/eip/data/meterreads/UtilityIQ414/in | wc -l"`

files4=`ssh jdcupmdmseip4.entergy.com "ls /home/eip/data/meterreads/UtilityIQ414/in | wc -l"`

files5=`ssh jdcupmdmseip5.entergy.com "ls /home/eip/data/meterreads/UtilityIQ414/in | wc -l"`

files6=`ssh jdcupmdmseip6.entergy.com "ls /home/eip/data/meterreads/UtilityIQ414/in | wc -l"`

files7=`ssh jdcupmdmseip7.entergy.com "ls /home/eip/data/meterreads/UtilityIQ414/in | wc -l"`

total=$(( $files1+$files2+$files3+$files4+$files5+$files6+$files7 ))

set -e

echo "Folder Monitor File Count: "
echo ""
printf "jdcupmdmseip1:\n  files $files1 \n\n"

printf "jdcupmdmseip2:\n  files $files2 \n\n"

printf "jdcupmdmseip3:\n  files $files3 \n\n"

printf "jdcupmdmseip4:\n  files $files4 \n\n"

printf "jdcupmdmseip5:\n  files $files5 \n\n"

printf "jdcupmdmseip6:\n  files $files6 \n\n"

printf "jdcupmdmseip7:\n  files $files7 \n\n\n"

printf "TOTAL Files: $total \n"

echo ""
echo ""


}
##### Device Read Process ActiveMQ QUeues
menu_option_eleven() {


server1=`cat apps/server1_apps.txt`
server2=`cat apps/server2_apps.txt`
server3=`cat apps/server3_apps.txt`
server4=`cat apps/server4_apps.txt`
server5=`cat apps/server5_apps.txt`
server6=`cat apps/server6_apps.txt`
server7=`cat apps/server7_apps.txt`
server8=`cat apps/server8_apps.txt`
server9=`cat apps/server9_apps.txt`
server10=`cat apps/server10_apps.txt`
server11=`cat apps/server11_apps.txt`
server12=`cat apps/server12_apps.txt`
server13=`cat apps/server13_apps.txt`
server14=`cat apps/server14_apps.txt`
server15=`cat apps/server15_apps.txt`
server16=`cat apps/server16_apps.txt`
server17=`cat apps/server17_apps.txt`
server18=`cat apps/server18_apps.txt`


## Server get file queues uncomment on
curl -u admin:admin -o queues/activemq_MDMS_s1.xml http://jdcupmdmseip1.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s2.xml http://jdcupmdmseip2.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s3.xml http://jdcupmdmseip3.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s4.xml http://jdcupmdmseip4.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s5.xml http://jdcupmdmseip5.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s6.xml http://jdcupmdmseip6.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s7.xml http://jdcupmdmseip7.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s8.xml http://jdcupmdmseip8.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s9.xml http://jdcupmdmseip9.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s10.xml http://jdcupmdmseip10.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s11.xml http://jdcupmdmseip11.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s12.xml http://jdcupmdmseip12.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s13.xml http://jdcupmdmseip13.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s14.xml http://jdcupmdmseip14.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s15.xml http://jdcupmdmseip15.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s16.xml http://jdcupmdmseip16.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s17.xml http://jdcupmdmseip17.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s18.xml http://jdcupmdmseip18.entergy.com:8161/admin/xml/queues.jsp

i=0

drp_count=0

zero=0

drp_total=0

#queue_count_file=/home/eip/capgemini/scripts/EIP_UI/count.dat


declare -i Queue_count

truncate -s 0 $queue_count_file

echo "jdcupmdmseip1 Queues"
echo "==================================="
for app in $server1;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s1.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip2 Queues"
for app in $server2;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s2.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip3 Queues"
for app in $server3;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s3.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip4 Queues"
for app in $server4;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s4.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip5 Queues"
for app in $server5;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s5.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip6 Queues"
for app in $server6;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s6.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip7 Queues"
for app in $server7;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s7.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip8 Queues"
for app in $server8;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s8.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip9 Queues"
for app in $server9;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s9.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip10 Queues"
for app in $server10;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s10.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip11 Queues"
for app in $server11;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s11.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip12 Queues"
for app in $server12;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s12.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip13 Queues"
for app in $server13;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s13.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip14 Queues"
for app in $server14;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s14.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip15 Queues"
for app in $server15;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s15.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip16 Queues"
for app in $server16;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s16.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip17 Queues"
for app in $server17;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s17.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip18 Queues"
for app in $server18;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s18.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
### LOGIC
#########################


upperlim=$drp_$i
echo "================================================================="
   echo "TOTAL Active Queue Count: $drp_total"

#totalcount=0
#echo "Upper Limit: $upperlim"

#for ((i=0; i<=upperlim; i++)); do
#   echo "DRP: drp_$i"
#   echo "Queue Count: $(drp_$i)"
#   
#   if [[ "drp_$i" > 0 ]]; then
#   echo "TOTAL: $num"
#   fi
   
#done



####################################
echo "========================================="
echo ""
echo ""



}



##################################################################################################################################################################################

##################################################################################################################################################################################



menu_option_twelve() {


server1=`cat apps/uiq/server1_apps.txt`
server2=`cat apps/uiq/server2_apps.txt`
server3=`cat apps/uiq/server3_apps.txt`
server4=`cat apps/uiq/server4_apps.txt`
server5=`cat apps/uiq/server5_apps.txt`
server6=`cat apps/uiq/server6_apps.txt`
server7=`cat apps/uiq/server7_apps.txt`



## Server get file queues uncomment on
curl -u admin:admin -o queues/activemq_MDMS_s1.xml http://jdcupmdmseip1.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s2.xml http://jdcupmdmseip2.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s3.xml http://jdcupmdmseip3.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s4.xml http://jdcupmdmseip4.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s5.xml http://jdcupmdmseip5.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s6.xml http://jdcupmdmseip6.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s7.xml http://jdcupmdmseip7.entergy.com:8161/admin/xml/queues.jsp


i=0

drp_count=0

zero=0

drp_total=0

#queue_count_file=/home/eip/capgemini/scripts/EIP_UI/count.dat


declare -i Queue_count

#truncate -s 0 $queue_count_file

echo "jdcupmdmseip1 Queues"
echo "==================================="
for app in $server1;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s1.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip2 Queues"
for app in $server2;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s2.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip3 Queues"
for app in $server3;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s3.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip4 Queues"
for app in $server4;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s4.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip5 Queues"
for app in $server5;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s5.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip6 Queues"
for app in $server6;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s6.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip7 Queues"
for app in $server7;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s7.xml |grep 'stats size' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
########################
### LOGIC
#########################


upperlim=$drp_$i
echo "================================================================="
   echo "TOTAL Active Queue Count: $drp_total"





####################################
echo "========================================="
echo ""
echo ""



}

menu_option_thirteen() {

server1=`cat apps/dds/server1_apps.txt`
server2=`cat apps/dds/server2_apps.txt`
server3=`cat apps/dds/server3_apps.txt`
server4=`cat apps/dds/server4_apps.txt`
server5=`cat apps/dds/server5_apps.txt`
server6=`cat apps/dds/server6_apps.txt`
server7=`cat apps/dds/server7_apps.txt`
server8=`cat apps/dds/server8_apps.txt`
server9=`cat apps/dds/server9_apps.txt`
server10=`cat apps/dds/server10_apps.txt`
server11=`cat apps/dds/server11_apps.txt`
server12=`cat apps/dds/server12_apps.txt`
server13=`cat apps/dds/server13_apps.txt`
server14=`cat apps/dds/server14_apps.txt`
server15=`cat apps/dds/server15_apps.txt`
server16=`cat apps/dds/server16_apps.txt`
server17=`cat apps/dds/server17_apps.txt`
server18=`cat apps/dds/server18_apps.txt`

previous_total=`cat previous_total.txt`
previous_file="previous_total.txt"
#Clear Previous run
truncate -s 0 $previous_file


ct=$(date "+%Y.%m.%d - %H.%M")

pt=`cat previous_time.txt`
previous_time_file="previous_time.txt"
#Clear Previous time
truncate -s 0 $previous_time_file
#log current time
echo "$ct" >> $previous_time_file




## Server get file queues uncomment on
curl -u admin:admin -o queues/activemq_MDMS_s1.xml http://jdcupmdmseip1.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s2.xml http://jdcupmdmseip2.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s3.xml http://jdcupmdmseip3.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s4.xml http://jdcupmdmseip4.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s5.xml http://jdcupmdmseip5.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s6.xml http://jdcupmdmseip6.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s7.xml http://jdcupmdmseip7.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s8.xml http://jdcupmdmseip8.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s9.xml http://jdcupmdmseip9.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s10.xml http://jdcupmdmseip10.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s11.xml http://jdcupmdmseip11.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s12.xml http://jdcupmdmseip12.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s13.xml http://jdcupmdmseip13.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s14.xml http://jdcupmdmseip14.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s15.xml http://jdcupmdmseip15.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s16.xml http://jdcupmdmseip16.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s17.xml http://jdcupmdmseip17.entergy.com:8161/admin/xml/queues.jsp
curl -u admin:admin -o queues/activemq_MDMS_s18.xml http://jdcupmdmseip18.entergy.com:8161/admin/xml/queues.jsp


i=0

drp_count=0

zero=0

drp_total=0

#queue_count_file=/home/eip/capgemini/scripts/EIP_UI/count.dat


declare -i Queue_count

truncate -s 0 $queue_count_file

echo "jdcupmdmseip1 Queues"
echo "==================================="
for app in $server1;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s1.xml |grep 'stats size' |cut -d '"' -f 2`
#Enqueue
EnQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s1.xml |grep 'enqueueCount' |cut -d '"' -f 2`
#Dequeue
DeQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s1.xml |grep 'dequeueCount' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
echo "EnQueue_Count: "$EnQueue_count
echo "DeQueue_Count: "$DeQueue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip2 Queues"
for app in $server2;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s2.xml |grep 'stats size' |cut -d '"' -f 2`
#Enqueue
EnQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s2.xml |grep 'enqueueCount' |cut -d '"' -f 2`
#Dequeue
DeQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s2.xml |grep 'dequeueCount' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
echo "EnQueue_Count: "$EnQueue_count
echo "DeQueue_Count: "$DeQueue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip3 Queues"
for app in $server3;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s3.xml |grep 'stats size' |cut -d '"' -f 2`
#Enqueue
EnQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s3.xml |grep 'enqueueCount' |cut -d '"' -f 2`
#Dequeue
DeQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s3.xml |grep 'dequeueCount' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
echo "EnQueue_Count: "$EnQueue_count
echo "DeQueue_Count: "$DeQueue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip4 Queues"
for app in $server4;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s4.xml |grep 'stats size' |cut -d '"' -f 2`
#Enqueue
EnQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s4.xml |grep 'enqueueCount' |cut -d '"' -f 2`
#Dequeue
DeQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s4.xml |grep 'dequeueCount' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
echo "EnQueue_Count: "$EnQueue_count
echo "DeQueue_Count: "$DeQueue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip5 Queues"
for app in $server5;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s5.xml |grep 'stats size' |cut -d '"' -f 2`
#Enqueue
EnQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s5.xml |grep 'enqueueCount' |cut -d '"' -f 2`
#Dequeue
DeQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s5.xml |grep 'dequeueCount' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
echo "EnQueue_Count: "$EnQueue_count
echo "DeQueue_Count: "$DeQueue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip6 Queues"
for app in $server6;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s6.xml |grep 'stats size' |cut -d '"' -f 2`
#Enqueue
EnQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s6.xml |grep 'enqueueCount' |cut -d '"' -f 2`
#Dequeue
DeQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s6.xml |grep 'dequeueCount' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
echo "EnQueue_Count: "$EnQueue_count
echo "DeQueue_Count: "$DeQueue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip7 Queues"
for app in $server7;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s7.xml |grep 'stats size' |cut -d '"' -f 2`
#Enqueue
EnQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s7.xml |grep 'enqueueCount' |cut -d '"' -f 2`
#Dequeue
DeQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s7.xml |grep 'dequeueCount' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
echo "EnQueue_Count: "$EnQueue_count
echo "DeQueue_Count: "$DeQueue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip8 Queues"
for app in $server8;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s8.xml |grep 'stats size' |cut -d '"' -f 2`
#Enqueue
EnQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s8.xml |grep 'enqueueCount' |cut -d '"' -f 2`
#Dequeue
DeQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s8.xml |grep 'dequeueCount' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
echo "EnQueue_Count: "$EnQueue_count
echo "DeQueue_Count: "$DeQueue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip9 Queues"
for app in $server9;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s9.xml |grep 'stats size' |cut -d '"' -f 2`
#Enqueue
EnQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s9.xml |grep 'enqueueCount' |cut -d '"' -f 2`
#Dequeue
DeQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s9.xml |grep 'dequeueCount' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
echo "EnQueue_Count: "$EnQueue_count
echo "DeQueue_Count: "$DeQueue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip10 Queues"
for app in $server10;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s10.xml |grep 'stats size' |cut -d '"' -f 2`
#Enqueue
EnQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s10.xml |grep 'enqueueCount' |cut -d '"' -f 2`
#Dequeue
DeQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s10.xml |grep 'dequeueCount' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
echo "EnQueue_Count: "$EnQueue_count
echo "DeQueue_Count: "$DeQueue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip11 Queues"
for app in $server11;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s11.xml |grep 'stats size' |cut -d '"' -f 2`
#Enqueue
EnQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s11.xml |grep 'enqueueCount' |cut -d '"' -f 2`
#Dequeue
DeQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s11.xml |grep 'dequeueCount' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
echo "EnQueue_Count: "$EnQueue_count
echo "DeQueue_Count: "$DeQueue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip12 Queues"
for app in $server12;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s12.xml |grep 'stats size' |cut -d '"' -f 2`
#Enqueue
EnQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s12.xml |grep 'enqueueCount' |cut -d '"' -f 2`
#Dequeue
DeQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s12.xml |grep 'dequeueCount' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
echo "EnQueue_Count: "$EnQueue_count
echo "DeQueue_Count: "$DeQueue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
########################
echo "jdcupmdmseip13 Queues"
for app in $server13;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s13.xml |grep 'stats size' |cut -d '"' -f 2`
#Enqueue
EnQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s13.xml |grep 'enqueueCount' |cut -d '"' -f 2`
#Dequeue
DeQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s13.xml |grep 'dequeueCount' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
echo "EnQueue_Count: "$EnQueue_count
echo "DeQueue_Count: "$DeQueue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip14 Queues"
for app in $server14;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s14.xml |grep 'stats size' |cut -d '"' -f 2`
#Enqueue
EnQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s14.xml |grep 'enqueueCount' |cut -d '"' -f 2`
#Dequeue
DeQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s14.xml |grep 'dequeueCount' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
echo "EnQueue_Count: "$EnQueue_count
echo "DeQueue_Count: "$DeQueue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip15 Queues"
for app in $server15;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s15.xml |grep 'stats size' |cut -d '"' -f 2`
#Enqueue
EnQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s15.xml |grep 'enqueueCount' |cut -d '"' -f 2`
#Dequeue
DeQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s15.xml |grep 'dequeueCount' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
echo "EnQueue_Count: "$EnQueue_count
echo "DeQueue_Count: "$DeQueue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip16 Queues"
for app in $server16;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s16.xml |grep 'stats size' |cut -d '"' -f 2`
#Enqueue
EnQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s16.xml |grep 'enqueueCount' |cut -d '"' -f 2`
#Dequeue
DeQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s16.xml |grep 'dequeueCount' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
echo "EnQueue_Count: "$EnQueue_count
echo "DeQueue_Count: "$DeQueue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip17 Queues"
for app in $server17;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s17.xml |grep 'stats size' |cut -d '"' -f 2`
#Enqueue
EnQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s17.xml |grep 'enqueueCount' |cut -d '"' -f 2`
#Dequeue
DeQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s17.xml |grep 'dequeueCount' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
echo "EnQueue_Count: "$EnQueue_count
echo "DeQueue_Count: "$DeQueue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done
########################
echo "jdcupmdmseip18 Queues"
for app in $server18;do
echo "App_name: "$app
Queue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s18.xml |grep 'stats size' |cut -d '"' -f 2`
#Enqueue
EnQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s18.xml |grep 'enqueueCount' |cut -d '"' -f 2`
#Dequeue
DeQueue_count=`sed -n "/<queue name=$app>/,/<\/queue>/p" queues/activemq_MDMS_s18.xml |grep 'dequeueCount' |cut -d '"' -f 2`
echo "Queue_Count: "$Queue_count
echo "EnQueue_Count: "$EnQueue_count
echo "DeQueue_Count: "$DeQueue_count
   if [ "$Queue_count" -gt "$zero" ]; then
   drp_total=$((drp_total+Queue_count))
   echo "TOTAL: $drp_total"
   fi
i=$((i +1))
declare "drp_$i=$Queue_count"
echo $drp_$i
echo ""
echo ""
done

########################
### LOGIC
#########################
echo "$drp_total" >> $previous_file

upperlim=$drp_$i

diff_total=$((previous_total-drp_total))


echo "Current TOTAL Queue Count: $drp_total"

echo "================================================================="
   echo "Prev. Queue Count: $previous_total"
   echo "Curr. Queue Count: $drp_total"
   echo ""
   echo "Difference: $diff_total"
   echo ""
   echo "Current Time: $ct"
   echo "Previous Run: $pt"
   


####################################
echo "========================================="
echo ""
echo ""






}
###############################################
###################
##############################################
menu_option_sixteen() {


files1=$(ls /home/eip/data/meterreads/UtilityIQ414/in/stage | wc -l)

files2=`ssh jdcupmdmseip2.entergy.com "ls /home/eip/data/meterreads/UtilityIQ414/in/stage | wc -l"`

files3=`ssh jdcupmdmseip3.entergy.com "ls /home/eip/data/meterreads/UtilityIQ414/in/stage | wc -l"`

files4=`ssh jdcupmdmseip4.entergy.com "ls /home/eip/data/meterreads/UtilityIQ414/in/stage | wc -l"`

files5=`ssh jdcupmdmseip5.entergy.com "ls /home/eip/data/meterreads/UtilityIQ414/in/stage | wc -l"`

files6=`ssh jdcupmdmseip6.entergy.com "ls /home/eip/data/meterreads/UtilityIQ414/in/stage | wc -l"`

files7=`ssh jdcupmdmseip7.entergy.com "ls /home/eip/data/meterreads/UtilityIQ414/in/stage | wc -l"`

total=$(( $files1+$files2+$files3+$files4+$files5+$files6+$files7 ))

set -e

echo "STAGE Folder Monitor File Count: "
echo ""
printf "jdcupmdmseip1:\n  files $files1 \n\n"

printf "jdcupmdmseip2:\n  files $files2 \n\n"

printf "jdcupmdmseip3:\n  files $files3 \n\n"

printf "jdcupmdmseip4:\n  files $files4 \n\n"

printf "jdcupmdmseip5:\n  files $files5 \n\n"

printf "jdcupmdmseip6:\n  files $files6 \n\n"

printf "jdcupmdmseip7:\n  files $files7 \n\n\n"

printf "TOTAL Files: $total \n"





}


menu_option_fourteen() {

echo ""
echo "ALERT ----------------------"

echo "This will move ALL files from stage to IN directory. Make sure you want to do this..."


echo ""
read -p "Press enter to continue"
echo ""

echo "Moving ALL files from stage to IN directory..."

files1=$(mv /home/eip/data/meterreads/UtilityIQ414/in/stage/*.xml /home/eip/data/meterreads/UtilityIQ414/in/ )

files2=`ssh jdcupmdmseip2.entergy.com "mv /home/eip/data/meterreads/UtilityIQ414/in/stage/*.xml /home/eip/data/meterreads/UtilityIQ414/in/ "`

files3=`ssh jdcupmdmseip3.entergy.com "mv /home/eip/data/meterreads/UtilityIQ414/in/stage/*.xml /home/eip/data/meterreads/UtilityIQ414/in/ "`

files4=`ssh jdcupmdmseip4.entergy.com "mv /home/eip/data/meterreads/UtilityIQ414/in/stage/*.xml /home/eip/data/meterreads/UtilityIQ414/in/ "`

files5=`ssh jdcupmdmseip5.entergy.com "mv /home/eip/data/meterreads/UtilityIQ414/in/stage/*.xml /home/eip/data/meterreads/UtilityIQ414/in/ "`

files6=`ssh jdcupmdmseip6.entergy.com "mv /home/eip/data/meterreads/UtilityIQ414/in/stage/*.xml /home/eip/data/meterreads/UtilityIQ414/in/ "`

files7=`ssh jdcupmdmseip7.entergy.com "mv /home/eip/data/meterreads/UtilityIQ414/in/stage/*.xml /home/eip/data/meterreads/UtilityIQ414/in/ "`

echo ""
echo "Checking files if moved..."

files1=$(ls /home/eip/data/meterreads/UtilityIQ414/in/stage | wc -l)

files2=`ssh jdcupmdmseip2.entergy.com "ls /home/eip/data/meterreads/UtilityIQ414/in/stage | wc -l"`

files3=`ssh jdcupmdmseip3.entergy.com "ls /home/eip/data/meterreads/UtilityIQ414/in/stage | wc -l"`

files4=`ssh jdcupmdmseip4.entergy.com "ls /home/eip/data/meterreads/UtilityIQ414/in/stage | wc -l"`

files5=`ssh jdcupmdmseip5.entergy.com "ls /home/eip/data/meterreads/UtilityIQ414/in/stage | wc -l"`

files6=`ssh jdcupmdmseip6.entergy.com "ls /home/eip/data/meterreads/UtilityIQ414/in/stage | wc -l"`

files7=`ssh jdcupmdmseip7.entergy.com "ls /home/eip/data/meterreads/UtilityIQ414/in/stage | wc -l"`

total=$(( $files1+$files2+$files3+$files4+$files5+$files6+$files7 ))

set -e

echo "STAGE Folder Monitor File Count: "
echo ""
printf "jdcupmdmseip1:\n  files $files1 \n\n"

printf "jdcupmdmseip2:\n  files $files2 \n\n"

printf "jdcupmdmseip3:\n  files $files3 \n\n"

printf "jdcupmdmseip4:\n  files $files4 \n\n"

printf "jdcupmdmseip5:\n  files $files5 \n\n"

printf "jdcupmdmseip6:\n  files $files6 \n\n"

printf "jdcupmdmseip7:\n  files $files7 \n\n\n"

printf "TOTAL Files in Stage now: $total \n"

printf ""



}

menu_option_sixteen_old() {

echo "Create Stage a directory"

stagename="stage-5PM"

echo ""
read -p "Press enter to continue"
echo ""

echo "Create directoryies..."
#mkdir -p /home/eip/data/meterreads/UtilityIQ414/in/stage/stage2

stage2_1=$(mkdir -p /home/eip/data/meterreads/UtilityIQ414/in/stage/$stagename)

stage2_2=`ssh jdcupmdmseip2.entergy.com "mkdir -p /home/eip/data/meterreads/UtilityIQ414/in/stage/$stagename"`

stage2_3=`ssh jdcupmdmseip3.entergy.com "mkdir -p /home/eip/data/meterreads/UtilityIQ414/in/stage/$stagename"`

stage2_4=`ssh jdcupmdmseip4.entergy.com "mkdir -p /home/eip/data/meterreads/UtilityIQ414/in/stage/$stagename"`

stage2_5=`ssh jdcupmdmseip5.entergy.com "mkdir -p /home/eip/data/meterreads/UtilityIQ414/in/stage/$stagename"`

stage2_6=`ssh jdcupmdmseip6.entergy.com "mkdir -p /home/eip/data/meterreads/UtilityIQ414/in/stage/$stagename"`

stage2_7=`ssh jdcupmdmseip7.entergy.com "mkdir -p /home/eip/data/meterreads/UtilityIQ414/in/stage/$stagename"`

echo "Created folders please check..."


}

menu_option_fifteen() {

echo ""
echo "ALERT ----------------------"

echo "This will move ALL files from IN to STAGE directory. Make sure you want to do this..."


echo ""
read -p "Press enter to continue"
echo ""



echo "Moving ALL files from IN to STAGE directory..."

IN_files1=$(mv /home/eip/data/meterreads/UtilityIQ414/in/*.xml /home/eip/data/meterreads/UtilityIQ414/in/stage/$stagename)

IN_files2=`ssh jdcupmdmseip2.entergy.com "mv /home/eip/data/meterreads/UtilityIQ414/in/*.xml /home/eip/data/meterreads/UtilityIQ414/in/stage/"`

IN_files3=`ssh jdcupmdmseip3.entergy.com "mv /home/eip/data/meterreads/UtilityIQ414/in/*.xml /home/eip/data/meterreads/UtilityIQ414/in/stage/"`

IN_files4=`ssh jdcupmdmseip4.entergy.com "mv /home/eip/data/meterreads/UtilityIQ414/in/*.xml /home/eip/data/meterreads/UtilityIQ414/in/stage/"`

IN_files5=`ssh jdcupmdmseip5.entergy.com "mv /home/eip/data/meterreads/UtilityIQ414/in/*.xml /home/eip/data/meterreads/UtilityIQ414/in/stage/"`

IN_files6=`ssh jdcupmdmseip6.entergy.com "mv /home/eip/data/meterreads/UtilityIQ414/in/*.xml /home/eip/data/meterreads/UtilityIQ414/in/stage/"`

IN_files7=`ssh jdcupmdmseip7.entergy.com "mv /home/eip/data/meterreads/UtilityIQ414/in/*.xml /home/eip/data/meterreads/UtilityIQ414/in/stage/"`

echo ""
echo "Checking files if moved..."

files1=$(ls /home/eip/data/meterreads/UtilityIQ414/in/stage/ | wc -l)

files2=`ssh jdcupmdmseip2.entergy.com "ls /home/eip/data/meterreads/UtilityIQ414/in/stage/ | wc -l"`

files3=`ssh jdcupmdmseip3.entergy.com "ls /home/eip/data/meterreads/UtilityIQ414/in/stage/ | wc -l"`

files4=`ssh jdcupmdmseip4.entergy.com "ls /home/eip/data/meterreads/UtilityIQ414/in/stage/ | wc -l"`

files5=`ssh jdcupmdmseip5.entergy.com "ls /home/eip/data/meterreads/UtilityIQ414/in/stage/ | wc -l"`

files6=`ssh jdcupmdmseip6.entergy.com "ls /home/eip/data/meterreads/UtilityIQ414/in/stage/ | wc -l"`

files7=`ssh jdcupmdmseip7.entergy.com "ls /home/eip/data/meterreads/UtilityIQ414/in/stage/ | wc -l"`

total=$(( $files1+$files2+$files3+$files4+$files5+$files6+$files7 ))

set -e

echo "STAGE Folder Monitor File Count: "
echo ""
printf "jdcupmdmseip1:\n  files $files1 \n\n"

printf "jdcupmdmseip2:\n  files $files2 \n\n"

printf "jdcupmdmseip3:\n  files $files3 \n\n"

printf "jdcupmdmseip4:\n  files $files4 \n\n"

printf "jdcupmdmseip5:\n  files $files5 \n\n"

printf "jdcupmdmseip6:\n  files $files6 \n\n"

printf "jdcupmdmseip7:\n  files $files7 \n\n\n"

printf "TOTAL Files in Stage now: $total \n"

printf ""



}

##################################################################################################################################################################################
##################################################################################################################################################################################

##################################################################################################################################################################################
##################################################################################################################################################################################

press_enter() {
  echo ""
  echo -n "	Press Enter to continue "
  read
  clear
}

incorrect_selection() {
  echo "Incorrect selection! Try again."
}

until [ "$selection" = "0" ]; do
  clear
  echo "---~~----~~~~~~~~~~~~~~~~~~~~~~~~~~~~----~~---"
  echo "---~~----EIP UI Console Version 10.8------~~---"
  echo "---~~----~~~~~~~~PRODUCTION~~~~~~~~~~----~~---"
  echo ""
  echo "    	1  -  Check Meter - BADGE_ID"
  echo "    	2  -  Check Meter - UDC_ID "
  echo "    	3  -  Check Location - LOCATION_ID"
  echo "    	4  -  MasterDataTxn ID Check - MASTERDATATXN_ID"
  echo "    	5  -  Check Flexsync Errors - (LOCATION)ID)"
  echo ""
  echo "    	6  -  END LEGACY METER" 
  echo "    	7  -  END LEGACY METER - (No Checks & will end Legacy meter & need SDP ID)" 
  echo "    	8  -  Check Flexsync - BADGE_ID (Load meters.csv file)"
  #echo "    	9  -  Check Flexsync Errors - UDC_ID (Load flexsync_error.csv file)"
  echo ""
  echo "       11  -  Check ActiveMQ Queues - DeviceReadProcessors"
  echo "	   12  -  Check ActiveMQ Queues - UtilitIQ414 Adapter Queues"
  echo "	   13  -  Check ActiveMQ Queues - DataDeliveryService Queues"
  echo ""
  echo "       10  -  Check Folder Count Across Production Servers"
  echo "       16  -  Check Stage Folder Count Across Production Servers"
  echo "       14  -  Move Files from Stage Folder to IN"
  echo "       15  -  Move files from IN to Stage"
  
  echo ""
  echo "       20 -  Check MasterDataTxn ID Payload - MasterDataTxn Id"
  echo ""
  echo "    	0  -  Exit"
  echo ""
  echo -n "  Enter selection: "
  read selection
  echo ""
  case $selection in
    1 ) clear ; menu_option_one ; press_enter ;;
    2 ) clear ; menu_option_two ; press_enter ;;
	3 ) clear ; menu_option_three ; press_enter ;;
	4 ) clear ; menu_option_four ; press_enter ;;
	5 ) clear ; menu_option_five ; press_enter ;;
	6 ) clear ; menu_option_six ; press_enter ;;
	7 ) clear ; menu_option_seven ; press_enter ;;
	8 ) clear ; menu_option_eight ; press_enter ;;
	9 ) clear ; menu_option_nine ; press_enter ;;
	10 ) clear ; menu_option_ten ; press_enter ;;
	11 ) clear ; menu_option_eleven ; press_enter ;;
	12 ) clear ; menu_option_twelve ; press_enter ;;
	13 ) clear ; menu_option_thirteen ; press_enter ;;
	14 ) clear ; menu_option_fourteen ; press_enter ;;
	15 ) clear ; menu_option_fifteen ; press_enter ;;
	16 ) clear ; menu_option_sixteen ; press_enter ;;
	
	20 ) clear ; menu_option_twenty ; press_enter ;;
    0 ) clear ; exit ;;
    * ) clear ; incorrect_selection ; press_enter ;;
  esac
done

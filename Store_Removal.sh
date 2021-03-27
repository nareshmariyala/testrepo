#!/usr/bin/env bash

##########################################################################################
#
# Created by:		TOPSI-TAVHAL team, Capgemini INDIA
# Title:			Store removal from Martti
# Description:		Removing a store from Martti tables upon customer request  
#			
# Input arguments:	Martti Id
# Output:			Messages on stdout
# Exit values:		0 - Success
#                   	1 - Database connection failure
#			2 - Error in SQL 
#			           
# DB Reference:	   Database(s) - TUHTITUO 
#					
# DB Changes:		Updates and Deletes
#			
# Job Dependency:	None
# Arguments: 		INCC Number, MormaID, StoreID, OutletName
#
# Version History:
#
#	1.0	11-May-2017	Abhirup Mukherjee	First version
#	1.1 	26-Oct-2018 	Kartikey Agarwal	Detect COOP deletion
#							Removed argument passing
#	1.2	03-jun-2019	Naresh Mariyala		Modifications for Python Scripts
#				Dhruv Mistry		
#
##########################################################################################
echo -e "\e[31m******* ACCT Enviorment | Store Removal *******\e[0m"

#Connect to TUHTITUO database
. /tuhti/finp/era/ymparisto64.sh 2>> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt


if [[ $? -ne 0 ]]; then
echo "Unable to establish database connection...." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt 
exit 1
fi
echo "Connected to TUHTIKON database.." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt

#Check the Store Name if Correct or Not
outletName=`db2 -x "SELECT NIMI FROM MARTTI.ORGANISAATIO where TUNNISTE = '$3' with ur"`

if [[ $outletName = *"$4"* ]];
then
	echo "Store Name is matching with Outlet Name" >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
else
	echo "Outlet Name in ITSM and Database Does Not Match for Given outletID" >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
	exit 1
fi

echo "Parameters passed in Store Removal Unix Script are as: '$*'"

#Get the MARTTIID
marttiId=`db2 -x "SELECT MARTTIID FROM MARTTI.ORGANISAATIO where MORMAID = $2 and  TUNNISTE = '$3' with ur"` 

echo "Martti id to be removed :  $marttiId" >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt


#Check if the store is COOP
grep -w -c "$2" /hahome/tuhtiadm/TOPSI_routine/SSR_Automation/CoopID.txt >/dev/null

if [ $? -eq 0 ] 
then
	echo -e "\e[31mAborting Script! Morma ID is of COOP \e[0m" >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
	exit
fi


#Redirects to Backup Script
/hahome/tuhtiadm/TOPSI_routine/SSR_Automation/SSR_17_Bak.sh $1 $marttiId

if [[ $? -ne 0 ]]; then
	echo "Backup was not Successful" 1>&2 >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
	exit 1
fi

echo "Backup Completed OK" >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
echo "Beginning removal of store" >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt


# Update MARTTI.ORGANISAATIO table

db2 -x "update MARTTI.ORGANISAATIO set TILAUSOIKEUS = '0', MENEKKI = '0' where marttiid like '$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while updating MARTTI.ORGANISAATIO table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi

# Delete from martti.mantilausrivi table

db2 -x "delete from martti.mantilausrivi where tilausriviid in (select tilausriviid from martti.tilausrivi where marttikyid='$marttiId')"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from martti.mantilausrivi table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi

# Delete from MARTTI.TILAUSRIVI table

db2 -x "delete from MARTTI.TILAUSRIVI a where a.MARTTIKYID = '$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from MARTTI.TILAUSRIVI table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi

# Delete from MARTTI.TILAUSKORTTI
db2 -x "delete from MARTTI.TILAUSKORTTI a where a.MARTTIKYID = '$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from MARTTI.TILAUSKORTTI table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi

# Delete from MARTTI.POIKKEAVATILAUSMAARA
db2 -x "delete from MARTTI.POIKKEAVATILAUSMAARA a where a.MARTTIKYID = '$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from MARTTI.POIKKEAVATILAUSMAARA table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi


# Delete from MARTTI.TILAUSKORTTITIPI
db2 -x "delete from MARTTI.TILAUSKORTTITIPI a where a.MARTTIKYID = '$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from MARTTI.TILAUSKORTTITIPI table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi

# Delete from MARTTI.TUOTTEENTILAUSTAPA
db2 -x "delete from MARTTI.TUOTTEENTILAUSTAPA a where a.MARTTIKYID = '$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from MARTTI.TUOTTEENTILAUSTAPA table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi

# Delete from martti.orgliittyma
db2 -x "delete from martti.orgliittyma a where a.MARTTIID = '$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from martti.orgliittyma table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi

# Delete from martti.ketjuyksikko
db2 -x "delete from martti.ketjuyksikko a where a.KYTUNNISTE = '$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from martti.ketjuyksikko table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi

# Delete from martti.MANTILAUSOTSIKKO
db2 -x "delete from martti.MANTILAUSOTSIKKO where marttikyid='$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from MARTTI.MANTILAUSOTSIKKO table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi


# Delete from martti.tilausvalikoima1
db2 -x "delete from martti.tilausvalikoima1 where marttikyid='$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from martti.tilausvalikoima1 table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi

# Delete from martti.tilausvalikoima2
db2 -x "delete from martti.tilausvalikoima2 where marttikyid='$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from martti.tilausvalikoima2 table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi


# Delete from martti.tilausvalikoima
db2 -x "delete from martti.tilausvalikoima where marttikyid='$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from martti.tilausvalikoima table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi

# Delete from martti.varastotapahtuma
db2 -x "delete from martti.varastotapahtuma where marttikyid='$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from martti.varastotapahtuma table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi

# Delete from martti.MENEKINVIIKKOPROFIILI
db2 -x "delete from martti.MENEKINVIIKKOPROFIILI where marttikyid='$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from MARTTI.MENEKINVIIKKOPROFIILI table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi

# Delete from martti.TOIMITUSKALENTERIOTSIKKO
db2 -x "delete from martti.TOIMITUSKALENTERIOTSIKKO where marttiorgid='$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from MARTTI.TOIMITUSKALENTERIOTSIKKO table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi

# Determine which martti.SEKAPAKKAUSTILAUSVALIKOIMA view to be used

db2 -x "select marttikyid from martti.SEKAPAKKAUSTILAUSVALIKOIMA1 fetch first 5 rows only"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 1 ]]; then

db2 -x "delete from martti.SEKAPAKKAUSTILAUSVALIKOIMA2 where marttikyid='$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from MARTTI.SEKAPAKKAUSTILAUSVALIKOIMA2 table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi

else 

db2 -x "delete from martti.SEKAPAKKAUSTILAUSVALIKOIMA1 where marttikyid='$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from MARTTI.SEKAPAKKAUSTILAUSVALIKOIMA1 table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi

fi

# Delete from martti.KALENTERIRYHMAKY
db2 -x "delete from martti.KALENTERIRYHMAKY where marttikyid='$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from MARTTI.KALENTERIRYHMAKY table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi

# Delete from martti.TOIMITUSAINEISTOOTSIKKO
db2 -x "delete from martti.TOIMITUSAINEISTOOTSIKKO where marttikyid='$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from MARTTI.TOIMITUSAINEISTOOTSIKKO table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi

# Delete from martti.SOVELLUSPOIKKEUS
db2 -x "delete from martti.SOVELLUSPOIKKEUS where marttiorgid='$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from MARTTI.SOVELLUSPOIKKEUS table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi

# Delete from martti.HALUTTUTOIMITUSPAIVA
db2 -x "delete from martti.HALUTTUTOIMITUSPAIVA where kytunniste='$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from MARTTI.HALUTTUTOIMITUSPAIVA table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi

# Delete from martti.SALDOTARKASTUSSUUNNITELMA
db2 -x "delete from martti.SALDOTARKASTUSSUUNNITELMA where MARTTIKYID='$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from MARTTI.SALDOTARKASTUSSUUNNITELMA table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi


# Delete from martti.saldotapahtuma
db2 -x "delete from martti.saldotapahtuma where kytunniste='$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from MARTTI.saldotapahtuma table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi

# Delete from martti.TUOTESALDO
db2 -x "delete from martti.TUOTESALDO where kytunniste='$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from MARTTI.TUOTESALDO table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi


# Delete from martti.organisaatio
db2 -x "delete from martti.organisaatio a where a.MARTTIID = '$marttiId'"
EXIT_STATUS=$?

if [[ $EXIT_STATUS -eq 4 || $EXIT_STATUS -eq 8 ]]; then
echo "Error occured while deleting rows from martti.organisaatio table..." >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt
exit 2
fi

echo "Store with martti id $marttiId has been successfully removed from all relevant tables in MARTTI PROD" | mailx -s "Store successfully deleted from Martti PROD" "topsi_pria.in@capgemini.com"
echo "Store removal completed successfully: Ending Script" >> /hahome/tuhtiadm/TOPSI_routine/store_removal_log.txt

exit 0

#!/bin/csh

#################################
### WRITTEN BY ROOPESH SAXENA ###
### LAST UPDATED 05/26/2020   ###
#################################

if ($1 == '-help' || $#argv != 1) then
  echo "Function: Process ISO test data files to properly read in Visual-Viewer."
  echo "For NHTSA tests, download as NHTSA ISO_MME format."
  echo "Usage: $0:t [ISO test id]"
  exit
endif

set testid = $1

if (`/bin/ls -1 $testid.??? |& grep -v 'No match' | wc -l` == 0) then
  echo "ERROR: No files found with specified ISO test id."
  exit
endif

# ------------------------------ MANUALLY EDIT PARAMETERS IN THIS BLOCK (START) ------------------------------
set LineLabelContainingChannelCodeInIndivChFile = "Location          "
# ------------------------------ MANUALLY EDIT PARAMETERS IN THIS BLOCK (END) ------------------------------

set fileprefix = "RSISO"
set newfileroot = {$fileprefix}_{$testid}
set newchnfile = {$newfileroot}.chn

if (`/bin/ls -1 -d {$newfileroot}.* |& grep -v "No match" | wc -l` > 0) then
  echo "File(s) already exist containing $newfileroot in name. Delete them before continuing."
  exit
endif

touch $newchnfile
echo "Title                       :"$fileprefix >> $newchnfile
echo "Number of channels          :ReplaceCountLater" >> $newchnfile

set allfiles = `/bin/ls -1 $testid.???`
set filenum = 0
foreach infile ($allfiles)
  echo "Processing file ... "$infile

# 'dos2unix' command is not installed anymore in newer version of Red Hat Linux, so its functionality is replaced with 'tr' command below.
#  (dos2unix $infile) >& /dev/null
  (/bin/rm -f $infile.dos2unix.tmp; tr -d '\r' < $infile > $infile.dos2unix.tmp ; mv -f $infile.dos2unix.tmp $infile; chmod 400 $infile) >& /dev/null

  set outfile = {$fileprefix}_{$infile}
  if (`grep -c $LineLabelContainingChannelCodeInIndivChFile $infile` == 1) then

#   Channel codes sometimes have "?" in them, replacing them with "x" so as not to cause problems.
    set chcode = `awk -F\: -v LineLabelContainingChannelCodeInIndivChFile=$LineLabelContainingChannelCodeInIndivChFile '{if ($0 ~ LineLabelContainingChannelCodeInIndivChFile) print $2}' $infile | sed s/"\?"/"x"/g`
    set chfileext = `echo $infile:e`
    set uniquechcode = $chcode"_"$chfileext

    (cp $infile $outfile; chmod 777 $outfile)
    (mv $outfile $outfile.tmp; awk -v uniquechcode=$uniquechcode '{if ($0 ~ "Channel code *:") sub(/:.*$/,":"uniquechcode); print}' $outfile.tmp > $outfile; /bin/rm $outfile.tmp)
    (mv $outfile $outfile.tmp; awk -v uniquechcode=$uniquechcode '{if ($0 ~ "Name of the channel *:") sub(/:.*$/,":"uniquechcode); print}' $outfile.tmp > $outfile; /bin/rm $outfile.tmp)
    (mv $outfile $outfile.tmp; awk -v uniquechcode=$uniquechcode '{if ($0 ~ "Location *:") sub(/:.*$/,":"uniquechcode); print}' $outfile.tmp > $outfile; /bin/rm $outfile.tmp)
    echo "Name of channel "$chfileext"         :"$uniquechcode >> $newchnfile
    @ filenum ++
  endif
end

(mv $newchnfile $newchnfile.tmp; awk -v filenum=$filenum '{if ($0 ~ "^Number of channels *:") sub(/:.*$/,":"filenum); print}' $newchnfile.tmp > $newchnfile; /bin/rm $newchnfile.tmp)

# Below block is obsolete since I added unique channel code in above block itself.
#set lineno = 1
#set nooflines = `wc -l $newchnfile | awk '{print $1}'`
#while ($lineno <= $nooflines)
#  if (`awk -v lineno=$lineno '{if ((FNR == lineno) && ($0 ~ "Name of channel ")) printf FNR}' $newchnfile` > 0) then
#    set oldchnum = `awk -v lineno=$lineno '{if (FNR==lineno) print $4}' $newchnfile`
#    set oldchcode = `awk -v lineno=$lineno '{if (FNR==lineno) print $5}' $newchnfile | sed s/"\:"/""/g`
#    set newchcode = $oldchcode"_"$oldchnum
#    if (`grep -c $oldchcode $newchnfile` > 1) then
#      (mv $newchnfile $newchnfile.tmp; awk -v lineno=$lineno -v oldchcode=$oldchcode -v newchcode=$newchcode '{if ((FNR==lineno) && ($0 ~ oldchcode)) sub(oldchcode,newchcode); print}' $newchnfile.tmp > $newchnfile; /bin/rm $newchnfile.tmp)
#      (mv $newfileroot.$oldchnum $newfileroot.$oldchnum.tmp; awk -v oldchcode=$oldchcode -v newchcode=$newchcode '{if ($0 ~ oldchcode) sub(oldchcode,newchcode); print}' $newfileroot.$oldchnum.tmp > $newfileroot.$oldchnum; /bin/rm $newfileroot.$oldchnum.tmp)
#    endif
#  endif
#  @ lineno ++
#end

chmod 400 $newfileroot.*


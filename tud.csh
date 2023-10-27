#!/bin/csh

#################################
### WRITTEN BY ROOPESH SAXENA ###
### LAST UPDATED 12/16/2016   ###
#################################

if ($1 == '-help' || $#argv != 1) then
  echo "Function: Create user directory for given CPG test."
  echo "Usage: $0:t [CPG test id]"
  exit
endif

set testdir = `echo $1 | sed s/"\/"/""/g`
set filetolookin = "*.LET.LETTER.TXT"
set userdirname = ""
if (!(-f $testdir/$filetolookin)) then
  echo "ERROR: $testdir/$filetolookin file not found."
  exit
endif

# Test id.
if (`echo $testdir | cut -c 1-2` == "IS") then
  set testidlinenum = `awk '{if (($0 ~ "KPH" || $0 ~ "MPH") && ($0 ~ "REQST")) print FNR}' $testdir/$filetolookin | head -1`
else if(`echo $testdir | cut -c 1-2` == "VC") then
  set testidlinenum = `awk '{if (($0 ~ "KPH" || $0 ~ "MPH") && ($0 ~ "ITEM")) print FNR}' $testdir/$filetolookin | head -1`
endif
set testid = `awk -v testidlinenum=$testidlinenum '{if (FNR==testidlinenum) print $1}' $testdir/$filetolookin`
if ($testid != "") then
  set userdirname = $testid
endif

# Program.
if (`echo $testid | cut -c 1-2` == "IS") then
  set programid = `awk -v testidlinenum=$testidlinenum -F" " '{if (FNR==(testidlinenum)) print $2}' $testdir/$filetolookin | sed s/" "/""/g`
else if (`echo $testid | cut -c 1-2` == "VC") then
  set programid = `awk -v testidlinenum=$testidlinenum -F\, '{if (FNR==(testidlinenum+1)) print $1}' $testdir/$filetolookin | sed s/" "/""/g`
else
  set programid = ""
endif
echo -n "Program id in file [$programid]: "
set programidinprompt = $<
if ($programidinprompt != "") then
  set programid = $programidinprompt
endif
if ($programid != "") then
  set userdirname = {$userdirname}_$programid
endif

# Test date.
set testdateraw = `awk -v testidlinenum=$testidlinenum '{if (FNR==(testidlinenum+2)) print $3}' $testdir/$filetolookin | sed s/" "/""/g`
set testdatemon = `echo $testdateraw | awk -F\/ '{print $1}'`
set testdateday = `echo $testdateraw | awk -F\/ '{print $2}'`
set testdateyear = `echo $testdateraw | awk -F\/ '{print $3}'`
set testdate = "$testdateyear$testdatemon$testdateday"
echo -n "Test date (yymmdd) in file [$testdate]: "
set testdateinprompt = $<
if ($testdateinprompt != "") then
  set testdate = $testdateinprompt
endif
if ($testdate != "") then
  set userdirname = {$userdirname}_$testdate
endif

# Test speed.
set testspeed = ""
if (`echo $testid | cut -c 1-2` == "IS") then
  set testspeedvalue = `awk -v testidlinenum=$testidlinenum '{if (FNR==(testidlinenum)) print $3}' $testdir/$filetolookin | sed s/" "/""/g`
  set testspeedunits = `awk -v testidlinenum=$testidlinenum '{if (FNR==(testidlinenum)) print $4}' $testdir/$filetolookin | sed s/" "/""/g`
else if (`echo $testid | cut -c 1-2` == "VC") then
  set testspeedvalue = `awk -v testidlinenum=$testidlinenum '{if (FNR==(testidlinenum)) print $2}' $testdir/$filetolookin | sed s/" "/""/g`
  set testspeedunits = `awk -v testidlinenum=$testidlinenum '{if (FNR==(testidlinenum)) print $3}' $testdir/$filetolookin | sed s/" "/""/g`
endif
if ($testspeedunits == "KPH") then
  set testspeedvalue = `echo $testspeedvalue | awk '{print ($testspeedvalue/1.609344)}'`
  set testspeedunits = "MPH"
endif
set testspeedrange = 0.5
if ($testspeed == "") then
  set testspeed = `echo $testspeedvalue | awk -v target=20 -v testspeedrange=$testspeedrange '{if ($1>(target-testspeedrange) && $1<(target+testspeedrange)) print target}'`
endif
if ($testspeed == "") then
  set testspeed = `echo $testspeedvalue | awk -v target=25 -v testspeedrange=$testspeedrange '{if ($1>(target-testspeedrange) && $1<(target+testspeedrange)) print target}'`
endif
if ($testspeed == "") then
  set testspeed = `echo $testspeedvalue | awk -v target=30 -v testspeedrange=$testspeedrange '{if ($1>(target-testspeedrange) && $1<(target+testspeedrange)) print target}'`
endif
if ($testspeed == "") then
  set testspeed = `echo $testspeedvalue | awk -v target=31 -v testspeedrange=$testspeedrange '{if ($1>(target-testspeedrange) && $1<(target+testspeedrange)) print target}'`
endif
if ($testspeed == "") then
  set testspeed = `echo $testspeedvalue | awk -v target=35 -v testspeedrange=$testspeedrange '{if ($1>(target-testspeedrange) && $1<(target+testspeedrange)) print target}'`
endif
if ($testspeed == "") then
  set testspeed = `echo $testspeedvalue | awk -v target=40 -v testspeedrange=$testspeedrange '{if ($1>(target-testspeedrange) && $1<(target+testspeedrange)) print target}'`
endif
if ($testspeed == "") then
  set testspeed = "x"
endif
echo -n "Test speed (mph) in file [$testspeed]: "
set testspeedinprompt = $<
if ($testspeedinprompt != "") then
  set testspeed = $testspeedinprompt
endif
if ($testspeed != "") then
  set userdirname = {$userdirname}_$testspeed
endif

# Impact type.
set impacttype = ""
set impacttyperaw = `awk -F\; '{if ($0~"BARRIER TYPE") print $2}' $testdir/$filetolookin`
if ($impacttype == "") then
  set impacttype = `echo $impacttyperaw | awk '{if ($0~"FLAT FIXED") print "FF"}'`
endif
if ($impacttype == "") then
  set impacttype = `echo $impacttyperaw | awk '{if ($0~"LEFT 30 DEG") print "LA"}'`
endif
if ($impacttype == "") then
  set impacttype = `echo $impacttyperaw | awk '{if ($0~"RIGHT 30 DEG") print "RA"}'`
endif
if ($impacttype == "") then
  set impacttype = `echo $impacttyperaw | awk '{if ($0~"OFFSET IIHS") print "ODB"}'`
endif
if ($impacttype == "") then
  set impacttype = `echo $impacttyperaw | awk '{if ($0~"OFFSET ECE") print "ODB"}'`
endif
if ($impacttype == "") then
  set impacttype = `echo $impacttyperaw | awk '{if ($0~"OFFSET EU NCAP") print "ODB"}'`
endif
if ($impacttype == "") then
  set impacttype = `echo $impacttyperaw | awk '{if ($0~"25 ROB") print "SORB"}'`
endif
if ($impacttype == "") then
  set impacttype = `echo $impacttyperaw | awk '{if ($0~"MPDB") print "MPDB"}'`
endif
if ($impacttype == "") then
  set impacttype = "x"
endif
echo -n "Impact type in file [$impacttype]: "
set impacttypeinprompt = $<
if ($impacttypeinprompt != "") then
  set impacttype = $impacttypeinprompt
endif
if ($impacttype != "") then
  set userdirname = {$userdirname}$impacttype
endif

# Occupants.
set occlist = "1L 1R 2L 2R"
foreach occ ($occlist)
  set line = `awk -v occ=$occ '/OCCUPANTS/,/^$/ {if ($0 ~ occ) print}' $testdir/$filetolookin`
  if (`echo "$line" | grep -v ' 0 - CH ' | grep -c -i "5TH FEMALE"` > 0) then
    set occtxt = {$occ}"5th"
  else if (`echo "$line" | grep -v ' 0 - CH ' | grep -c -i "50TH MALE"` > 0) then
    set occtxt = {$occ}"50th"
  else if (`echo "$line" | grep -v ' 0 - CH ' | grep -c -i "95TH MALE"` > 0) then
    set occtxt = {$occ}"95th"
  else if (`echo "$line" | grep -v ' 0 - CH ' | grep -c -i "P 18 MONTH"` > 0) then
    set occtxt = {$occ}"P1.5"
  else if (`echo "$line" | grep -v ' 0 - CH ' | grep -c -i "P 3 YEAR"` > 0) then
    set occtxt = {$occ}"P3"
  else if (`echo "$line" | grep -v ' 0 - CH ' | grep -c -i "Q 1 1/2 YEAR"` > 0) then
    set occtxt = {$occ}"Q1.5"
  else if (`echo "$line" | grep -v ' 0 - CH ' | grep -c -i "Q 3 YEAR"` > 0) then
    set occtxt = {$occ}"Q3"
  else if (`echo "$line" | grep -v ' 0 - CH ' | grep -c -i "Q 6 YEAR"` > 0) then
    set occtxt = {$occ}"Q6"
  else if (`echo "$line" | grep -v ' 0 - CH ' | grep -c -i "Q 10 YEAR"` > 0) then
    set occtxt = {$occ}"Q10"
  else if (`echo "$line" | grep -v ' 0 - CH ' | grep -c -i "THOR 50TH"` > 0) then
    set occtxt = {$occ}"Thor"
  else
    set occtxt = ""
  endif
  echo -n "Occ" $occ "in file [$occtxt]: "
  set occprompt = $<
  if ($occprompt != "") then
    set occtxt = $occprompt
  endif
  if ($occtxt != "") then
    set userdirname = {$userdirname}_{$occtxt}
  endif
end

# Directory name will be.
echo -n "Directory name will be: "
echo {$userdirname}"_<usercomments>_dir"

# User comments.
echo -n "User comments: "
set usercomments = $<
if ($usercomments != "") then
  set userdirname = {$userdirname}_$usercomments
endif

# Create dir.
set userdirname = {$userdirname}_dir
echo -n "Create directory [$userdirname]: "
set userdirnameinprompt = $<
if ($userdirnameinprompt != "") then
  set userdirname = $userdirnameinprompt
endif
mkdir $userdirname


#!/bin/bash
# Usage:
# bash /path/to/fourtwenty-utils/g420up.sh <datadir> <instance_name>

root=$1  # base directory to use for datadir and logs
shift
dd=$1  # double digit instance id like 00 01 02
shift


# logs are output to a date-tagged file for each run , while a link is
# created to the latest, so that monitoring be easier with the same filename
# TODO: use this if G420 not set
# G420=g420

# g420 CLI params       e.g., (dd=04, run=09)
datetag=`date "+%c%y%m%d-%H%M%S"|cut -d ' ' -f 5`
datadir=$root/data/$dd             # /tmp/fourtwenty/04
log=$root/log/$dd.$datetag.log     # /tmp/fourtwenty/04.09.log
linklog=$root/log/$dd.current.log  # /tmp/fourtwenty/04.09.log
stablelog=$root/log/$dd.log        # /tmp/fourtwenty/04.09.log
password=$dd             # 04
port=130$dd              # 13000
rpcport=61$dd            # 6100

mkdir -p $root/data
mkdir -p $root/log
ln -sf "$log" "$linklog"
# if we do not have an account, create one
# will not prompt for password, we use the double digit instance id as passwd
# NEVER EVER USE THESE ACCOUNTS FOR INTERACTING WITH A LIVE CHAIN
if [ ! -d "$root/keystore/$dd" ]; then
  echo create an account with password $dd [DO NOT EVER USE THIS ON LIVE]
  mkdir -p $root/keystore/$dd
  $G420 --datadir $datadir --password <(echo -n $dd) account new
# create account with password 00, 01, ...
  # note that the account key will be stored also separately outside
  # datadir
  # this way you can safely clear the data directory and still keep your key
  # under `<rootdir>/keystore/dd

  cp -R "$datadir/keystore" $root/keystore/$dd
fi

# echo "copying keys $root/keystore/$dd $datadir/keystore"
# ls $root/keystore/$dd/keystore/ $datadir/keystore

# mkdir -p $datadir/keystore
# if [ ! -d "$datadir/keystore" ]; then
echo "copying keys $root/keystore/$dd $datadir/keystore"
cp -R $root/keystore/$dd/keystore/ $datadir/keystore/
# fi

BZZKEY=`$G420 --datadir=$datadir account list|head -n1|perl -ne '/([a-f0-9]{40})/ && print $1'`

# bring up node `dd` (double digit)
# - using <rootdir>/<dd>
# - listening on port 130dd, (like 13000, 13001, ...)
# - with the account unlocked
# - launching json-rpc server on port 61dd (like 6100, 6101, 6102, ...)
echo "$G420 --datadir=$datadir \
  --identity="$dd" \
  --bzzaccount=$BZZKEY --bzzport=86$dd \
  --port=$port \
  --unlock=$BZZKEY \
  --password=<(echo -n $dd) \
  --rpc --rpcport=$rpcport --rpccorsdomain='*' $* \
  2>&1 | tee "$stablelog" > "$log" &  # comment out if you pipe it to a tty etc.
"

$G420 --datadir=$datadir \
  --identity="$dd" \
  --bzzaccount=$BZZKEY --bzzport=86$dd \
  --port=$port \
  --unlock=$BZZKEY \
  --password=<(echo -n $dd) \
  --rpc --rpcport=$rpcport --rpccorsdomain='*' $* \
   2>&1 | tee "$stablelog" > "$log" &  # comment out if you pipe it to a tty etc.

# to bring up logs, uncomment
# tail -f $log

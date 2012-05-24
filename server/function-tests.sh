#!/bin/bash

TEST="../cmd-client/cross-copy -q -l"

report(){
  
  echo "$@ in line" `caller 1`
}

assertEqual(){
  [[ $1 == $2 ]] || ( report "$3 (expected '$1' but was '$2')" && echo FAIL && exit 1 )
}

##### FUNCTION TESTS

DEVICE_ID_1=`uuidgen`
DEVICE_ID_2=`uuidgen`
DATA="the message"
SECRET=`uuidgen`

function testSimpleTransfer(){
  echo $FUNCNAME
  ( M=`$TEST $SECRET`; assertEqual "$DATA" "$M" "should receive correct message" ) &
  sleep 1
  R=`$TEST $SECRET "$DATA"`
  assertEqual 1 $R "shoud have one direct delivery"
  SECRET=`uuidgen`
  wait
}

function testFetchingRecentPaste(){
  echo $FUNCNAME
  R=`$TEST $SECRET "$DATA"`
  assertEqual 0 $R "shoud have no direct deliverys"
  R=`$TEST -r $SECRET | grep -Po '"data":.*?[^\\\\]",'`
  assertEqual '"data":"the message",' "$R" "should get recently stored data"
  SECRET=`uuidgen`
}

function testFetchingTwoRecentPastes(){
  echo $FUNCNAME
  R=`$TEST -k 2 $SECRET "1"`
  R=`$TEST -k 1 $SECRET "2"`
  R=`$TEST -r $SECRET | grep -Po '"data":.*?[^\\\\]",'`
  assertEqual '"data":"1",
"data":"2",' "$R" "should get both messages"
  sleep 1
  R=`$TEST -r $SECRET | grep -Po '"data":.*?[^\\\\]",'`
  assertEqual '"data":"1",' "$R" "second message should have been kept for only a second"
  sleep 1
  R=`$TEST -r $SECRET | grep -Po '"data":.*?[^\\\\]",'`
  assertEqual '' "$R" "first message should have been kept for only two seconds"
  SECRET=`uuidgen`
}

function testFetchingRecentPasteInJsonFormatWithDeviceId(){
  echo $FUNCNAME
  R=`$TEST -d $DEVICE_ID_1 $SECRET "$DATA"`
  assertEqual 0 $R "shoud have no direct deliverys"
  R=`$TEST -j -d $DEVICE_ID_2 $SECRET | grep -Po '"data":.*?[^\\\\]",'`
  assertEqual '"data":"the message",' "$R" "should get recently stored data"
  SECRET=`uuidgen`
}

#testSimpleTransfer
#testFetchingRecentPaste
#testFetchingTwoRecentPastes
testFetchingRecentPasteInJsonFormatWithDeviceId
echo "SUCSESS"

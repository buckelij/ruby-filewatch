#!/bin/bash
SHAREA=//orion/c\$/a
SHAREB=//dvd-burner02/c\$/b
USER=erb
DOMAIN=thejockeyclub
#export PASSWORD=
SINCEDB_PATH=/tmp/sincedb.testing2013
export SINCEDB_PATH
MYROOT=`pwd`

mkdir -p ./mnt/a
mkdir -p ./mnt/b
pkill -f /usr/bin/ruby.*test.rb
export RUBYLIB="./lib/"

##TEST1
#writes in the last 10 seconds (:sincedb_write_interval) are re-printed on startup
echo "TEST 1:  loses position on shutdown when no writes after next tick of :sincedb_write_interval":
rm -f $SINCEDB_PATH
umount ./mnt/a ; umount ./mnt/b
mount.cifs $SHAREA ./mnt/a -o user=$USER,domain=$DOMAIN
mount.cifs $SHAREB ./mnt/b -o user=$USER,domain=$DOMAIN

cat <<EOF >test.rb
require "rubygems"
require "filewatch/tail"
t = FileWatch::Tail.new
t.tail("$MYROOT/mnt/*/*.txt")
t.subscribe do |path, line|
  puts "#{path}: #{line}"
end
EOF

echo a > ./mnt/a/1a.txt ; echo b > ./mnt/b/1b.txt
ruby ./test.rb &
sleep 5
echo aa >> ./mnt/a/1a.txt ; sleep 5
echo bb >> ./mnt/b/1b.txt ; sleep 5
echo bbb >> ./mnt/b/1b.txt ; sleep 5
echo aaa >> ./mnt/a/1a.txt ; sleep 5
sleep 15 
pkill -f /usr/bin/ruby.*test.rb
cat $SINCEDB_PATH | sed 's/^/    /'

echo "restarting tail with no file changes (should be no output)"
sleep 5 ; ruby ./test.rb &
sleep 5
pkill -f /usr/bin/ruby.*test.rb
cat $SINCEDB_PATH | sed 's/^/    /'

echo "restarting tail with no file changes (should be no output)"
sleep 5 ; ruby ./test.rb &
sleep 5
pkill -f /usr/bin/ruby.*test.rb
cat $SINCEDB_PATH | sed 's/^/    /'

echo "TEST 1: DONE"


##TEST2
echo "TEST 2: remounting results in missing lines"
#Because major/minor of inode changes depending on mount order of different servers
rm -f $SINCEDB_PATH
umount ./mnt/a ; umount ./mnt/b
mount.cifs $SHAREA ./mnt/a -o user=$USER,domain=$DOMAIN
mount.cifs $SHAREB ./mnt/b -o user=$USER,domain=$DOMAIN
cat <<EOF >test.rb
require "rubygems"
require "filewatch/tail"
t = FileWatch::Tail.new
t.tail("$MYROOT/mnt/*/*.txt")
t.subscribe do |path, line|
  puts "#{path}: #{line}"
end
EOF

echo a > ./mnt/a/1a.txt ; echo b > ./mnt/b/1b.txt
ruby ./test.rb &
sleep 5
echo aa >> ./mnt/a/1a.txt ; sleep 5
echo bb >> ./mnt/b/1b.txt ; sleep 5
echo bbb >> ./mnt/b/1b.txt ; sleep 5
echo aaa >> ./mnt/a/1a.txt ; sleep 5
sleep 15 
pkill -f /usr/bin/ruby.*test.rb
cat $SINCEDB_PATH | sed 's/^/    /'

echo "restarting tail with no file changes (should be no output)"
sleep 5 ; ruby ./test.rb &
sleep 5
pkill -f /usr/bin/ruby.*test.rb
cat $SINCEDB_PATH | sed 's/^/    /' 

echo "restarting tail after remounting in different order, with file changes"
umount ./mnt/a ; umount ./mnt/b
mount.cifs $SHAREB ./mnt/b -o user=$USER,domain=$DOMAIN
mount.cifs $SHAREA ./mnt/a -o user=$USER,domain=$DOMAIN
echo REMOUNTED >> ./mnt/b/1b.txt
sleep 5 ; ruby ./test.rb &
sleep 5
pkill -f /usr/bin/ruby.*test.rb
cat $SINCEDB_PATH | sed 's/^/    /'

echo "TEST 2: DONE"

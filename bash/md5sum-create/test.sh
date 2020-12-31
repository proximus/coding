#===============================================================================
#
#         FILE: test.sh
#
#        USAGE: ---
#
#  DESCRIPTION: ---
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#  ORIG AUTHOR: Samuel Gabrielsson <samuel.gabrielsson@gmail.com>
# ORGANIZATION: ---
#      VERSION: 1.0
#      CREATED: 2020-07-06 00:23:30
#     REVISION: ---
#      CHANGES: ---
#
#===============================================================================
rm -rf Test/
cp -r Test-backup Test
./md5sum-create Test/ -vv

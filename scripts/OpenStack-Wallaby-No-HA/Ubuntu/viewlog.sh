
#!/bin/bash
# rapid CLI oneliner log inspection inside all log files
# Lookig for keywords "fail", "error", "unable", "warning".
# Ref: https://raw.githubusercontent.com/AJNOURI/COA/master/misc/oneliner_log_inspection.sh
#################################################### GUIDE####################
# Go lenh  voi cac tu khoa ERORR hoac FAIL hoac thay bang tu ban muon
# bash viewlog.sh ERROR
# bash viewlog.sh "ERROR|FAIL"
##############################################################################
for i in $(ls /var/log/*/*.log); do echo "=========="; echo $i; echo "========="; tail $i| egrep -i $1; done

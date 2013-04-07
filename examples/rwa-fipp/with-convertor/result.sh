#!/bin/sh
ls out/*.out| sort | xargs grep -H -T -e "WITH-INTOBJ" | awk -F ':' '{print $1 "  " $3}' > INTOBJ.ret 
ls out/*.out| sort | xargs grep -H -T -e "WITH-WORKING" | awk -F ':' '{print $1 "  " $3}' > WORKING.ret 
ls out/*.out| sort | xargs grep -H -T -e "WITH-GAP" | awk -F ':' '{print $1 "  " $3}' > GAP.ret 
ls out/*.out| sort | xargs grep -H -T -e "OVERALL-RUNTIME" | awk -F ':' '{print $1 "  " $3}' > RUNTIME.ret 
ls out/*.out| sort | xargs grep -H -T -e "WITH-USED-CONFIGS" | awk -F ':' '{print $1 "  " $3}' > NCONFIG.ret 


join  INTOBJ.ret WORKING.ret | join - GAP.ret | join - RUNTIME.ret | join - NCONFIG.ret > result.ret 


less result.ret | awk -F ' ' 'BEGIN{}{ print $1 " " $3 " " sprintf("%5.2f",$5/$3*100.0) " " $7 " " strftime("%Hh:%Mm:%Ss", $9,1) " " $11 }'

rm *.ret

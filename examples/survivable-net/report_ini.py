import os
import ConfigParser
import glob
from prettytable import PrettyTable
import re


inputdir  = "ini/N*s[2,3,4,5]*.ini"
inputdir  = "ini/NSF*s1*.ini"

#inputdir  = "ini/24NET-s1*.ini"

#inputdir  = "ini/E*s1*.ini"
#inputdir  = "ini/24NET-s*e90*.ini"
#inputdir  = "ini/24NET-hs*e120*.ini"

def atoi(text):
    return int(text) if text.isdigit() else text

def natural_keys(text):
    '''
    alist.sort(key=natural_keys) sorts in human order
    http://nedbatchelder.com/blog/200712/human_sorting.html
    (See Toothy's implementation in the comments)
    '''
    return [ atoi(c) for c in re.split('(\d+)', text) ]



if __name__ == "__main__" :


    print "REPORT"

    tableII  = PrettyTable( ["INSTANCE" , "GEN-CONFIG" , "SEL-CONFIG" , "ZILP" , "GAP" , "MEAN" , "STD" ] )
    tableIII = PrettyTable( ["INSTANCE" , "N-ISSUES" , "Fail-P-Link" , "ADD-ROUTE" , "ADD-PROTECT1" , "Ratio1" , "ADD-PROTECT2" , "Ratio2" ] )


    listFile = glob.glob( inputdir )

    for inifile in sorted( listFile , key = natural_keys ):
	
        print "analyzing " , inifile 	

        config = ConfigParser.ConfigParser()
        config.read( inifile )

        llink    = float( config.get("INPUT", "LLINK"))
        nconnect = "%.1f" % ( 100 * float( config.get("RESERVE","NCONNECT-ISSUES" )) / llink )

        nconfiggen = config.get("COLUMN","CONFIG-GEN" )
        nconfigsel = config.get("COLUMN","CONFIG-SEL" )

    
#        maxfl = float( config.get("PROTECTION","MAX-PROTECT-FL" ) )

        fperl = "%.1f" % float(config.get( "RESERVE" , "FAIL-PER-LINK" ))


        gap_route = float( config.get("ADD-ROUTE" , "GAP" ) )
        gap_protect = float( config.get( "PROTECTION" , "GAP" ))
        gap_reserve = float( config.get("RESERVE","GAP" ))
        gap_restore = float( config.get("RESTORE" , "GAP" ) )
        gap = "%.1f" % (( gap_route + gap_protect + gap_reserve + gap_restore ) / 4.0 )
        meanre = "%.1f" % float(config.get("WAVE" , "AVE-WAVE" ))
        stdre = "%.1f" % float(config.get("WAVE" , "STD-WAVE" ))
        

        addprotect1 = "%.1f" % float(config.get("RESERVE" , "ADD-PROTECT-PERCENT" ))
        protectratio1 = "%.1f" % float( config.get("RESERVE" , "REDUNDANCY" ))

        addprotect2 = "%.1f" % float(config.get("RESTORE" , "ADD-PROTECT-PERCENT" ))
        protectratio2 = "%.1f" % float( config.get("RESTORE" , "REDUNDANCY" ))


        zilp = "%.1f" % float(config.get( "RESERVE" , "WORK" ))
        addroute = "%.1f" % float(config.get("RESTORE" , "ADD-ROUTING" ))

        tableII.add_row( [ inifile  , nconfiggen , nconfigsel , zilp ,  gap ,  meanre , stdre  ] )
        tableIII.add_row( [ inifile  , nconnect , fperl , addroute , addprotect1 , protectratio1 , addprotect2 , protectratio2 ] )



    # print table II

    print tableII
    print tableIII

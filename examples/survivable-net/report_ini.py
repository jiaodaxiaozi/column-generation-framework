import os
import ConfigParser
import glob
from prettytable import PrettyTable
import re


inputdir  = "ini/E*s[2,3,4,5]*e90*.ini"
#inputdir  = "ini/*s1*.ini"

#inputdir  = "ini/24NET-s1*.ini"

inputdir  = "ini/NJ*s1*.ini"
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
    tableIII = PrettyTable( ["INSTANCE" , "N-ISSUES" , "Fail-P-Link" , "ADDED ROUTE" , "ADDED PROTECT" , "Ratio"  ] )


    listFile = glob.glob( inputdir )

    for inifile in sorted( listFile , key = natural_keys ):
	
        print "analyzing " , inifile 	

        config = ConfigParser.ConfigParser()
        config.read( inifile )

        nconnect = "%.1f" % float( config.get("RESULT","NCONNECT-ISSUES" ))

        nconfiggen = config.get("RESULT","CONFIG-GENERATE" )
        nconfigsel = config.get("RESULT","CONFIG-SELECT" )

    
        maxfl = float( config.get("PROTECTION","MAX-PROTECT-FL" ) )

        fperl = "%.1f" % float(config.get( "RESULT" , "FAIL-PER-LINK" ))

        #fperl = maxfl 

        gap = "%.1f" % float(config.get("RESULT" , "GAP" ))
        meanre = "%.1f" % float(config.get("RESULT" , "MEAN-RESERVE" ))
        stdre = "%.1f" % float(config.get("RESULT" , "STD-RESERVE" ))
        

        addprotect = "%.1f" % float(config.get("RESULT" , "ADD-PROTECT" ))
        protectratio = "%.1f" % float( config.get("RESULT" , "PROTECT-RATIO" ))


        zilp = "%.1f" % float(config.get( "RESULT" , "ZILP" ))

        addroute = "%.1f" % float(config.get("ADD-ROUTE" , "ADD-ROUTING" ))


        tableII.add_row( [ inifile  , nconfiggen , nconfigsel , zilp ,  gap ,  meanre , stdre  ] )
        tableIII.add_row( [ inifile  , nconnect , fperl , addroute , addprotect , protectratio  ] )



    # print table II

    print tableII
    print tableIII

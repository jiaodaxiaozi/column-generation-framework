import os
import glob
import time
import commands
import sys

homedir   = os.getcwd() + "/"
datadir   = homedir + "sndlib/"
inputdir  = datadir + "NET/polska*d0*.net"
outputdir = datadir + "OUT/"
inidir    = datadir + "INI/"

scriptdir = homedir + "script/"


cmd = "oplrun -deploy -D input=\"%s\" -D output=\"%s\" " + "../../solver.mod"

if __name__ == "__main__" :

    print "RUN BATCH OF EXPERIMENTS"
    print "------------------------"
    print "Home Dir: " , homedir

    # delete script
    os.system("rm -f " + scriptdir + "*" )

    for ins in glob.glob( inputdir ) :

        base_name = os.path.basename(os.path.splitext( ins )[0])

        print "INSTANCE:" , base_name

        outname = outputdir + base_name + ".out"
        errname = outputdir + base_name + ".err"
        ininame = inidir    + base_name + ".ini" 
        scrname = scriptdir + base_name + ".pbs"

        print "output   : " , outname
        print "error    : " , errname
        print "ini      : " , ininame
        print "script   : " , scrname

        exe = cmd % ( ins , ininame )

        print "execute  : " , exe 
        
        # writing script
        sf = open( scrname , "w" )  
        
        sf.write("#!/bin/csh\n")
        
        sf.write("#\n")
        sf.write("#PBS -l walltime=120:00:00\n") 
        sf.write("#PBS -l nodes=1:m48G:ppn=12\n")
        sf.write("#PBS -W umask=022\n")
        sf.write("#PBS -r n\n")
        sf.write("\n")
        sf.write("#PBS -o " + outname + "\n")
        sf.write("#PBS -e " + errname + "\n")
        sf.write("\n")
        sf.write("module add cplex-studio\n")
        sf.write("\n")
        sf.write("cd " + homedir + "\n" )
        sf.write( exe + "\n" )
        sf.close()
        
        os.system("qsub " + scrname ) 

import os
import glob
import time
import commands

inputdir  = "net/24NET-hs4-e130-0.net"
inputdir  = "net/24NET-s1-e40-0.net"
inputdir = "net/NJ*s1*e40-0.net"
outputdir = "out/"
inidir    = "ini/"

cmd = "bsub  -n 8 -q \"long\" -M 134217728 -J %s -oo %s -eo %s oplrun -deploy -D input=\"%s\" -D output=\"%s\" ../../solver.mod"

if __name__ == "__main__" :

	print "RUN BATCH OF EXPERIMENTS"
	print "------------------------"

	for ins in glob.glob( inputdir ) :

		base_name = os.path.basename(os.path.splitext( ins )[0])

		print "INSTANCE:" , base_name

		outname = outputdir + base_name + ".out"
		errname = outputdir + base_name + ".err"
		ininame = inidir    + base_name + ".ini" 
 
		print "output   : " , outname
		print "error    : " , errname
		print "ini      : " , ininame

		exe = cmd % (base_name , outname , errname , ins , ininame )

		print "execute  : " , exe 
		os.system( exe )

		
		output = commands.getoutput('bjobs | wc -l')
		print "PENDING JOBS =  "  , output
		
		time.sleep(5)
		
		while int(output) > 20 :
			time.sleep(5)	
			output = commands.getoutput('bjobs | wc -l')

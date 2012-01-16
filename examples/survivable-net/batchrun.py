import os
import glob
import time

inputdir  = "net/NSF*21.net"
outputdir = "out/"
inidir    = "ini/"

cmd = "bsub -n 4 -q \"long\" -M 25165824 -J %s -oo %s -eo %s oplrun -deploy -D input=\"%s\" -D output=\"%s\" ../../solver.mod"

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
		time.sleep(10)

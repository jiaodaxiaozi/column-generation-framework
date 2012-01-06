import os
import glob

inputdir = "net/NSF*.net"
outputdir = "out/"

cmd = "bsub -n 4 -q \"long\" -M 25165824 -J %s -oo %s -eo %s oplrun -deploy -D input=\"%s\" ../../solver.mod"

if __name__ == "__main__" :

	print "RUN BATCH OF EXPERIMENTS"
	print "------------------------"
	for ins in glob.glob( inputdir ) :

		base_name = os.path.basename(os.path.splitext( ins )[0])

		print "INSTANCE:" , base_name

		outname = outputdir + base_name + ".out"
		errname = outputdir + base_name + ".err"
 
		print "output   : " , outname
		print "error    : " , errname

		exe = cmd % (base_name , outname , errname , ins  )

		print "execute  : " , exe 
		os.system( exe )

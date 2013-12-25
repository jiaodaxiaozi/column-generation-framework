import os



if __name__ == "__main__" :


    nins = 10
    print "gen data"


    for i in range(1,nins+1):
       
        seed = 2048 * i ; 
        print "seed: " ,  seed

        # data file
        f = open("map-" + str(seed) +".dat" , "w" )

        f.write("SEED_TRAFFIC = " + str(seed) + "; \n")
        f.write("NNODESLOT = 1024 ; \n" )
        f.write("NWAVELENGTH = 256 ; \n")
        f.write("NGEN = 6 ; \n")


        f.close()

        # pbs file
        f = open("map-" + str(seed) +".pbs" , "w" )

        f.write("#!/bin/csh\n")
        f.write("#PBS -l walltime=168:00:00\n" )
        f.write("#PBS -l nodes=1:m48G:ppn=12\n" )
        f.write("#PBS -W umask=022\n")
        f.write("#PBS -o OUT/map-" + str(seed) +  ".out \n")
        f.write("#PBS -e OUT/map-" + str(seed) +  ".err \n")

        f.write("module add cplex-studio\n")


        f.write("cd /RQexec/hoangha1/framework/examples/optimal-regenerator/\n")
        f.write("oplrun -deploy -D input=map-" + str(seed) + ".dat ../../solver.mod model.dat\n")

        f.close()

        # calling 
        os.system("qsub map-" + str(seed) + ".pbs" )





if __name__ == "__main__" :


    nins = 10
    print "gen data"

    for i in range(1,nins):
       
        seed = i * 512
        print "seed: " ,  seed

        f = open("map-" + str(seed) +".dat" , "w" )

        f.write("PERIOD = 1 ; \n")
        f.write("SEED_TRAFFIC = " + str(seed) + "; \n")
        f.write("KPATH_PARAM = 1 ; \n")
        f.write("NNODESLOT = 150 ; \n" )
        f.write("NWAVELENGTH = 160 ; \n")
        f.write("NGEN = 16 ; \n")



        f.close()


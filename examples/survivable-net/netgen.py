import random
import os
import re
from sets import Set

def primecover( s ) :
    return "\"" + s + "\"" 

# check if topo removing (s , d) is not connected ? yes return 1, no return 0
def checkTopoNotConnect( topo , s , d ) :

    temptopo = [ x for x in topo if x != [s,d] and x != [d,s] ]
    
    color = {}
    for x in topo :
        for v in x :
            color[ v ] = 0


    def travel( v , c  ) :
    
        color[ v ] = c 

        for x in temptopo :
            if v in x :
                for u in x :
                    if color[ u ] == 0 :
                        travel( u , c )    
    
    travel( s , 1 )
    
    for x in topo :
        for v in x :
            if color[ v ]==0 :
                return 1    
    
    return 0



def generate_by_degree( basename , degree , genedge , iter ):


    ffile = open( "./topo/" + basename + ".topo" )

    if degree :
        fnet  = open( "./net/" +  basename +  "-s" + "-d" + str(degree) + "-" + str(iter) +  ".net" , "w" )
    else :
        fnet  = open( "./net/" +  basename +  "-s" + "-e" + str(genedge) + "-" + str(iter) +  ".net" , "w" )

    lstNode = [];    
    lstEdge = [];

    tag = 0

    edgename = 0

    separator = "[\ |\n|\t|\r]+"

    for line in ffile :
        
        if ( re.match("TAG" , line ) ) :

            item = re.split( separator , line )
            tag  = int(item[1])

        # node 
        if ( re.match( "node" , line ) ) :

            item = re.split( separator , line )
            lstNode.append( item[1] )
            
    
        # link
        if ( re.match( "link" , line ) ) :

            item = re.split( separator , line )

            edgename += 1
            
            if tag == 1 :

                lstEdge.append( ( str(edgename) , item[3] , item[5] , item[7] ) )

            if tag == 2 :
                lstEdge.append( ( str(edgename) + 'a' , item[2] , item[3] , item[4] ) )
                lstEdge.append( ( str(edgename) + 'b' , item[3] , item[2] , item[4] ) )

    print "finish reading network"

    # write node set
    fnet.write("nodeset = {\n" )

    for nnode in lstNode :
        fnet.write( primecover( nnode ) + ",\n" )

    fnet.write("};\n")

    # write edgeset 
    
    fnet.write("edgeset = {\n" )

    for nedge in lstEdge :
        fnet.write("< ")

        for item in nedge[:-1] :
            fnet.write( primecover( item ) + "," )
    
        fnet.write( nedge[ -1 ] )

        fnet.write(" >,\n")

    fnet.write("};\n")
    
    print "finish writing basic information "

    # get set of all undirect edge
    lstUedge = Set( )

    for edge in lstEdge :
        lstUedge.add( Set(( edge[1] , edge[2] )) )

    # print all single link failure

    fnet.write("nfailure = "  + str( len( lstUedge ) ) + ";\n" )

    fnet.write( "failureset = [ \n" )

    for uedge in lstUedge : 
        fnet.write( "{ " )

        for edge in lstEdge :
            if (( edge[1] in  uedge ) and ( edge[2] in uedge ) ):
                fnet.write( primecover( edge[0] ) + " ")    

        fnet.write( " },\n" )
    fnet.write( "]; \n" )

    print "finish writing single failure"

    # generate logical topology
    logicdeg = {}
    logictopo = []


    for v in lstNode :    
        logicdeg[ v ] = 0 

    random.seed()

    # GENERATE BY DEGREE
    if degree > 0 :
        while ( 1 ) :

            underdeg = [ v for v in lstNode if logicdeg[v] < degree ]

            if not len( underdeg ):
                break
        
            # take two random variables from underdeg

            v1 = random.choice( underdeg )    
            v2 = random.choice( underdeg )

            if len( underdeg ) > 1 :
                while v1 == v2 :
                    v2 = random.choice( underdeg )                        
            else :
                while v1 == v2 :
                    v2 = random.choice( lstNode )

            # update degree
            logicdeg[ v1 ] += 1
            logicdeg[ v2 ] += 1

            logictopo.append( [ v1 , v2 ] )        
            logictopo.append( [ v2 , v1 ] )

    else :

        # GENERATE BY EDGE
        ge = 0    
        while ge < genedge :

            v1 = random.choice( lstNode )    
            v2 = random.choice( lstNode )
            
            if  (v1 != v2)  :

                logictopo.append( [ v1 , v2 ] )
                logictopo.append( [ v2 , v1 ] )                
                ge += 1

   

    fnet.write("logicset = { \n" )

    id = 0 

    for v1,v2 in logictopo:
        fnet.write("< " + str(id) + " , " + primecover( v1 ) + " , " + primecover( v2 ) + " , 1 >\n" ) 
	id += 1

    fnet.write("};\n" )


    # write common data
    fcommon = open( "common.dat" )
    cmlist = fcommon.readlines()
    for li in cmlist:
        fnet.write( li )
    fcommon.close()
    
    ffile.close()    
    fnet.close()

    print "finish generating logical topo "
    
    # checking 2-vertex connected 
    
    n_not_connect = 0

    for v1,v2 in logictopo :
    
        
        n_not_connect += checkTopoNotConnect( logictopo , v1 , v2 )
        if n_not_connect > 0 :
            return 0
            
    print "finish checking logic topo"

    if degree > 0 :
        print "generate by degree " , degree, " single failure for topo " , basename , " at iter " , iter 
    else :

        print "generate by edge " , genedge, " single failure for topo " , basename , " at iter " , iter 

    return 1

if __name__ == "__main__" :


    os.system("rm -f net/*")
    
    print "GENERATE NETWORKS"
    print ""

    for filename in os.listdir( "topo" ):

        basename,extension = filename.split(".")
        
        if  extension != "topo" :
            continue

        print "" 
        print "TOPO :" , basename , "\n"

        for i in range( 1 ) :

            if basename == "NSF" :    
                #while not generate_by_degree( basename , 0 , 21 ,  i ) : pass
                #while not generate_by_degree( basename , 0 , 25 ,  i ) : pass

                while not generate_by_degree( basename , 0 , 50 ,  i ) : pass

            if basename == "EURO" :    
                #while not generate_by_degree( basename , 3 ,  0 ,  i ) : pass
                #while not generate_by_degree( basename , 0 , 30 ,  i ) : pass
                #while not generate_by_degree( basename , 0 , 35 ,  i ) : pass

                while not generate_by_degree( basename , 0 , 70 ,  i ) : pass

            if basename == "NJLATA" :    
                #while not generate_by_degree( basename , 3 ,  0 ,  i ) : pass
                #while not generate_by_degree( basename , 0 , 20 ,  i ) : pass

                while not generate_by_degree( basename , 0 , 40 ,  i ) : pass

            if basename == "24NET" :

                #while not generate_by_degree( basename , 0 , 40 ,  i ) : pass
                #while not generate_by_degree( basename , 0 , 45 ,  i ) : pass

                while not generate_by_degree( basename , 0 , 90 ,  i ) : pass

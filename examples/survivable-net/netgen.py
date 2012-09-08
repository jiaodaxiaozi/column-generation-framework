import random
import os
import re
import math
import sys


#
# Convert a set to set of string
#
def set2char( F ) :

	F1 = []
	for fs in F :
		
		fs1 = []

		for s in fs :
			fs1.append(  set( [ str( x ) for x in s ] ) )

		F1.append( fs1 )

	return F1

#
# Add " to string
#
def primecover( s ) :
    return "\"" + s + "\"" 

#
# compute number of color after removing S
#
def checkNumberColor( topo , S ) :

    temptopo = [ x for x in topo if x not in S ]

    # first set color of all nodes = 0    
    color = {}
    for x in topo :
        for v in x :
            color[ v ] = 0

    # paint node v with color c
    def travel( v , c  ) :
    
        color[ v ] = c 

        for x in temptopo :
            if v in x :
                for u in x :
                    if color[ u ] == 0 :
                        travel( u , c )    
    
    # compute number of color    
    ncolor = 0
    for x in topo :
	for v in x  :
	    if color[v] == 0 :
		ncolor = ncolor + 1
		travel( v , ncolor )
    return ncolor


lstNode = []
lstEdge = []
logicdeg = {}
logictopo = []
capacity = {}
shortest = {}
mody = {}
F1 = set()
F2 = set()
F3 = set()
F4 = set()
FNODE = set()

def generate_logic( degree , genedge , ishalf ) :

    global logicdeg , logictopo  , lstNode , lstEdge , shortest

    
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
        tmpNode = set()
        
        while (2 * len( tmpNode )) < len( lstNode ) :
        
            v = random.choice( lstNode )
            tmpNode.add( v )
        
        
        #print "- half node : " , tmpNode
        
        ge = 0    
        while ge < genedge :

            if not ishalf :
                v1 = random.choice( lstNode )    
                v2 = random.choice( lstNode )
            else :
                v1 = random.choice( list(tmpNode) )
                v2 = random.choice( list(tmpNode) )
                
            
            if  (v1 != v2)  :

                logictopo.append( [ v1 , v2 ] )
                logictopo.append( [ v2 , v1 ] )                
                ge += 1
                # update degree
                logicdeg[ v1 ] += 1
                logicdeg[ v2 ] += 1

    # verify logic topology
    needrerun = 0 
    for v in lstNode  :
        if logicdeg[ v ] == 2 :
            print "node " , v , " has degree " , logicdeg[ v ]
            needrerun = 1
    if needrerun:
        generate_logic( degree , genedge , ishalf ) 
#
# Reading topo information
#
   
def reading_data( basename ) :

    global logicdeg , logictopo  , lstNode , lstEdge , F1 , F2 , F3 , F4 , FNODE 
    
    lstNode = [] 
    lstEdge = [] 
    
    print "READ TOPO : " , basename

    ffile = open( "./topo/" + basename + ".topo" )
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

    # get set of all undirect edge
    F1 = set( )
    F2 = set( )
    F3 = set( )
    F4 = set( )
    FNODE = set ( )

    # get set of all undirect edge
    lstUedge = set( )

    for edge in lstEdge :
        lstUedge.add( frozenset( ( edge[1] , edge[2] )) )
        
    # build single failure set 
    for e in lstUedge :
	if checkNumberColor( lstUedge ,  set( [e] ) ) == 1 :
        	F1.add(  frozenset([e]) )

    # build single node failure set
    for v in lstNode :
	tempnodeset = set()
	for e in lstUedge :
	    if v in e :
		tempnodeset.add( e )  
	
	#print "number color = " , checkNumberColor( lstUedge , tempnodeset)
	FNODE.add( frozenset( tempnodeset ) ) 

    # build higher order failure set
    for v in lstNode :
	temp = set()

	for e in lstUedge: 
	    if v in e :
		temp.add( e )			    

	
	# build dual
	for e1 in temp :
	    for e2 in temp :
		if len( set( [e1,e2] ) ) == 2 :
		    if checkNumberColor( lstUedge ,  set( [e1,e2] ) ) == 1 :
		        F2.add( frozenset( [ e1 , e2 ] ) )
	# build third
	for e1 in temp :
	    for e2 in temp :
		for e3 in temp :
		    if len( frozenset([e1,e2,e3]) )== 3 :
		    	if checkNumberColor( lstUedge ,  frozenset( [e1,e2,e3] ) ) == 1 :
		            F3.add( frozenset( [ e1 , e2 , e3 ] ) )
	# build fourth
 	for e1 in temp :
	    for e2 in temp :
		for e3 in temp :
		    for e4 in temp :
			if len( frozenset([ e1 , e2, e3 ,e4]) )== 4 :
		    	    if checkNumberColor( lstUedge ,  frozenset( [e1,e2,e3,e4] ) ) == 1 :
		                F4.add( frozenset( [ e1 , e2 , e3 , e4 ] ) )


    print "number of edges : " , len( lstEdge )
    print "number of nodes : " , len( lstNode )
    print "number of single failure : " , len( F1 )
    print "number of dual failure   : " , len( F2 )
    print "number of third failure  : " , len( F3 )
    print "number of fourth failure : " , len( F4 )
    
    F1 = [ x for x in F1 ]
    F2 = [ x for x in F2 ]
    F3 = [ x for x in F3 ]
    F4 = [ x for x in F4 ]

    random.shuffle(  F1 )
    random.shuffle(  F2 )
    random.shuffle(  F3 )
    random.shuffle(  F4 )


    print "------------------------------------"
    
    ffile.close()
#
# Writing basic information : node set + edge set + failure set
#
def write_basic( fnet , nloc , sce ) :

    global logicdeg , logictopo  , lstNode , lstEdge , shortest , mody , F1,F2,F3,F4 , FNODE
    # write node set
    fnet.write("nodeset = {\n" )

    
    for nnode in lstNode :
        fnet.write( primecover( nnode ) + ",\n" )

    fnet.write("};\n")

    # compute capacity
    
    for e in lstEdge :    
        capacity[ e ] = 0
    
    for x,y in logictopo[ 0 : nloc ] :
    
        for e in shortest[ (x,y) ] :
        
            capacity[ e ] += 1
    
    # write edgeset 
    
    for e in lstEdge :
        
        if mody[e] > 0 :
            dv =  0.2 * capacity[e]   
        else :
            dv =   -0.2 * capacity[e]  
        
        newe =  math.ceil( capacity[ e ] +  dv )
        
        if ( newe < 1 ) : 
            newe = 1
        
        #print e , ":" , capacity[e ] , "=>" , newe 
        
        capacity[ e ] = newe
            
    fnet.write("edgeset = {\n" )
    
    for nedge in lstEdge :
        fnet.write("< ")

        for item in nedge[:-1] :
            fnet.write( primecover( item ) + "," )
    
        fnet.write( nedge[ -1 ] )
        fnet.write( "," + str(capacity[ nedge ]) )

        fnet.write(" >,\n")

    fnet.write("};\n")
    
    print "finish writing basic information"
    
    # print all link failure

    FSET = set();



    if sce == 1 :
	FSET = F1

    if sce == 2 : 
	FSET = F1 + F2[ 0 : len(F2)/14 +1 ]
    if sce == 3 :
	FSET = F1 + F2[ 0 : len(F2)/14 +1 ] + F3[ 0 : len(F3)/14 + 1 ]

    if sce == 4 : 
	FSET = F1 + F2[ 0 : len(F2)/10 +1 ] + F3[ 0 : len(F3)/10 + 1 ] 

    if sce == 5 : 
	FSET = F1 + F2[ 0 : len(F2)/10 +1 ] + F3[ 0 : len(F3)/10 + 1 ] + F4[ 0 : len(F4)/20 + 1 ]

    if sce == 6 :
	FSET = FNODE

    FSET  = set2char( FSET )
    
    fnet.write("nfailure = "  + str(  len( FSET) ) + ";\n" )

    fnet.write( "failureset = [ \n" )

    for fs in FSET : 
        fnet.write( "{ " )

        for edge in lstEdge :
            for uedge in fs :	
		#print "check " , edge[1], edge[2] , " in " , uedge	
                if (( edge[1] in  uedge ) and ( edge[2] in uedge ) ):
                    fnet.write( primecover( edge[0] ) + " ")    

        fnet.write( " },\n" )
    fnet.write( "]; \n" )

    print "finish writing failure"

#
# Writing logicset from 0 to nloc
#    
def write_logic( fnet , nloc )  :
    global logictopo
    fnet.write("logicset = { \n" )

    id = 0 
    for v1,v2 in logictopo[ 0 :  nloc ] :
        fnet.write("< " + str(id) + " , " + primecover( v1 ) + " , " + primecover( v2 ) + " , 1 >\n" ) 
        id += 1
        
    fnet.write("};\n" )
#
# Writing common information
#
def write_common( fnet ) :

    # write common data
    fcommon = open( "common.dat" )
    cmlist = fcommon.readlines()
    for li in cmlist:
        fnet.write( li )
    fcommon.close()

#
# Compute shortest path for artificial capacity constraints    
#
def compute_shortest( ) :

    global logicdeg , logictopo  , lstNode , lstEdge , capacity , shortest , mody


    shortest = {}
    mody = {}
    
    for e in lstEdge :
        
        mody[ e ] = 0
        while mody[e] == 0 :
            mody[  e ] = random.randint( - 1 , 1 )
        
        
    # generate capacity
    
    for  x , y in logictopo :    
        
        #print "shortest path : "  , x , " => " , y
        
        shortest[ (x,y) ] = []
        
        dis = {}
        pre = {}
        notvisit = set()
        
        for v in lstNode:
            dis[ v ] = 100000
            notvisit.add( v )
        
        dis[ x ] = 0 
        pre[ x ] = x 
        
        consider = x
        
        
        while consider != y :
        
            notvisit.remove( consider )
        
            for e in lstEdge :
                                            
                if  ( e[1] == consider )  :
                                        
                    if ( dis[ consider ] + 1 ) < dis[ e[2] ] :
                        
                        dis[ e[2] ] = dis[ consider ] + 1
                        pre[ e[2] ] = e[1 ]
                    
            consider = y
            for v  in notvisit :
                if dis[v ] < dis[ consider ] :
                    consider = v
    
        consider = y
        thelen = 0
        
        while consider != x :

            for e in lstEdge :
                if ( e[1] == pre[consider] and e[2] == consider ) :
                    shortest[ ( x , y ) ].append( e )
        
            
            thelen = thelen + 1
            consider = pre[ consider ]
        
#                    
# generate topo    
#
def generate_topo( basename , lstDegree , lstNoLogic , iter , ishalf , listSCE ):

    global logicdeg , logictopo  , lstNode , lstEdge  

    # read generate topo data    
    reading_data( basename )
    
    
    # generate by degree
    for degree in lstDegree :
    
        generate_logic( degree , 0 , ishalf )
        compute_shortest()
    
	for sce in listSCE :    
        	fnet  = open( "./net/" +  basename +  "-s" + str(sce) + "-d" + str(degree) + "-" + str(iter) +  ".net" , "w" )        
        	write_basic( fnet , 1000000 , sce )
       		write_logic( fnet , 1000000 )
        	write_common( fnet )
        	fnet.close()


    generate_logic( 0 , len( lstNode ) * len( lstNode ) , ishalf )
    compute_shortest()
    
    for nloc in lstNoLogic :
        for sce in listSCE : 
        	if not ishalf :
            		fnet  = open( "./net/" +  basename +  "-s" + str(sce) + "-e" + str(nloc) + "-" + str(iter) +  ".net" , "w" )
        	else :
            		fnet  = open( "./net/" +  basename +  "-hs" + str(sce) + "-e" + str(nloc) + "-" + str(iter) +  ".net" , "w" )
        
        	write_basic( fnet , 2 * nloc , sce )        
        	write_logic( fnet , 2 * nloc )
       		write_common( fnet )
        	fnet.close()




if __name__ == "__main__" :

    #print "delete old files "
    #for ff in os.listdir("net" ) :
        
    #    file_path = os.path.join("net", ff )
    #    os.unlink( file_path )
    
    print ""
    print "GENERATE NETWORKS"
    print ""

    for filename in os.listdir( "topo" ):

        basename,extension = filename.split(".")
        
        if  extension != "topo" :
            continue

        print "" 
        print "TOPO :" , basename , "\n"

        for i in range( 100 ) :

            if basename == "NSF" :    
                generate_topo( basename , [] , [ 10 , 18 ] , i , False , [1] ) 
                

            if basename == "EURO" :    
                generate_topo( basename , [] ,  [ 25  ] ,  i , False , [1] ) 
                
            if basename == "NJLATA" :    
                generate_topo( basename , [ ] ,  [ 14 , 16 ] ,  i , False , [1] ) 

            #if basename == "test" :
		
            #    generate_topo( basename , [ 3 ] ,  [ 20 ] ,  i , False , [1,2,3,4,5,6] ) 

            if basename == "24NET" :
                generate_topo( basename , [  ] , [ 35  ]  ,  i , False , [1] ) 
                generate_topo( basename , [  ] , [ 20,30,40,50,60  ]  ,  i , False ,  [5] ) 

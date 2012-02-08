import random
import os
import re
from sets import Set
import math


# 24 NET
F44 = [ Set( [2 , 6] ) , Set( [2 , 3] )   ]
F45 = [ Set( [0 , 5] ) , Set( [1 , 5] )   ]
F46 = [ Set( [2 , 6] ) , Set( [3 , 6] ) , Set( [6 , 7] ) ]
F47 = [ Set( [5 , 10] ) , Set( [ 5 , 8 ] ) ]
F48 = [ Set( [8 , 10] ) , Set( [ 8 , 11] ) ]
F49 = [ Set( [9 , 12] ) , Set( [ 9 , 13] )  ]
F50 = [ Set( [10 , 18]) , Set( [10 , 14] )  ]
F51 = [ Set( [15, 20] ) , Set( [15 , 21] )  ]
F52 = [ Set( [15,16] )  , Set( [16 , 21] ) ]
F53 = [ Set( [2 , 3] )  , Set( [3 , 4] )   ]
F54 = [ Set( [15 , 20] ), Set( [21, 20] )  ]
F55 = [ Set( [14 , 15] ), Set( [14 ,19 ])  ]
F56 = [ Set( [10,11] )  , Set( [8 , 11] ) , Set( [12 , 11] ) ]
F57 = [ Set( [8,10] )   , Set( [8 , 5] )  , Set( [8 , 6] ) , Set( [8 ,9] ) ]
F58 = [ Set( [12,13] )   , Set( [12 , 16] ) ]
F59 = [ Set( [21 , 22] ), Set( [16 , 22] ) ]
F60 = [ Set( [7 , 6 ] ) , Set( [7 , 9 ])   ]
F61 = [ Set( [0 , 5 ] ) , Set( [ 1,5] ) , Set( [ 6,5] ) , Set( [ 5,8 ] ) ]

IF12 = [ F44 , F45 , F47 , F48 , F49 , F50 , F51 , F52 ]
IF22 = IF12 + [ F53 , F54 , F55 ]
IF32 = IF22 + [ F58 , F59 , F60 ]

IF13 = [ F46 ]
IF23 = IF13 + [ F56 ]

IF14 = [ F57 ]
IF24 = [ F61 ]

def set2char( F ) :

	F1 = []
	for fs in F :
		
		fs1 = []

		for s in fs :
			fs1.append(  Set( [ str( x ) for x in s ] ) )

		F1.append( fs1 )

	return F1





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


lstNode = []
lstEdge = []
lstUedge = Set()  
nfailure = 0
logicdeg = {}
logictopo = []
capacity = {}
shortest = {}
mody = {}


def generate_logic( degree , genedge , ishalf ) :

    global logicdeg , logictopo  , lstNode , lstEdge , lstUedge , nfailure , shortest

    
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
        tmpNode = Set()
        
        while (2 * len( tmpNode )) < len( lstNode ) :
        
            v = random.choice( lstNode )
            tmpNode.add( v )
        
        
        print "- half node : " , tmpNode
        
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

    
    # checking 2-vertex connected 
    
    n_not_connect = 0

    for v1,v2 in logictopo :
    
        
        n_not_connect += checkTopoNotConnect( logictopo , v1 , v2 )
        if n_not_connect > 0 :
            return 0
    
    return 1
    
def reading_data( basename ) :

    global logicdeg , logictopo  , lstNode , lstEdge , lstUedge , nfailure 
    
    lstNode = [] 
    lstEdge = [] 
    lstUedge = Set()  
    

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
    lstUedge = Set( )

    for edge in lstEdge :
        lstUedge.add( Set(( edge[1] , edge[2] )) )
        
    nfailure = len( lstUedge )
    
    print "number of edges : " , len( lstEdge )
    print "number of nodes : " , len( lstNode )
    print "number of single failure : " , nfailure
    print "------------------------------------"
    
    ffile.close()

def write_basic( fnet , nloc , sce ) :

    global logicdeg , logictopo  , lstNode , lstEdge , lstUedge , nfailure , shortest , mody
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
        
        print e , ":" , capacity[e ] , "=>" , newe 
        
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

    FSET = [ [x] for x in lstUedge ]

    if sce == 1 : pass

    if sce == 2 :
	FSET = FSET + IF12 + IF13

    if sce == 3 :
	FSET = FSET + IF22 + IF23

    if sce == 4 :
	FSET = FSET + IF32 + IF23 

    if sce == 5 :
	FSET = FSET + IF32 + IF23 + IF14


    FSET  = set2char( FSET )

    fnet.write("nfailure = "  + str(  len( FSET) ) + ";\n" )

    fnet.write( "failureset = [ \n" )

    for fs in FSET : 
        fnet.write( "{ " )

        for edge in lstEdge :
            for uedge in fs :		
                if (( edge[1] in  uedge ) and ( edge[2] in uedge ) ):
                    fnet.write( primecover( edge[0] ) + " ")    

        fnet.write( " },\n" )
    fnet.write( "]; \n" )

    print "finish writing failure"
    
def write_logic( fnet , nloc )  :
    global logicdeg , logictopo  , lstNode , lstEdge , lstUedge , nfailure , shortest
    fnet.write("logicset = { \n" )

    id = 0 
    for v1,v2 in logictopo[ 0 :  nloc ] :
        fnet.write("< " + str(id) + " , " + primecover( v1 ) + " , " + primecover( v2 ) + " , 1 >\n" ) 
        id += 1
        
    fnet.write("};\n" )

def write_common( fnet ) :

    # write common data
    fcommon = open( "common.dat" )
    cmlist = fcommon.readlines()
    for li in cmlist:
        fnet.write( li )
    fcommon.close()
    

def compute_shortest( ) :

    global logicdeg , logictopo  , lstNode , lstEdge , lstUedge , nfailure , capacity , shortest , mody


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
        notvisit = Set()
        
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
        
                    
    
def generate_topo( basename , lstDegree , lstNoLogic , iter , ishalf , listSCE ):

    global logicdeg , logictopo  , lstNode , lstEdge , lstUedge , nfailure 
    
    reading_data( basename )
    
    
    # generate by degree
    for degree in lstDegree :
    
        while not generate_logic( degree , 0 , ishalf ) : pass
        compute_shortest()
    
	for sce in listSCE :    
        	fnet  = open( "./net/" +  basename +  "-s" + str(sce) + "-d" + str(degree) + "-" + str(iter) +  ".net" , "w" )        
        	write_basic( fnet , 1000000 , sce )
       		write_logic( fnet , 1000000 )
        	write_common( fnet )
        	fnet.close()


    while not generate_logic( 0 , len( lstNode ) * len( lstNode ) , ishalf ) : pass
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

        for i in range( 1 ) :

            #if basename == "NSF" :    
            
            #   generate_topo( basename , [] , [ 21 , 25 , 50 , 80 ] , i , False , 1 ) 
                

            #if basename == "EURO" :    
                
            #   generate_topo( basename , [3 ] ,  [ 30 , 35 , 70 , 100  ] ,  i , False , 1 ) 
                
            #if basename == "NJLATA" :    
            
            #    generate_topo( basename , [ 3 ] ,  [ 20 , 40, 70 ] ,  i , False , 1 ) 

            if basename == "24NET" :

	    	generate_topo( basename , [  ] , [ 40 , 90 , 120  ]  ,  i , False , [1,2,3,4,5] ) 
                generate_topo( basename , [  ] , [ 40 , 90 , 130  ]  ,  i , True ,  [1,2,3,4,5] ) 

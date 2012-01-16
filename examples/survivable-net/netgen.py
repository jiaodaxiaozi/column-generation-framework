import random
import os
import re
from sets import Set
import math

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

def write_basic( fnet , nloc ) :

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
    
    # print all single link failure

    fnet.write("nfailure = "  + str(  nfailure ) + ";\n" )

    fnet.write( "failureset = [ \n" )

    for uedge in lstUedge : 
        fnet.write( "{ " )

        for edge in lstEdge :
            if (( edge[1] in  uedge ) and ( edge[2] in uedge ) ):
                fnet.write( primecover( edge[0] ) + " ")    

        fnet.write( " },\n" )
    fnet.write( "]; \n" )

    print "finish writing single failure"
    
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
        
                    
        

            
    
def generate_topo( basename , lstDegree , lstNoLogic , iter , ishalf ):

    global logicdeg , logictopo  , lstNode , lstEdge , lstUedge , nfailure 
    
    reading_data( basename )
    
    
    # generate by degree
    for degree in lstDegree :
    
        while not generate_logic( degree , 0 , ishalf ) : pass
        compute_shortest()
        
        fnet  = open( "./net/" +  basename +  "-s" + "-d" + str(degree) + "-" + str(iter) +  ".net" , "w" )        
        write_basic( fnet , 1000000)
        write_logic( fnet , 1000000 )
        write_common( fnet )
        fnet.close()


    while not generate_logic( 0 , len( lstNode ) * len( lstNode ) , ishalf ) : pass
    compute_shortest()
    
    for nloc in lstNoLogic :
        
        if not ishalf :
            fnet  = open( "./net/" +  basename +  "-s" + "-e" + str(nloc) + "-" + str(iter) +  ".net" , "w" )
        else :
            fnet  = open( "./net/" +  basename +  "-hs" + "-e" + str(nloc) + "-" + str(iter) +  ".net" , "w" )
        
        write_basic( fnet , 2 * nloc )        
        write_logic( fnet , 2 * nloc )
        write_common( fnet )
        fnet.close()




if __name__ == "__main__" :

    print "delete old files "
    for ff in os.listdir("net" ) :
        
        file_path = os.path.join("net", ff )
        os.unlink( file_path )
    
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

            if basename == "NSF" :    
            
                generate_topo( basename , [] , [ 21 , 25 , 50 , 80 ] , i , False) 
                

            if basename == "EURO" :    
                
                generate_topo( basename , [3 ] ,  [ 30 , 35 , 70  ] ,  i , False) 
                
            if basename == "NJLATA" :    
            
                generate_topo( basename , [ 3 ] ,  [ 20 , 40 , 70 ] ,  i , False) 

            if basename == "24NET" :

                generate_topo( basename , [  ] , [ 40 , 70 , 90  ]  ,  i , False) 
                generate_topo( basename , [  ] , [ 40 , 90 , 110 ]  ,  i , True ) 

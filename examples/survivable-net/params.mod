include "../../sysmsg.mod" ; // include this line in every global configuration file

float   NPROTECT[ 0..20 ] = ... ;
float   NROUTE[0..20] = ... ;
float   RELAX[ 0..20] = ... ;

{ string } nodeset = ... ; 

tuple edge_record {
   string id ; // name of edge
   string src; // source  
   string dst; // destination
   float  distance ; // distance 
   float  cap ; // capacity
 };

{ edge_record } edgeset = ... ;


tuple logic_record {
  int    id ;  
  string src ;
  string dst ;
  float  demand ;
  
};

int nfailure = ... ;   
{ string } failureset [ 1.. nfailure] = ...;

{ logic_record } logicset = ... ;

{ string } logicnodeset = { l.src | l in logicset } union { l.dst | l in logicset } ;


int efail [ f in 1..nfailure ][ e in edgeset ] = (  e.id in failureset[ f ] )  ? 1 : 0 ;


tuple config_record {

    int id   ;
    int logic_id ;
    float cost   ;
};

tuple route_record {

	int config_id ;
	string edge_id ;
}

{ config_record } configset = ... ;
{ route_record  } routeset  = ... ;


float dual_support[ logicset ] = ... ;
float dual_reserve[ logicset ][ edgeset ] = ... ;
int thepath[ edgeset ] = ... ;
int addrouting[ edgeset ] = ... ;

float startcap    = sum( e in edgeset ) e.cap;

{ config_record } configsol = ... ;
/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 *                                           GLOBAL FUNCTIONS
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/


execute GLOBAL_FUNCTIONS {




    /* return edge by id */
    function edge_by_id( id ) {

        for ( var e in edgeset )
        if ( e.id == id ) 
            return e ;
    }


    /* print configuration */
    function printConfiguration( c ) {

            var v ;
            var _end ;
            for ( var l in logicset )
            if ( l.id == c.logic_id ){
    
                write("logic link " , l  , " routed as : " , l.src );

                v = l.src ;
                _end = l.dst ;
            }


            while (1) {

                for ( var e in edgeset )
                if ( c.routing[ e ] == 1 && e.src == v ) {

                    v = e.dst ;
                    write( "->", v );
                    break ;
                }

                if ( v == _end ) break ;
            }
    
            writeln();


    }



/**

Dijkstra Shortest Path

Edges : dual_reserve[ request ][ e ]

**/


function DIJKSTRA( request , disp , takeroutecost )
{
    if ( disp ) writeln("DISTRA :" , request.src , " => " , request.dst );

    var edis = new Array();
    var visit = new Array();
    var pre  = new Array();

    var nvisit = 0 ;
    for ( var v in nodeset ){
        edis[ v ]  = Infinity ;
        visit[ v ] = 0 ;
        nvisit = nvisit + 1 ;
        pre[ v ] = null ;
    }


    edis[ request.src ] = 0 ;

    while( nvisit > 0 ){

        // find min edis among not visit
        var minv ;
        var mindis = Infinity ;

        for ( v in nodeset )
        if ( visit[ v ] == 0 ){
        
            if (  edis[v ] <= mindis  ) {

                mindis = edis[ v ];
                minv   = v ;
            }
        } // end for

        // consider minv & reset neighbough not visit
        visit[ minv ] = 1 ;
        nvisit = nvisit - 1 ;
        if ( minv == request.dst ) break ;
    
        for (var e in edgeset )
        if ( e.src == minv && visit[ e.dst ] == 0 )
        {
            if (  edis[ e.dst ] > (edis[ minv ] + dual_reserve[ request ][ e ] )) {
                edis[ e.dst ] = edis[ minv ] + dual_reserve[ request ][ e ] ;
                pre[ e.dst ] = e ;
            }    
        }

    }


    // make configuration
    var routecost = 0 ;
    for ( e in edgeset ) thepath[e ] = 0 ;

    var endnode = request.dst ;
    while ( endnode != request.src ) {
        
        routecost = routecost + 1 ;    
        thepath[ pre[ endnode ] ] = 1 ;        
        endnode = pre[ endnode ].src ;    
        
    }

    var dualcost  = edis[ request.dst ] + dual_support[ request ];


    if ( takeroutecost ) {

    	  dualcost  = routecost + edis[ request.dst ] - dual_support[ request ];
	}

    if ( disp ) writeln( "route cost : " , routecost , " price cost : " , dualcost );

    if ( dualcost > -0.0001 ) return false ;
 
    var cid = 0 ;

    for ( var c in configset )
	if ( cid < c.id ) cid = c.id ;

     cid = cid + 1 ;
 
    configset.addOnly( cid , request.id , routecost   );    

   for ( e in edgeset )
   if ( thepath[ e ] > 0 )
	routeset.addOnly( cid , e.id );

    return true;
} // end distra


} // end paragraph 


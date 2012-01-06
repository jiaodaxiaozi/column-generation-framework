
include "params.mod";


dvar int+     route[ logicset ] in 0..1; // can route
dvar int+      z[  configset ] in 0..1; // number of copy of configurations
dvar int+      reserve[ edgeset ][ logicset ]  in 0..1 ;
dvar int+      f_route [ edgeset ][ logicset ] in 0..1 ;
dvar int+      f_noroute [ edgeset ][ logicset ] in 0..1 ;

// flow desc :      failure         l1          l2           : l2 is routed on l1
dvar int+ flow[ 1..nfailure ][ logicset ][ logicset ] in 0..1 ;
dvar int+ protect[ 1..nfailure ][ logicset ] in 0..1; // can protect
dvar int+ broken[  1..nfailure ][ logicset ] in 0..1;

float DUMMY_COST = 100000 ;

execute STARTSOLVEINT {



    if ( isModel("FINAL") ) {
        
        cplex.tilim = 4 * 3600  ; // limit 4h searching for integer solution 
        cplex.epgap = 0.03 ;    // stop with small gap
        cplex.parallelmode = -1 ; // opportunistic mode
        cplex.threads = 0 ; // use maximum threads

    }


     if ( isModel("RELAX-FINAL")  ) setNextModel("PRICE-FINAL");
}



minimize    sum( c in configset ) z[c] * c.cost + sum( f in 1..nfailure , l in logicset ) (1-protect[ f ][ l ]) * DUMMY_COST; 
       

subject to {


    forall ( l in logicset )
    ctSupport :
        1 == sum( c in configset : c.logic_id == l.id ) z[c]  ;

    forall ( l in logicset , e in edgeset )
    ctReserve :
        reserve[e][l] == sum ( c in configset : c.logic_id == l.id ) z[c] * c.routing[e] ;

    sum ( l in logicset ) route[ l ] == NROUTE[0];

    // decompose route vs no route
    forall ( l in logicset , e in edgeset ){

        reserve[ e ][ l ] == f_route[ e ][ l ] + f_noroute[ e ][ l ];
        f_route[e][ l ] <= route[ l ] ;
        f_noroute[ e ][ l ] <= ( 1 - route[l] );
    }
    
    // routing constraint
    forall( e in edgeset ){
        sum( l in logicset ) f_route[ e ][ l ] <= capacity[ e ] ; 
        sum( l in logicset ) reserve[ e ][ l ] <=  (capacity[e] + addrouting[ e ]) ; 
    }

    
    forall( f in 1..nfailure , l in logicset , e in edgeset : e.id in failureset[f] )

        broken[ f ][ l ] >= reserve[ e ][ l ] ;

    
    // network flow
    forall ( f in 1..nfailure , l2 in logicset )
    
    {


        forall ( l1 in logicset  ){

            flow[ f ][ l1 ][ l2 ] <= 1 - broken[f][l1] ; 
            flow[ f ][ l1 ][ l2 ] <= protect[f][ l1 ];
        }
                    

        forall ( v in logicnodeset : (v != l2.src) && (v != l2.dst) )
              sum ( l1 in logicset : l1.dst ==v ) flow[f ][ l1 ][ l2 ] == sum ( l1 in logicset : l1.src ==v ) flow[f ][ l1 ][ l2 ] ;
    
        sum( l1 in logicset : l1.dst == l2.src ) flow[ f ][ l1][ l2 ] == 0;
        sum( l1 in logicset : l1.src == l2.dst ) flow[ f ][ l1][ l2 ] == 0;

        sum( l1 in logicset : l1.dst == l2.dst ) flow[ f ][ l1][ l2 ] == protect[ f ][ l2 ] ;
        sum( l1 in logicset : l1.src == l2.src ) flow[ f ][ l1][ l2 ] == protect[ f ][ l2 ] ;

    
    } 

};

float routecost   = sum( l in logicset , e in edgeset ) f_route[e][l ] ; 
float noroutecost = sum( l in logicset , e in edgeset ) f_noroute[e][l ] ; 
float startcap    = sum( e in edgeset ) capacity[e];
float addroutecap = sum( e in edgeset  ) addrouting[e ];
int   nfull       = sum( l in logicset ) (  (sum ( f in 1..nfailure ) (1-protect[ f ][ l ])) == 0 ? 1 : 0 ) ;

float totalfl     = sum( l in logicset , f in 1..nfailure ) (1-protect[ f ][ l ]) ; 
float failperlink = card( logicset ) == nfull ? 0 : totalfl/ (card(logicset)-nfull)  ;
float linkperfail = card( logicset ) == nfull ? 0 : totalfl / nfailure  ;

float useforprotect[ f in 1..nfailure ][ e in edgeset ] = sum( l2 in logicset , l1 in logicset ) flow[ f ][ l1 ][ l2 ] * reserve[ e ][ l1 ] ;
float reserveprotect[ e in edgeset ] = max (f in 1..nfailure ) useforprotect[ f ][ e ];
float protectcap = sum( e in edgeset ) reserveprotect[ e ];
int   nselect = sum ( c in configset ) z[c] > 0.5 ? 1:0 ;

float meanreserve = ( routecost + noroutecost ) / card(edgeset) ;
float stdreserve  = sqrt( sum (  e in edgeset ) ( (sum( l in logicset )reserve[ e ][ l ]) - meanreserve )*( (sum( l in logicset )reserve[e][l]) - meanreserve ) / card( edgeset ) );

int   maxwave = max( e in edgeset ) ( sum( l in logicset ) reserve[e][l] );

/********************************************** 

    POST PROCESSING
    
 *********************************************/
 
    
execute CollectDualValues {


    var l , m  , e , f ;

    for( l in logicset )
        dual_support[l] = ctSupport[ l ].dual ;
    
    for( l in logicset )
    for( e in edgeset  )
        dual_reserve[l][e] = ctReserve[ l ][e].dual ;    




}


execute InRelaxProcess {



        
        writeln("Master Objective : " , cplex.getObjValue() , " nconfig : " , configset.size );



    if ( isModel("FINAL") ) {
    
        lineSep("RESULT", "-");
        writeln();
        writeln("ROUTECOST = "   , routecost );
        writeln("NOROUTECOST = " , noroutecost );
        writeln("STARTCAP = " , startcap );
        writeln("E-LINK   = " , edgeset.size );
        writeln("L-LINK   = " , logicset.size );
        writeln("NFAILURE = " , nfailure );
        writeln("ROUTED   = " , NROUTE[0] , " " , NROUTE[0] / logicset.size * 100 , " (%)" );
        writeln("ADD-ROUTING = " , addroutecap , " " , addroutecap / startcap * 100 , " (%)" );
        writeln("NFULL = " , nfull );
        writeln("NCONNECT-ISSUES = " , logicset.size - nfull , " " ,  (logicset.size - nfull) / logicset.size * 100 , " (%)" ); 
        writeln("FAIL-PER-LOGIC-LINK = " , failperlink );
        writeln("LOGIC-LINK-PER-FAIL = " , linkperfail );
	writeln("TOTAL-FL = " , totalfl );
	writeln();
	writeln("NCONFIG = " , configset.size );
	writeln("NSELECT = " , nselect ,  nselect / configset.size * 100 , "(%)");
	 
        writeln("PROTECT-CAP = " , protectcap , " " , protectcap / (routecost + noroutecost)  );
       
	writeln("GAP =" , GAP( RELAX[0] , cplex.getObjValue())); 
	writeln("MEAN-RESERVE = " , meanreserve );
	writeln("STD-RESERVE = " , stdreserve );	
	writeln("MAX-WAVE = " , maxwave );

    } else RELAX[0] = cplex.getObjValue();

}








include "params.mod";


dvar int+     route[ logicset ] in 0..1; // can route
dvar int+     z[  configset ] in 0..1; // number of copy of configurations
dvar int+     reserve[ edgeset ][ logicset ]  in 0..1 ;


execute STARTSOLVEINT {

    

    if ( isModel("ROUTE") ) {
        
        cplex.tilim = 4 * 3600  ; // limit 4h searching for integer solution 
        cplex.epgap = 0.03 ;    // stop with small gap
        cplex.parallelmode = -1 ; // opportunistic mode
        cplex.threads = 0 ; // use maximum threads

    }
    
    if ( isModel("RELAX-ROUTE") ) {
    
        setNextModel("PRICE-ROUTE" );
    }


}



minimize  sum( l in logicset ) (1-route[l])  ;

subject to {


    forall ( l in logicset )
    ctSupport :
        route[l] == sum( c in configset : c.logic_id == l.id ) z[c]  ;

    forall ( l in logicset , e in edgeset )
    ctReserve :
        reserve[e][l] == sum ( c in configset : c.logic_id == l.id ) z[c] * c.routing[e] ;

    
    // routing constraint
    forall( e in edgeset )
        sum( l in logicset ) reserve[ e ][ l ]   <= e.cap ; 
        
    


};

float nroute   = sum ( l in logicset ) route[l];


/********************************************** 

    POST PROCESSING
    
 *********************************************/
 
    
execute {


    var l , m  , e , f ;

    for( l in logicset )
        dual_support[l] = ctSupport[ l ].dual ;
    
    for( l in logicset )
    for( e in edgeset  )
        dual_reserve[l][e] = ctReserve[ l ][e].dual ;    


    writeln("Master Objective : " , cplex.getObjValue() );

    if ( isModel("ROUTE") ){
    
        NROUTE[0] = nroute ;
        writeln();
        writeln("Maximum routing logical links : " , NROUTE[0] , " (" , NROUTE[0] / logicset.size * 100.0 , " %)" );
        writeln();
        
        setNextModel("RELAX-ADD-ROUTE");
        
    }


    
}






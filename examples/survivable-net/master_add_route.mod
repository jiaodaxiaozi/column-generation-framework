
include "params.mod";


dvar int+     route[ logicset ] in 0..1; // can route
dvar int+      z[  configset ] in 0..1; // number of copy of configurations
dvar int+      reserve[ edgeset ][ logicset ]  in 0..1 ;
dvar int+      f_route [ edgeset ][ logicset ] in 0..1 ;
dvar int+      f_noroute [ edgeset ][ logicset ] in 0..1 ;


dvar int+      addroute[ edgeset ] ;


execute STARTSOLVEINT {

    

    if ( isModel("ADD-ROUTE") ) {
        
        cplex.tilim = 4 * 3600  ; // limit 4h searching for integer solution 
        cplex.epgap = 0.03 ;    // stop with small gap
        cplex.parallelmode = -1 ; // opportunistic mode
        cplex.threads = 0 ; // use maximum threads

        setNextModel("RELAX-FINAL");
    }


 if ( isModel("RELAX-ADD-ROUTE")  ) setNextModel("PRICE-ADD-ROUTE");
}



minimize   sum( e in edgeset ) addroute[ e ] ;

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
        sum( l in logicset ) f_route[ e ][ l ]   <= capacity[ e ] ; 
        sum( l in logicset ) reserve[ e ][ l ] <=  (capacity[e] + addroute[ e ]) ; 
    }

    


};


float addcap = sum( e in edgeset ) addroute[e] ;


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



        
        writeln("Master Objective : " , cplex.getObjValue() , " nconfig : " , configset.size);



    if ( isModel("ADD-ROUTE") ) {
        writeln();
        writeln("additional routing bandwidth : " , addcap );
        writeln();
        for ( var e in edgeset )
            addrouting[ e ] = addroute[e].solutionValue ;
   
        
    }

}






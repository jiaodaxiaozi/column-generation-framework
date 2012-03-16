
include "params.mod";


dvar int+      route[ logicset ] in 0..1; // can route
dvar int+      z[  configset ] in 0..1; // number of copy of configurations
dvar int+      reserve[ edgeset ][ logicset ]  in 0..1 ;
dvar int+      f_route [ edgeset ][ logicset ] in 0..1 ;


dvar int+      addroute[ edgeset ] ;


execute STARTSOLVEINT {


    if ( isModel("ADD-ROUTE") ) {
        
        cplex.tilim = 12 * 3600  ; // limit 12h searching for integer solution 

        setNextModel("RELAX-PROTECT");
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
        reserve[e][l] == sum ( c in configset , r in routeset : c.logic_id == l.id && r.config_id == c.id && r.edge_id == e.id ) z[c]  ;

    sum ( l in logicset ) route[ l ] == NROUTE[0];


    // decompose route vs no route
    forall ( l in logicset , e in edgeset ){

        f_route[ e ][ l ] <= reserve[e][l];
	    f_route[ e ][ l ] <= route[ l ] ;
	    f_route[ e ][ l ] >= route[ l ] + reserve[e][l] - 1 ;


    }

    
    // routing constraint
    forall( e in edgeset ){
        sum( l in logicset ) f_route[ e ][ l ] <=   e.cap ; 
        sum( l in logicset ) reserve[ e ][ l ] <=  ( e.cap + addroute[ e ]) ; 
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
        

        output_section("ADD-ROUTE");
        output_value("GAP" , GAP( NROUTE[2] , cplex.getObjValue() ) );
	    output_value( "ADD-CAP" , addcap );
	    output_value( "ADD-ROUTING" , addcap / startcap * 100 );
        

        lineSep("ADD ROUTE" , "-" );

        
        for ( var e in edgeset )
            addrouting[ e ] = addroute[e].solutionValue ;
   
   	    writeln("configset = " , configset.size );    
	    writeln("routeset  = " , routeset.size );

        writeln();
        for ( e in edgeset ) 
            if ( addrouting[e] > 0.5 )
                writeln("add " , addrouting[e] , " to " , e );

    } else NROUTE[2] = cplex.getObjValue();

}






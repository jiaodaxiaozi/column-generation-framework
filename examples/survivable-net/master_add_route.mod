
include "params.mod";


dvar int+      z[  configset ] in 0..1; // number of copy of configurations
dvar int+      reserve[ edgeset ][ logicset ]  in 0..1 ;
dvar int+      addroute[ edgeset ] ;


execute STARTSOLVEINT {


    if ( isModel("ADD-ROUTE") ) {
        
        cplex.tilim = 24 * 3600  ; // limit 12h searching for integer solution 

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

    // routing constraint
    forall( e in edgeset ){
        sum( l in logicset ) reserve[ e ][ l ] <=  ( e.cap + addroute[ e ]) ; 
    }

    


};



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
        
        ADD_ROUTE[ 0 ] = cplex.getObjValue();

        output_section("ADD-ROUTE");
        output_value("GAP" , GAP( RELAX[ RELAX_ADD_ROUTE ] , cplex.getObjValue() ) );
	    output_value( "ADD-CAP" , ADD_ROUTE[0] );
	    output_value( "ADD-ROUTING" , ADD_ROUTE[0] / startcap * 100 );
        

        lineSep("ADD ROUTE" , "-" );

   	    writeln("configset = " , configset.size );    
	    writeln("routeset  = " , routeset.size );

        writeln();
        for ( e in edgeset ) 
            if ( addroute[e].solutionValue > 0.5 )
                writeln("add " , addroute[e].solutionValue , " to " , e );

    } else RELAX[ RELAX_ADD_ROUTE ] = cplex.getObjValue();

    
}







include "params.mod";


dvar int+      route[ logicset ] in 0..1; // can route
dvar int+      z[  configset ] in 0..1; // number of copy of configurations
dvar int+      reserve[ edgeset ][ logicset ]  in 0..1 ;
dvar int+      f_route [ edgeset ][ logicset ] in 0..1 ;

// flow desc :      failure         l1          l2           : l2 is routed on l1
dvar int+ flow[ 1..nfailure ][ logicset ][ logicset ] in 0..1 ;
dvar int+ protect[ 1..nfailure ][ logicset ] in 0..1; // can protect
dvar int+ broken[  1..nfailure ][ logicset ] in 0..1;


execute STARTSOLVEINT {

    writeln("MODEL : " , getModel() );

    if ( isModel("PROTECTION") ) {
        
        cplex.epgap = 0.03 ;    // stop with small gap
    }


     if ( isModel("RELAX-PROTECT")  ) setNextModel("PRICE-PROTECT");
}



minimize    sum( f in 1..nfailure , l in logicset ) (1-protect[ f ][ l ]) ; 
       

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
        sum( l in logicset ) f_route[ e ][ l ] <= e.cap ; 
        sum( l in logicset ) reserve[ e ][ l ] <=  ( e.cap + addrouting[ e ]) ; 
    }

    
    forall( f in 1..nfailure , l in logicset , e in edgeset : e.id in failureset[f] )
        broken[ f ][ l ] >= reserve[ e ][ l ] ;

    forall( f in 1..nfailure , l in logicset  )
	    broken[ f ][ l ] <= sum( e in edgeset : e.id in failureset[ f ] ) reserve[ e ][ l ] ;



     
    // network flow
    forall ( f in 1..nfailure , l2 in logicset )
    
    {


        forall ( l1 in logicset  ){

            flow[ f ][ l1 ][ l2 ] <= 1 - broken[f][l1] ; 
        }
                    

        forall ( v in logicnodeset : (v != l2.src) && (v != l2.dst) )
              sum ( l1 in logicset : l1.dst ==v ) flow[f ][ l1 ][ l2 ] == sum ( l1 in logicset : l1.src ==v ) flow[f ][ l1 ][ l2 ] ;
    
        sum( l1 in logicset : l1.dst == l2.src ) flow[ f ][ l1][ l2 ] == 0;
        sum( l1 in logicset : l1.src == l2.dst ) flow[ f ][ l1][ l2 ] == 0;

        sum( l1 in logicset : l1.dst == l2.dst ) flow[ f ][ l1][ l2 ] == protect[ f ][ l2 ] ;
        sum( l1 in logicset : l1.src == l2.src ) flow[ f ][ l1][ l2 ] == protect[ f ][ l2 ] ;

    
    } 

};

float protectcap =  sum( f in 1..nfailure , l in logicset ) protect[ f ][ l ];

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



        
        writeln("Master Objective : " , cplex.getObjValue() , " nconfig : " , configset.size  , " routeset : " , routeset.size);


    if ( isModel("PROTECTION") ) {
    

    NPROTECT[0] = protectcap ;

	output_section("PROTECTION");
    output_value( "MAX-PROTECT-FL" , NPROTECT[0] );
	output_value( "GAP" , GAP( NPROTECT[1] , cplex.getObjValue()));


	setNextModel("RELAX-FINAL");

    }  else {


        for ( var i = 10 ; i >= 1  ; i -- )         
            NPROTECT[i+1] = NPROTECT[ i ] ;

		NPROTECT[1] = cplex.getObjValue();

        if ( Opl.abs( NPROTECT[5] - NPROTECT[1]) <= 0.0001 ) setNextModel("PROTECTION" );

    }
}







include "params.mod";


dvar int+      z[  configset ] in 0..1; // number of copy of configurations
dvar int+      reserve[ edgeset ][ logicset ]  in 0..1 ;

// flow desc :      failure         l1          l2           : l2 is routed on l1
dvar int+ flow[ 1..nfailure ][ logicset ][ logicset ] in 0..1 ;
dvar int+ protect[ 1..nfailure ][ logicset ] in 0..1; // can protect
dvar int+ broken[  1..nfailure ][ logicset ] in 0..1;



execute STARTSOLVEINT {

    writeln("MODEL : " , getModel() );

    if ( isModel("FINAL") ) {

        cplex.epgap = 0.01 ;    // stop with small gap

    }


     if ( isModel("RELAX-FINAL")  ) setNextModel("PRICE-FINAL");
}



minimize    sum( c in configset ) z[c] * c.cost  ; 
       

subject to {


    forall ( l in logicset )
    ctSupport :
        1 == sum( c in configset : c.logic_id == l.id ) z[c]  ;

    forall ( l in logicset , e in edgeset )
    ctReserve :
        reserve[e][l] == sum ( c in configset , r in routeset : c.logic_id == l.id && r.config_id == c.id && r.edge_id == e.id ) z[c]  ;

    sum( l in logicset , f in 1..nfailure ) protect[ f ][ l ] == NPROTECT[0] ;

    // routing constraint
    forall( e in edgeset ){
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


float routecost   = sum( l in logicset , e in edgeset ) f_route[e][l ] ; 
float totalcost   = sum( l in logicset , e in edgeset ) reserve[e][l ] ; 
float addroutecap = sum( e in edgeset  ) addrouting[e ];
float nfull       = sum( l in logicset ) (  (sum ( f in 1..nfailure ) (1-protect[ f ][ l ])) < 0.5 ? 1 : 0 ) ;

float totalfl     = sum( l in logicset , f in 1..nfailure ) (1-protect[ f ][ l ]) ; 
float failperlink = card( logicset ) == nfull ? 0 : (totalfl/ (card(logicset)-nfull))  ;
float linkperfail = card( logicset ) == nfull ? 0 : (totalfl / nfailure)  ;

float useforprotect[ f in 1..nfailure ][ e in edgeset ] = sum( l2 in logicset , l1 in logicset ) flow[ f ][ l1 ][ l2 ] * reserve[ e ][ l1 ] *  broken[f][l2] * protect[ f ][ l2 ]  ;
float reserveprotect[ e in edgeset ] = max (f in 1..nfailure ) useforprotect[ f ][ e ];
float protectcap = sum( e in edgeset ) reserveprotect[ e ];

float preprotect [ e in edgeset ] = maxl( 0 , (e.cap - ( sum(l in logicset) reserve[e][l]  ))) ;
float addprotect = sum( e in edgeset ) maxl( 0 , reserveprotect[e] - preprotect[e] );

float nselect = sum ( c in configset ) z[c]  ;

float meanreserve = totalcost / card(edgeset) ;
float stdreserve  = sqrt( sum (  e in edgeset ) ( (sum( l in logicset )reserve[ e ][ l ]) - meanreserve )*( (sum( l in logicset )reserve[e][l]) - meanreserve ) / card( edgeset ) );


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


    if ( isModel("FINAL") ) {
    
        
        	for ( var c in configset ){

		if (z[c].solutionValue > 0.5 ){
			configsol.addOnly( c );
		}


	}

	output_section("RESULT");
    output_value( "NEDGE" , logicset.size );
    output_value( "TOTALFL" , totalfl );
	output_value( "NCONNECT-ISSUES" ,  (logicset.size - nfull) / logicset.size * 100 ) ;
	output_value( "FAIL-PER-LINK" , failperlink );
	output_value( "ADD-PROTECT" , addprotect / startcap * 100 );
	output_value( "PROTECT-RATIO" ,  protectcap / totalcost);
	output_value( "CONFIG-GENERATE" , configset.size );
	output_value( "CONFIG-SELECT" , nselect );

    output_value( "ZILP" , cplex.getObjValue() );

	output_value( "GAP" , GAP( RELAX[0] , cplex.getObjValue()));
    output_value("MEAN-RESERVE" , meanreserve );
    output_value("STD-RESERVE" , stdreserve );	

	setNextModel("MAXWAVE");

    }  else {

        for ( var i = 10 ; i >= 0 ; i -- )
            RELAX[ i + 1 ] = RELAX[ i ] ;

		RELAX[0] = cplex.getObjValue();

        if ( Opl.abs( RELAX[ 0 ] - RELAX[ 5 ] ) <= 0.0001 )
            setNextModel( "FINAL" );

    }
}






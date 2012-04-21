
include "params.mod";


dvar int+      z[  configset ] in 0..1; // number of copy of configurations
dvar int+      reserve[ edgeset ][ logicset ]  in 0..1 ;

// flow desc :      failure         l1          l2           : l2 is routed on l1
dvar int+ flow[ 1..nfailure ][ logicset ][ logicset ] in 0..1 ;
dvar int+ broken[  1..nfailure ][ logicset ] in 0..1;

dvar int+      addroute[ edgeset ] ;

execute STARTSOLVEINT {

    writeln("MODEL : " , getModel() );

    if ( isModel("RESTORE") ) {
        
        cplex.epgap = 0.01 ;    // stop with small gap
    }

     if ( isModel("RELAX-RESTORE")  ) setNextModel("PRICE-RESTORE");
}

dvar int rcap[ edgeset ];

minimize    sum( e in edgeset ) rcap[ e ]; 

subject to {


    forall ( l in logicset )
    ctSupport :
        1 == sum( c in configset : c.logic_id == l.id ) z[c]  ;

    forall ( l in logicset , e in edgeset )
    ctReserve :
        reserve[e][l] == sum ( c in configset , r in routeset : c.logic_id == l.id && r.config_id == c.id && r.edge_id == e.id ) z[c]  ;

    forall ( l in logicset , e in edgeset )
        reserve[e][l] == fixroute[ e ][ l ]  ;

    // routing constraint
    forall( e in edgeset )
        sum( l in logicset ) reserve[ e ][ l ] <=  ( e.cap + addroute[ e ]) ; 

    sum( e in edgeset ) addroute[e] <= ADD_ROUTE[ 0 ];


    // detect broken links 
    forall( f in 1..nfailure , l in logicset , e in edgeset : e.id in failureset[f] )
        broken[ f ][ l ] >= reserve[ e ][ l ] ;

    forall( f in 1..nfailure , l in logicset  )
	    broken[ f ][ l ] <= sum( e in edgeset : e.id in failureset[ f ] ) reserve[ e ][ l ] ;


    // compute cap
    forall( f in 1..nfailure , e in edgeset ){

        rcap[ e ] >=  sum( l2 in logicset , l1 in logicset ) flow[ f ][ l1 ][ l2 ] * fixroute[ e ][ l1 ] ;        

    }

    // network flow
    forall ( f in 1..nfailure , l2 in logicset )
    {

        forall ( l1 in logicset  ){

            flow[ f ][ l1 ][ l2 ] <= 1 - broken[f][l1] ; 
        }
                    

        forall ( v in logicnodeset : (v != l2.src) && (v != l2.dst) ){
        
              sum ( l1 in logicset : l1.dst ==v ) flow[f ][ l1 ][ l2 ] == sum ( l1 in logicset : l1.src ==v ) flow[f ][ l1 ][ l2 ] ;
              sum ( l1 in logicset : l1.dst == v || l1.src == v ) flow[ f ][ l1 ][ l2 ] <= 2 * insurance[ f ][ l2 ] ;
        }

        sum( l1 in logicset : l1.dst == l2.src ) flow[ f ][ l1][ l2 ] == 0;
        sum( l1 in logicset : l1.src == l2.dst ) flow[ f ][ l1][ l2 ] == 0;

        sum( l1 in logicset : l1.dst == l2.dst ) flow[ f ][ l1][ l2 ] == insurance[ f ][ l2 ] ;
        sum( l1 in logicset : l1.src == l2.src ) flow[ f ][ l1][ l2 ] == insurance[ f ][ l2 ] ;

    
    } 

};

float sparecap[ e in edgeset ] = max( f in 1..nfailure ) sum( ll in logicset , l in logicset ) flow[ f ][ l ][ ll ] * reserve[ e ][ l ] * broken[ f ][ ll ]; 
float workcap[  e in edgeset ] = sum ( l in logicset ) reserve[ e ][ l ] ;
float addcap [ e in edgeset ] = maxl( sparecap[e] - ( e.cap + addroute[ e ] - workcap[e] ) , 0 );

float routingcap = sum( e in edgeset ) workcap[ e ] ;
float restorecap = sum( e in edgeset ) sparecap[ e ] ;
float addprotectcap = sum( e in edgeset ) addcap[ e ] ;

float maxfl = sum ( f in 1..nfailure , l in logicset ) insurance[ f ][ l ] ;

float addroutecap = sum( e in edgeset ) addroute[e] ;
int   ncolsel = sum ( c in configset ) ( z[c] > 0.5 ? 1 : 0 );
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


    if ( isModel("RESTORE") ) {
    
        output_section("RESTORE");
        output_value( "MAX-PROTECT-FL" , maxfl );
        output_value( "GAP" , GAP( RELAX[ RELAX_RESTORE ] , cplex.getObjValue()));
        output_value( "SPARE" , restorecap );
        output_value( "WORK" , routingcap );
        output_value( "REDUNDANCY" , restorecap / routingcap );
        output_value( "ADD-PROTECT" ,  addprotectcap );
        output_value( "ADD-PROTECT-PERCENT" ,  addprotectcap/ startcap * 100 );
        output_value( "ADD-ROUTING" , addroutecap );

        output_section("COLUMN");
        output_value( "CONFIG-GEN" , configset.size );
        output_value( "CONFIG-SEL" , ncolsel );

      	for ( var c in configset ){

    		if (z[c].solutionValue > 0.5 ){
    			configsol.addOnly( c );
    		}
	    }

	    setNextModel("MAXWAVE");

    }  else {

		RELAX[ RELAX_RESTORE ] = cplex.getObjValue();

    }
}






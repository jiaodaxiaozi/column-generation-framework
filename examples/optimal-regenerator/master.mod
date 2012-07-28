/*********************************************
 *
 * COLUMN GENERATION - MASTER PROBLEM
 *
 *
 *********************************************/

include "params.mod";

float dummy_cost = 1000000.0;

dvar int+ dummy_var[ 1 .. PERIOD ][ BITRATE ][ NODESET ][ NODESET ]   ;

// number of copies of singlehop configuration
dvar int+ z[ SINGLEHOP_CONFIGINDEX ] ;
// number of copies of multihop configuration
dvar int+ y[ 1.. PERIOD][ MULTIHOP_CONFIGSET  ] ;
// number of available singlehop links from VI to VJ 
dvar int+ provide[ BITRATE ][ NODESET ][ NODESET ];


execute{

    setModelDisplayStatus( 1 );	

    writeln("MASTER SOLVING");	

    writeln(SINGLEHOP_CONFIGINDEX);	
    stop();
}



minimize  sum( c in SINGLEHOP_CONFIGINDEX ) c.cost * z[ c ] +  sum( p in 1..PERIOD , b in BITRATE , vs  in NODESET , vd  in NODESET ) dummy_var[ p ][ b ][ vs ][ vd ] ; 
;


subject to {

    

    forall(  b in BITRATE , vi  in NODESET , vj  in NODESET ) {

       provide[ b ][ vi ][ vj ] == sum( cindex in SINGLEHOP_CONFIGINDEX , c in SINGLEHOP_CONFIGSET , p in SINGLEHOP_SET 
                                    : c.index == cindex.index & c.rate == b && c.indexPath == p.index && p.src == vi.id && p.dst == vj.id ) z[ cindex ] ;
    }

    forall( p in 1..PERIOD , b in BITRATE , vs  in NODESET , vd  in NODESET ) {

    // satisfy request
         sum( m in MULTIHOP_CONFIGSET : m.src == vs.id &&  m.dst == vd.id && m.bitrate == b ) y[ p ][ m ] + dummy_var[ p ][ b ][ vs ][ vd ]
     >=  sum ( dem in DEMAND : dem.period == p  && dem.bitrate == b && dem.src == vs.id && dem.dst == vd.id ) dem.nrequest ;

    } 
	
};


float dummy_measure = sum( p in 1..PERIOD , b in BITRATE , vs  in NODESET , vd  in NODESET ) dummy_var[ p ][ b ][ vs ][ vd ] ;

/********************************************** 

	POST PROCESSING
	
 *********************************************/
 
	
execute CollectDualValues {

	
	
}

execute {

    writeln( "Master Objective: " , cplex.getObjValue(), " Dummy Amount : " , dummy_measure );

}



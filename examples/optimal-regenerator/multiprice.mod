/****************************************************************************
 * COLUMN GENERATION - MULTI HOP WAVELENGTH CONFIGURATION PRICING PROBLEM
 *
 * Author: Hoang Hai Anh
 * Email : hoanghaianh@gmail.com
 *
 ****************************************************************************/

include "params.mod";

string SRC ;
string DST ;
int    period ;
int    bitrate ;

execute {

//	setModelDisplayStatus( 1 );	
	

	// CPLEX settings for PRICING
	
	cplex.intsollim = 1; // take only one solution
	cplex.cutup = 	-0.001 ; // reduced cost 		
	cplex.parallelmode = -1 ; // opportunistic mode
	cplex.threads = 0 ; // use maximum threads
	
 	  var firstItem = Opl.item( CAL_MULTISET , 0 );

    SRC = firstItem.id_src ;
    DST = firstItem.id_dst ;
    period = firstItem.period ;
    bitrate = firstItem.bitrate ;


    CAL_MULTISET.remove( firstItem ); 

    setNextModel("MULTIPRICE");

 	
	if (CAL_MULTISET.size == 0){
		// last instance for multi price
		setNextModel("RELAXMASTER");
	}	

}


dvar  int+ e[ NODESET ][ NODESET ] in 0..1; // edge
dvar  int+ inte[ NODESET ] in 0..1 ; // intermediate nodes

minimize   - sum( vi in NODESET , vj in NODESET : vi.id == SRC && vj.id == DST)  dual_request[ period ][ bitrate][ vi ][ vj ] 
           - sum( vi in NODESET , vj in NODESET)  dual_avail[ period ][ bitrate][ vi ][ vj ] * e[ vi][vj] 
           - sum( v  in NODESET ) inte[ v ] * dual_regen[ period ][ v ] ;

subject to {

	forall ( v in NODESET : v.id != SRC && v.id != DST)
	  sum ( vs in NODESET : v.id != vs.id ) e[ vs ][ v] == sum ( vd in NODESET : v.id != vd.id ) e[ v ][ vd ];

	forall ( v in NODESET : v.id != SRC && v.id != DST)
	  sum ( vs in NODESET : v.id != vs.id ) e[ vs ][ v] == inte[v];

	forall ( v in NODESET : v.id == SRC ){
	
		sum ( vi in NODESET : v.id != vi.id ) e[ vi ][ v] == 0;
		sum ( vo in NODESET : v.id != vo.id ) e[ v ][ vo] == 1;

	}

	forall ( v in NODESET : v.id == DST ){

		sum ( vi in NODESET : v.id != vi.id ) e[ vi ][ v] == 1;
		sum ( vo in NODESET : v.id != vo.id ) e[ v ][ vo] == 0;

	}

   sum ( v in NODESET ) inte[ v ] <= 2 ;	  
  

} 

/********************************************** 

	POST PROCESSING
	
 *********************************************/

execute {
	
	setNextModel("RELAXMASTER");

	writeln("FIND AUGMENTED MULTIHOP FROM " + SRC +  "->" + DST + " IN PERIOD " + period + " WITH BITRATE " + bitrate);
	writeln("Price Objective : " , cplex.getObjValue()  );  
	
	// add new configuration	
	FINISH_RELAX_FLAG.add( 1 );

	var newindex = 0;

	while( MULTIHOP_CONFIGSET.find( newindex ) != null ) newindex ++ ;	
		
	writeln("New Index ", newindex);

    for ( var bb in BITRATE ) {

        if ( bb != bitrate ) 
            continue ;	

        MULTIHOP_CONFIGSET.addOnly(newindex,period,bb,SRC,DST );

        for ( var v in NODESET )
        if ( inte[v].solutionValue > 0.5 ) 
	
        MULTIHOP_INTERSET.addOnly(  newindex, v.id );
	
    	write("PATH :");
        	for ( var vi in NODESET)
	        	for( var vj in NODESET)
		    	if ( e[ vi][vj].solutionValue > 0){
		    		write( vi.id , "=>" , vj.id, " ");
		    		MULTIHOP_LINKSET.addOnly( newindex , vi.id , vj.id );	
		    	}
    	writeln();


        newindex = newindex + 1 ;
    }	
	
}  

  

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

	//setModelDisplayStatus( 1 );	
	

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

    
 	
	if (CAL_MULTISET.size == 0){
		// last instance for multi price
		setNextModel("RELAXMASTER");
	}	else setNextModel("MULTIPRICE");

}


dvar  int+ e[ NODESET ][ NODESET ] in 0..1; // edge
dvar  int+ inte[ NODESET ] in 0..1 ; // intermediate nodes

minimize   - sum( vi in NODESET , vj in NODESET : vi.id == SRC && vj.id == DST)  dual_request[ period ][ bitrate][ vi ][ vj ] 
           - sum( vi in NODESET , vj in NODESET)  dual_avail[ period ][ bitrate][ vi ][ vj ] * e[ vi][vj] ;

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
	  
  

} 

/********************************************** 

	POST PROCESSING
	
 *********************************************/

execute {
	
	writeln("FIND AUGMENTED MULTIHOP FROM " + SRC +  "->" + DST + " IN PERIOD " + period + " WITH BITRATE " + bitrate);
	writeln("Price Objective : " , cplex.getObjValue()  );  
	
	// add new configuration	
	FINISH_RELAX_FLAG.add( 1 );
	
		
	var newindex = MULTIHOP_CONFIGSET.size ;
	writeln("New Index ", newindex);
	MULTIHOP_CONFIGSET.addOnly(newindex,period,bitrate,SRC,DST);

    for ( var v in NODESET )
    if ( inte[v].solutionValue > 0.5 ) 
        MULTIHOP_INTERSET.addOnly( newindex, v.id );
	
	write("PATH :");
	for ( var vi in NODESET)
		for( var vj in NODESET)
			if ( e[ vi][vj].solutionValue > 0){
				write( vi.id , "=>" , vj.id, " ");
				MULTIHOP_LINKSET.addOnly( newindex , vi.id , vj.id );	
			}
			writeln();
	
	
}  

  

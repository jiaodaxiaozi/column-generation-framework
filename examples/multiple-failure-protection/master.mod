

include "params.mod";

float dummy_cost = 100000.0;

float basic_rate_threshold = 0.5 ;

dvar float+ dummy [1.. nfailure ][ requestset ] ;

dvar int+   z[ poolset] ; // number of copy of configurations


execute STARTSOLVEINT {

	
	if ( isModel( "MASTER-FINAL" ) ) {
		
		for ( var f = 1 ; f <= nfailure ; f ++ )
		for ( var r in requestset ){
			dummy[ f ][ r ].LB = 0 ;
			dummy[ f ][ r ].UB = 0 ;
		}	
	
		cplex.tilim = 24 * 3600  ; // limit 2 days searching for integer solution 
		cplex.epgap = 0.01 ;	// stop with small gap

		
		writeln("Final Step !" );
	}
	
	if ( isModel( "MASTER-RELAX-0" ) ) setNextModel("PRICE-0");	
	
	if ( isModel( "MASTER-RELAX-1" ) ) {
		
		consider_cycle[ 0 ] = consider_cycle[ 0 ] + 1 ;	
		
		setNextModel("PRICE-1");  
		
		if ( consider_cycle[ 0 ] == poolcycle.size ) {
		
			consider_cycle[ 0 ] = 0 ;
			if ( running[0] == 0 ) {
			
				setNextModel("PRICE-0");  
			
			} else running[0] = 0 ;
		
		}
			
			
	}
}


minimize sum( c in poolset ) z[c]  *  c.cost  
       + sum( f in 1.. nfailure , r in requestset  ) dummy[ f ][ r ] * dummy_cost ;


subject to {

// provide all recovery
forall( f in 1..nfailure , r in requestset  )
	if ( recovery[ f ][ r ] > 0 )
	ctProtect:
		dummy[ f ][ r ] + sum( c in poolset ) z[c]  * c.provide[ ord( set_failure_request , <f,r> ) ]  >= recovery[ f ][ r ] ;


	
};

float dummy_sum = sum ( f in 1..nfailure , r in requestset ) dummy[ f ][ r ];

/********************************************** 

	POST PROCESSING
	
 *********************************************/
 
	
execute CollectDualValues {


	var f , r , e ;

	for ( f = 1 ; f <= nfailure ; f ++ )
	for ( r in requestset )
	if  ( recovery[ f ][ r ] > 0 )
		dual_protect[ f ][ r ] = ctProtect[ f ][ r ].dual ; 
	else
		dual_protect[ f ][ r ] = 0;
	
}


execute InRelaxProcess {
	
	gencon[ 0 ] = gencon[ 0 ] + 1 ;
	

	if (  isModel("MASTER-RELAX-0") || isModel("MASTER-RELAX-1")  ){

		writeln("------------------------------------------------");

		

		var n_basic = 0;
		var max_reduced = 0 ;
		
		for ( var c in poolset ) {

			if ( z[c].reducedCost == 0.0 ) n_basic ++ ;

			if ( max_reduced <= z[c].reducedCost ){
			
					max_reduced = z[c].reducedCost ;
					enter_point[1] = Opl.ord( poolset , c ) ;

			 } 

		}
	

		enter_point[ 0 ] = (( n_basic / poolset.size ) <= basic_rate_threshold )  && ( max_reduced > 0.0001 ) && (cplex.getObjValue() < preobj[0] ); 

		writeln("Master Objective : " , cplex.getObjValue() , " nconfig = ", poolset.size , " basic-rate = " , 	n_basic/ poolset.size,
			" max-reduced = " , max_reduced  , " ncycle = " , poolcycle.size , " DUMMY SUM = " , dummy_sum );

		preobj[ 0 ] = cplex.getObjValue();


	}	
	
	

}

execute DisplayResult {

	if ( isModel("MASTER-FINAL")  ) {


		var nsel = 0 ;

		for (var c in poolset ){

			if ( z[c].solutionValue > 0 ){
				nsel ++ ;
				writeln("******");
				writeln("CONFIG " , nsel , " is repeated : " , z[c].solutionValue );
				printConfiguration( c ) ;	
			}
		}

        output_section("RESULT");
        output_value("NFAILURE" , nfailure );
        output_value("NREQUEST" , requestset.size );
        output_value("NNODE" , nodeset.size );
        output_value("NEDGE" , edgeset.size );
        output_value("NCYCLE" , poolcycle.size );
        output_value("NCONF"   , poolset.size );
    	output_value("GENCON" , gencon[0] );
    	output_value("NSEL" , nsel );
        output_value("RELAXOBJ" , preobj[0]);
        output_value("INTOBJ" , cplex.getObjValue()); 
        output_value("GAP" , GAP( preobj[0] , cplex.getObjValue() ));

	} // end display 


}





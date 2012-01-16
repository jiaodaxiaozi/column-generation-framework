/*********************************************
 *
 * COLUMN GENERATION - MASTER PROBLEM
 *
 *
 *********************************************/

include "params.mod";

float dummy_cost = 10000.0;

dvar float+ dummy [ 1..nitem ] ; // dummy variables for initial solution
dvar int+   z[ patternset ] ; // number of copy of configurations



execute{

	

	if ( isModel( "FINAL" ) ) {
		
		// CPLEX setting parameters for solving MIP
		
		cplex.tilim = 3600  ; // limit 1h searching for integer solution 
		cplex.epgap = 0.03 ;	// stop with small gap
		cplex.parallelmode = -1 ; // opportunistic mode
		cplex.threads = 0 ; // use maximum threads

	}
	
	if ( isModel("ROOT" ) ) {
	
		setNextModel( "PRICE"  );
	
	}
	
	
}


minimize sum( c in patternset ) z[c]  
       + sum( i in 1..nitem ) dummy[ i ] * dummy_cost ;


subject to {

	// provide all needed item
	forall( i in 1..nitem )
	ctDemand:
			dummy[ i ] + sum( c in patternset ) z[c] * c.a[ i ]  >= item_demand[ i ];
	
};



/********************************************** 

	POST PROCESSING
	
 *********************************************/
 
	
execute CollectDualValues {

	for ( var i = 1 ; i <= nitem ; i ++ )
		dual_demand[ i ] = ctDemand[ i ].dual;
	
	
}

execute InRelaxProcess {


	if ( isModel( "ROOT" ) ){

		writeln("Master Objective : " , relaxobj[0] , " number of patterns = ",  patternset.size );
		relaxobj[ 0 ] = cplex.getObjValue();
		
		
	}	

}

execute DisplayResult {

	if (isModel( "FINAL") ) {
	
		writeln();
		lineSep( " FINAL SOLUTION "  , "-" );
		writeln();

		var nconfig = 0 ;
		for (var c in patternset )
		if ( z[c].solutionValue > 0 ){
			nconfig = nconfig + 1 ;
			writeln("PATTERN " , nconfig , " is repeated : " , z[c].solutionValue );
			printPattern( c ) ;
		}

		writeln();
	
		output_section("RESULT");

	        writeln("Relax = " , relaxobj[0] );
        	writeln("Int   = " , cplex.getObjValue());
	        writeln("GAP : " , GAP( relaxobj[0]  , cplex.getObjValue() ));

		output_value( "RELAX" , relaxobj[0] );
		output_value( "OBJ" , cplex.getObjValue());
		output_value( "GAP" , GAP( relaxobj[0]  , cplex.getObjValue() ));

	} // end display 


}





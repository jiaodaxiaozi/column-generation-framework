include "params.mod";

dvar int+ z[ CONFIGSET ] ;
dvar float+ dummy[ DEMAND ] ;

execute {


	writeln("SOLVE " , getModel() );

}

minimize sum( c in CONFIGSET ) z[c] * c.cost + sum( d in DEMAND ) dummy[ d ] * 100000;

subject to {

	ctWavelength :
		sum ( c in CONFIGSET ) z[c] <= NWAVELENGTH ;

	forall( d in DEMAND )
		ctProvide:
			sum( c in CONFIGSET ) z[ c ] * c.provide[ d ] + dummy[ d ] >= d.nrequest ;

}


float dummysum = sum ( d in DEMAND ) dummy[ d ] ;
int   usedwave = sum ( c in CONFIGSET ) z[c] ;
execute {

	writeln("Master Objective : " , cplex.getObjValue() , " Dummy : " , dummysum );

	// copy duals
	dual_wave[ 0 ]  = ctWavelength.dual ;

	for ( var d in DEMAND ){


		dual_provide [ d ] = ctProvide[ d ].dual ;

	}

	if ( isModel("RELAXMASTER") ){
		setNextModel("PRICE");
		RELAXOBJ[0] = cplex.getObjValue();

	}
	

	if ( isModel("FINAL") ) {

		writeln("INTOBJ   :" , cplex.getObjValue());
		writeln("RELAXOBJ :" , RELAXOBJ[ 0 ]  );
		writeln("GAP      :" , GAP( cplex.getObjValue()  , RELAXOBJ[0] )) ;
        writeln("USED WAVE:" , usedwave );
	}
}

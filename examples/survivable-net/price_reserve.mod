include "params.mod";

execute {


	writeln("Start DIJSTRAs");
	var ret = 0 ;
	for ( var ll in logicset ) {

		if ( DIJKSTRA( ll , false , false )) ret = ret + 1 ;
	}

	writeln( "Improved Price : " , ret );
	
	

    if ( ret > 0 ) setNextModel("RELAX-RESERVE"); else setNextModel("RESERVE");

}




include "params.mod";

execute {


	writeln("Start DIJSTRAs");
	var ret = 0 ;
	for ( var ll in logicset ) {

		if ( DIJKSTRA( ll , false , true , true )) ret = ret + 1 ;
	}

	writeln( "Improved Price : " , ret );
	
	

    if ( ret > 0 ) setNextModel("RELAX-FINAL"); else setNextModel("FINAL");

}




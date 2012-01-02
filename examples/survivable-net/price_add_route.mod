include "params.mod";

execute {




	var ret = 0 ;
	for ( var ll in logicset ) {

		if ( DIJKSTRA( ll , false , false)) ret = ret + 1 ;

	}

	writeln( "Improved Price : " , ret );
	
	

    if ( ret > 0 ) setNextModel("RELAX-ADD-ROUTE"); else setNextModel("ADD-ROUTE");

}




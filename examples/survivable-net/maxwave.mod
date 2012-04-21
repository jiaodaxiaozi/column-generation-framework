
include "params.mod";

int   conflict[ c1 in  configsol ][ c2 in configsol ] = sum(  r1 in routeset , r2 in routeset : r1.config_id == c1.id  &&
								r2.config_id == c2.id  ) (r1.edge_id == r2.edge_id ? 1:0) > 0;

int   color[ configsol ] ;
float cape [ edgeset ] ;


execute STARTSOLVEINT {

	writeln("ANALYSIS WAVELENGTH");
	writeln("number of configurations : " , configsol.size );

	var nwave = 0;

	for ( var c in configsol ) color[ c ] = 0 ;
	for ( var e in edgeset   ) cape[ e ] = 0 ;

	function visit(  wave ) {

		var setup = 0 ;

		for ( var c1 in configsol )
		if ( color[ c1 ] == 0 ) {
			var ok = 1 ;

			for ( var c2 in configsol )
			if ( color[c2 ] == wave && conflict[ c2 ][ c1 ] > 0 )
				ok = 0;

			if ( ok == 1 ){ 
				color[ c1 ] = wave ;
				setup += 1 ;

				for ( e in edgeset ) 
				for ( var r in routeset )
				if  ( r.config_id == c1.id && r.edge_id == e.id )
					cape[ e ] += 1 ;	
			}
		}

		return setup ;
	}

	while ( 1 ) {

		nwave += 1 ;
		if ( visit( nwave ) == 0 ) break;
		
	}
	nwave -= 1 ;	

		writeln("WAVELENGTH="  , nwave  );
		
		var ave = 0 ;
		var std = 0 ;

		 for ( e in edgeset ){

			ave += cape[ e ] ;
		}
		
		ave = ave / edgeset.size ;
		writeln("AVE WAVE = " , ave );
		for ( e in edgeset ) {
			std += ( cape[ e ] - ave )*( cape[ e] - ave ) ;
		}

		std = Opl.sqrt(  std / edgeset.size ) ;
		writeln("STD WAVE = " , std ) ;

        output_section( "WAVE" );
		output_value( "NWAVE" , nwave );
		output_value( "AVE-WAVE" , ave );
		output_value( "STD-WAVE" , std );
	 
}

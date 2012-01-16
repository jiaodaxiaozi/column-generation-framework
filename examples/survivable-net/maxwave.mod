
include "params.mod";


{config_record} consider = configsol diff removesol ;

int   conflict[ consider ][ consider ] ;

range configrange = 1..card( consider ) ;
dvar int+  color[ configrange ][ consider ] in 0..1;
dvar int+  hist [ configrange  ];



execute STARTSOLVEINT {

	writeln("number of configurations : " , consider.size );
	// creating conflict
	for ( var c1 in consider )
	for ( var c2 in consider ){

		conflict[ c1 ][ c2 ] = 0 ;

		if ( c1.id < c2.id )
		for ( var e in edgeset )
		if ( c1.routing[ e ] == 1 && c2.routing[ e ] == 1 )
			conflict[ c1 ][ c2 ] = 1 ;

	}

}


maximize hist[1] ;

subject to {

	forall ( h in configrange , c1  in consider , c2 in consider : conflict[c1][c2]==1 )
		( color[h ][ c1 ] + color[ h ][c2] ) <= 1;
	
	forall( c in consider )
		sum( h in configrange ) color[h][c] == 1;

	forall( h in configrange )
		hist[ h ] == sum( c in consider ) color[ h ][ c ];

};

execute {

	for ( var c in consider )
	if ( color[ 1][c ].solutionValue > 0.5 ){
		removesol.addOnly( c ) ;

		for ( var e in edgeset )
			capwave[ e ] += c.routing[e ] ;
	//	write( c.id , " " );
	}
	//writeln();
	NWAVE[ 0 ] = NWAVE[ 0 ] + 1 ;
	if ( hist[1].solutionValue < consider.size )
		setNextModel("MAXWAVE");
	else {
		writeln("WAVELENGTH=" , NWAVE[ 0 ] );
		
		var ave = 0 ;
		var std = 0 ;

		 for ( e in edgeset ){

			ave += capwave[ e ] ;
		}
		
		ave = ave / edgeset.size ;
		writeln("AVE WAVE = " , ave );
		for ( e in edgeset ) {
			std += ( capwave[ e ] - ave )*( capwave[ e] - ave ) ;
		}

		std = Opl.sqrt(  std / edgeset.size ) ;
		writeln("STD WAVE = " , std ) ;

		output_value( "NWAVE" , NWAVE[0] );
		output_value( "AVE-WAVE" , ave );
		output_value( "STD-WAVE" , std );
	}
	 
}

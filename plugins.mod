
execute{

//// SYSTEM AVATAR //// 

function AVATAR() {

	return "[:>]" ;	
}

//// COMPUTE GAP BETWEEN TWO NUMBERS ////	
function GAP( relaxObj , intObj ) {	
	
	return Opl.abs( intObj - relaxObj ) / ( Opl.abs( relaxObj ) + 1.0e-6 ) * 100.0;		
	
}
	
//// MARK TIME MOMENT ////
function  timeMarker() {

	return (new Date());
}

//// ELAPSED TIME FROM MARKED ////
function elapsedTime( previous ) {

	var currentMoment = new Date();
	return Opl.round(( currentMoment - previous ) / 1000.0 );
}


//// LINE SEPARATOR //// 

function lineSep( label  , sep ) {
	
	var half_line_sep_length = 50 ;
	var halflen  =  half_line_sep_length -  label.length / 2 ;
	var i ;
	for ( i = 1 ; i <= halflen ; i ++ ) write( sep );
	write( label );
	
	for ( i = 1 ; i <= halflen ; i ++ ) write( sep );	
	writeln();
	
}

////  LEFT/RIGHT ALIGN WRITE ////

function leftWrite( st , len ) {

	
	write( st ) ;
	
	var miss = ( len - st.toString().length ) >= 0 ? ( len - st.toString().length ) : 0 ;
	for ( var i = 0 ; i < miss ; i ++ ) write(" " );

}

function rightWrite( st , len ) {

	var miss = ( len - st.toString().length ) >= 0 ? ( len - st.toString().length ) : 0 ;
	for ( var i = 0 ; i < miss ; i ++ ) write(" " );
	
	write( st ) ;

}



//// ASSERT EXISTED FILE ////

function assertExisted( fname ) {

	// check existed file ?
	var f = new IloOplInputFile( fname );
	
	if ( ! f.exists ) {
	
		writeln( AVATAR() , " file: " , fname , " does not exist ! " );
		writeln();
		stop();
	}
	
	f.close();
}





}; // end execute

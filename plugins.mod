
execute{

//// SYSTEM AVATAR //// 

function AVATAR() {

	return "[:>]" ;	
}

//// COMPUTE GAP BETWEEN TWO NUMBERS ////	
function GAP( relaxObj , intObj ) {	
	
	return Opl.abs( intObj - relaxObj ) / ( Opl.abs( relaxObj ) + 1.0e-6 ) * 100.0;		
	
}
	

//// FILTER COLLECTION ////
//
//
// remove elements from a collection where removeField=removeValue
//
//
function filterCollection( theCollect , removeField , removeValue , buffer  ){

	
	buffer.clear();

	var nOrigin = theCollect.size ;	
	var nKeep = 0 ;
	for ( var it in theCollect )
	if ( it[ removeField ] != removeValue )
	{ 
		buffer.add( it );
		nKeep = nKeep + 1 ;
	}
	

	theCollect.clear();
	for ( it in buffer )
		theCollect.add( it ) ;

	if ( nKeep != theCollect.size ) {
		writeln("Size is not correct " , nKeep , " <> " , theCollect.size );
		stop();
	}

	for ( it in theCollect )
	if ( it[ removeField ] == removeValue ){
		writeln("not clearly remove " ,removeField , " = " , removeValue );
		stop();
	}
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

//// SAVE VARIABLE TO FILE ////
function saveVarToFile( statefile ,v  ){

    var ofile = new IloOplOutputFile( statefile );

    for ( var item in thisOplModel.dataElements )
    if ( v == item )
        ofile.writeln( item , "=" , thisOplModel.dataElements[  item] , ";");

    ofile.close();

};

//// SAVE STATE TO FILE ////
function saveStateToFile( statefile   ){

    var ofile = new IloOplOutputFile( statefile );

    for ( var item in thisOplModel.dataElements )
        ofile.writeln( item , "=" , thisOplModel.dataElements[  item] , ";");

    ofile.close();

};


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


///// RETURN MAX( n , len( st ) ) //////
function maxLength( n, st  ) {
  return  n < st.toString().length ? st.toString().length : n ;
}

/*
///////// GET CURRENT ABSOLUTE PATH //////////   
function getPWDPath(){

		if ( ! IloOplGetEnv("PWD") ) return "./" ; // if on windows system
			else
		return IloOplGetEnv("PWD") + "/"; // on linux

} 

*/

}; // end execute

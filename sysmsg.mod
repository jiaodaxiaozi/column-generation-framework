string _MODEL_         = ... ; // current solving model
string _PARAM_         = ... ; // current model parameter

string _NEXT_MODEL_    = ... ; // next model to solve
string _NEXT_PARAM_    = ... ; // next model's parameter

string _MODEL_LOG_     = ... ; // model log file

string _PARAM_SEP_     = ":" ; // separator for arrays

execute {

	//// IS THAT MODEL ////
	function isModel( m ){
	
		return getModel() == m;
	
	}
	
	//// GET CURRENT MODEL ////
	function getModel() {
	
		return _MODEL_ ;
	}


	function setModelLog( log ) {

		_MODEL_LOG_ = log ;
		

	}
	
	//// GET CURRENT PARAMETER ////

	/* return Arrays of Integer */
	function getModelParam() {

		// convert back _PARAM_ to Arrays


		var decode = _PARAM_.split( _PARAM_SEP_ );

		for ( var i = 0 ; i < decode.length ; i ++ ) 
			decode[ i ] = parseInt( decode[i] ); 
		

		return decode ;
	}
	
	
	//// NEXT MODEL TO SOLVE ////

	/* p is Arrays of Integer */
	function setNextModel( m , p ) {
	
		_NEXT_MODEL_ = m ;

		if ( typeof(p) == "undefined" ) p = new Array();
	
		_NEXT_PARAM_ = p.join( _PARAM_SEP_ ) ;


	}
	
	

}


include "plugins.mod" ; 


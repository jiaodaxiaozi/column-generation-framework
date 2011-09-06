string _MODEL_        = ... ; // current solving model

string _NEXT_MODEL_    = ... ; // next model to solve
string _NOSOL_MODEL_   = ... ; // in case of no solution, which model to solve next


execute {

	function isModel( m ){
	
		return _MODEL_ == m;
	}

	function solNextModel( m ) {
	
		_NEXT_MODEL_ = m ;
	}
	
	function nosolNextModel( m ) {
		_NOSOL_MODEL_ = m ;
	}


}





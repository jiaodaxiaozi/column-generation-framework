string _MODEL_         = ... ; // current solving model
string _NEXT_MODEL_    = ... ; // next model to solve



execute {

	//// IS THAT MODEL ////
	function isModel( m ){
	
		return getModel() == m;
	
	}
	
	//// GET CURRENT MODEL ////
	function getModel() {
	
		return _MODEL_ ;
	}
	
	//// NEXT MODEL TO SOLVE ////
	function setNextModel( m ) {
	
		_NEXT_MODEL_ = m ;
	}
	
	

}


include "plugins.mod" ; 


string _MODEL_          = ... ; // current solving model
string _NEXT_MODEL_     = ... ; // next model to solve
int    _MODEL_DISPLAY_STATUS_   = ... ; // model show status


execute {

    

    //// IS THAT MODEL ////
    function isModel( m ){
    
        return getModel() == m;
    
    }
    
    //// GET CURRENT MODEL ////
    function getModel() {
    
        return _MODEL_ ;
    }

    
    ///// MODEL STATUS //////
    function setModelDisplayStatus( status ) {
    
        _MODEL_DISPLAY_STATUS_ = status ;
    }
    
    //// NEXT MODEL TO SOLVE ////
    function setNextModel( m  ) {
    
        _NEXT_MODEL_ = m ;

    }

}


include "plugins.mod" ; 


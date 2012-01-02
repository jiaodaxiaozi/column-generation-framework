string _MODEL_         = ... ; // current solving model
string _NEXT_MODEL_    = ... ; // next model to solve
string _MODEL_LOG_     = ... ; // model log file
int    _MODEL_STATUS_  = ... ; // model show status


execute {

    

    //// IS THAT MODEL ////
    function isModel( m ){
    
        return getModel() == m;
    
    }
    
    //// GET CURRENT MODEL ////
    function getModel() {
    
        return _MODEL_ ;
    }

    //// SET MODEL EXPORT ////
    function setModelLog( log ) {

        _MODEL_LOG_ = log ;
        

    }
    
    ///// MODEL STATUS //////
    function setModelStatus( status ) {
    
        _MODEL_STATUS_ = status ;
    }
    
    //// NEXT MODEL TO SOLVE ////
    function setNextModel( m  ) {
    
        _NEXT_MODEL_ = m ;

    }
    
    

}


include "plugins.mod" ; 


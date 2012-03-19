string _MODEL_          = ... ; // current solving model
string _NEXT_MODEL_     = ... ; // next model to solve
int    _MODEL_STATUS_   = ... ; // model show status

string _OUTFILE_        = ... ; // output filename

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
    function setModelStatus( status ) {
    
        _MODEL_STATUS_ = status ;
    }
    
    //// NEXT MODEL TO SOLVE ////
    function setNextModel( m  ) {
    
        _NEXT_MODEL_ = m ;

    }

	


    ///// READ CONTENT OF OUTPUT FILE //////
    function read_output_content() {

        var s = new IloOplOutputString();
		
		if ( _OUTFILE_ == "" ) return s ;

		var outname = getPWDPath() + _OUTFILE_ ; 
        var f = new IloOplInputFile( outname );
		  
		// check if file is existed			
		if ( f.exists ) {
		
			while (!f.eof) {
				s.writeln(f.readline());
			}

		
		
		}
			f.close();

		return s; 
	
    }
	
	//// EMPTY OUTPUT ////
	function empty_output() {
	
		write_output_content( new IloOplOutputString() );
	}

	//// WRITE CONTENT TO OUTPUT FILE ////
    function write_output_content( content ) {
	
		if ( _OUTFILE_ == "" ) return ;

		var outname = getPWDPath() + _OUTFILE_ ; 
		var f = new IloOplOutputFile();
	
		f.open( outname );
		f.write( content.getString() );
		f.close();     
    }

    //// OUTPUT SECTION ////
    function output_section( txt ) {

		var content = read_output_content() ;

		content.write( "[" + txt + "]" ) ; 
		write_output_content( content ); 

    }    
   
    ///// OUTPUT VALUE ////
    function output_value( param , value ) {
	
		var content = read_output_content() ;

		content.write( param + "=" + value ) ; 
		write_output_content( content ); 

    } 

}


include "plugins.mod" ; 


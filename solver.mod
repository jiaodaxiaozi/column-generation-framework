/*********************************************
 * COLUMN GENERATION SOLVER SYSTEM
 *
 * (C) Hoang Hai Anh, 2011
 * Email : hoanghaianh@gmail.com
 *
 *********************************************/

include "plugins.mod" ; 
 
string input = "" ;
string output= "" ;

 
main {



/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * CONSTANTS
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/

var parameter_file    = "params.mod"  ;
var parameter_data    = "params.dat"  ;
var model_define_file = "model.ini"   ;    
var __ROOT__          = "ROOT"        ;

var runCplex          = new IloCplex(); // for saving default parameters


/////// SETTING NEXT STATE //////////
function nextState( nextObj , curObj ) {

    if ( curObj == null ) {
    
        nextObj._NEXT_MODEL_  = "" ;    
        nextObj._MODEL_STATUS_= 0  ;    
	
    } else {
   
        nextObj._MODEL_       = curObj._NEXT_MODEL_ ;    
        nextObj._MODEL_STATUS_= curObj._MODEL_STATUS_  ;
    }

     nextObj._OUTFILE_ = thisOplModel.output ; 
}
    
/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * DEFINE MIP MODEL CLASS 
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/


 function MIPMODEL( id , fname , relax ){
 
    //// CONSTRUCTOR ////
    
    assertExisted( fname );
 
    this.mipid          = id   ; // id of this model
    this.mipsource      = new IloOplModelSource( fname ); // init source file 
    this.mipdefinition  = new IloOplModelDefinition( this.mipsource ); // init definition    
    
    this.ncall          = 0    ; // number of calling time
    this.acctime        = 0    ; // accumulated running time in seconds
    this.solvetime      = 0    ; // solving time 
    this.relax          = relax; // relax this model or not
            
    // methods
    this.mipsolve         = mipsolve    ;

            
 }


 //// SOLVING MODEL ////
 function mipsolve(  ) {
 
    var timeMark = timeMarker(); // mark time moment
    this.ncall ++ ; // update number of calling 

    // first model's parameters to default
    cplex.clearModel();
    for ( var p in cplex ){
      cplex[ p ] = runCplex[ p ]	
    }

    cplex.tilim = 3600 * 48;  // 2 days solving 
    cplex.epgap = 0.0001 ;      // 1 percent


    cplex.workdir = "/lscratch";
    cplex.workmem = 1024 * 40  ;
    cplex.nodefileind = 3 ;
    cplex.trelim  = 1024 * 60 ;

    cplex.parallelmode = -1 ; // opportunistic mode
    cplex.threads = 0 ; // use maximum threads

    var theopl         = new IloOplModel( this.mipdefinition , cplex ) ;  // create execution object    


    theopl.settings.mainEndEnabled = true ;
 
    // reset next model
    nextState( globalData , null );
    
    theopl.addDataSource( globalData ) ;    // add data source 
    theopl.generate() ; // generate execution object
    
 
    if ( this.relax )    theopl.convertAllIntVars() ;    // relax model
    
    if ( cplex.solve() )      
        theopl.postProcess() ;  // call post process    

    // next model to solve
    nextState( globalData , theopl );
 
    // update information
    this.solvetime = elapsedTime( timeMark ); // running time
    this.acctime += this.solvetime ; // accumulated running time                
 
    
    // display result
    if ( globalData._MODEL_STATUS_ > 0 ) {
        write( AVATAR() , " solve " + this.mipid  + " (\"" + this.mipsource.name + "\"" + ( this.relax ? ",\"relax\"" : "" ) + ") => " );
        writeln( " called: " , this.ncall , " runtime: ", this.solvetime , " acc. time: " , this.acctime  );    
    }
   
 
    theopl.end();
 } 
 


/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * FUNCTIONS
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/




//// INDEX OF MODEL BY NAME ////

function indexModel( m ) {
    
    // find execute model        
    for ( var i = 0 ; i < lstModel.length ; i ++ )
    if (  lstModel[i].mipid == m )
        return lstModel[ i ] ;
            
    return null ;
}

///// ASSERT EXIST MODEL ///
function assertModel( m ) {

    if ( indexModel(m)==null ) {
    
        writeln( AVATAR() , " no model with id: " ,m , " !" );
        writeln();
        stop();
    }
    
}


//// READ MODEL DEFINITION FILE ////
function readModelDefinition() {

    var  TERM_MODEL = "MODEL" ;
    var  TERM_RELAX = "RELAX" ;
    
    var f = new IloOplInputFile( );
    f.open(model_define_file );
    
    writeln();
    lineSep(" MODEL DEFINTION ",".");
    writeln();
    
    while (!f.eof) {
      
      var line  = f.readline();      // one line 
      var pieces = line.split(" "); // split into term
      
      var terms = new Array();

      for ( var i = 0 ; i < pieces.length ; i ++ ){
      
        // split again by tab

        var tabs = pieces[ i ].split("\t");

        for ( var j = 0 ; j < tabs.length ; j ++ )
 
            // not empty term
            if ( tabs[ j ].length ) terms[ terms.length ] = tabs[ j ] ;

      }
      
      // [MODEL] //
      if ( terms[0] == TERM_MODEL ) {
       
        var isrelax = ( terms[3] == null ) ? false : terms[3].toUpperCase() == TERM_RELAX;
        
        
        writeln( "[" + terms[0] + "]" , " >>> " , terms[1]  , " >>> " , terms[2] , " " , isrelax ? "(relax)" : ""  );        
        lstModel[ lstModel.length ] = new MIPMODEL( terms[1] , terms[2] , isrelax ); // create model
        
      }

    } // end while

    f.close();    
    
    
}
    
/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * DISPLAY STARTING INFORMATION
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/

    lineSep(" COLUMN GENERATION SOLVER ","=") ;
    writeln();    
    writeln();
    
    if ( thisOplModel.input == "" ) {   writeln( AVATAR() , "  input need to be specified ( -D input=filename ) " ); writeln(); stop(); }    
    
	writeln( AVATAR() , " PATH         : " , getPWDPath() );	
    writeln( AVATAR() , " INPUT        : " , thisOplModel.input  );
    
    if ( thisOplModel.output != "" ){		
		writeln( AVATAR() , " OUTPUT       : " , thisOplModel.output ); 
    }
   
        

    assertExisted(  model_define_file );
    assertExisted(  parameter_file );
	assertExisted(  parameter_data );
    assertExisted(  thisOplModel.input );    

    writeln( AVATAR() , " PARAMETER DEFINITION   : " , parameter_file );
	writeln( AVATAR() , " PARAMETER DATA         : " , parameter_data );
    writeln( AVATAR() , " MODEL DEFINE           : " , model_define_file );
    

    
/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * INIT MODELS & DATA
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/
    
    
    // create user data    
    var _userData = new IloOplDataSource( thisOplModel.input); 
	
	// create parammeter data
	var _paramData = new IloOplDataSource( parameter_data ); 
    
    // create system data
    var _sysData = new IloOplDataElements();
    
    nextState( _sysData , null );

     _sysData._MODEL_    = __ROOT__ ;

    
    // load global data
    var globalSource = new IloOplModelSource( parameter_file );
    var globalDef    = new IloOplModelDefinition( globalSource );    
    var globalOpl    = new IloOplModel( globalDef , cplex ) ;
    
    globalOpl.addDataSource( _userData );
	globalOpl.addDataSource( _paramData );
    globalOpl.addDataSource( _sysData  );                
    globalOpl.generate();
            
    // create global data
    var globalData = globalOpl.dataElements ;
    
    // create list of models
    var lstModel = new Array();
    
    
 
/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * SOLVING MODELS
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/

 readModelDefinition(); // read model definition 
 
 empty_output();
 
 assertModel( __ROOT__ );

 
 var   starting_process_moment =  timeMarker(); 
 
 lineSep(" PROCESSING " , "=" );
 writeln();
 while ( globalData._MODEL_ ){
     
    var callModel = indexModel( globalData._MODEL_ );
    
    // not found any model
    if ( callModel == null ) {
      writeln( AVATAR() , " no model with id: " , globalData._MODEL_ , " !" );
      stop();
    } else callModel.mipsolve();
      

    
 } // end while
 
 
 

/*---------------------------------------------------------------------------------------------------------------------------
 *
 *
 * SUMMARY
 *
 *
 *--------------------------------------------------------------------------------------------------------------------------*/


 

var elapsed_runtime = elapsedTime( starting_process_moment );

lineSep(" PERFORMANCE INFORMATION " ,"=" );
writeln();

// estimate size
var m ;
var model ;



var txt_id_size = maxLength( 0 , "MODEL" );
var txt_call_size = maxLength( 0 , "CALL" );
var txt_total_size = maxLength( 0 , "TOTAL-TIME" );
var txt_mean_size = maxLength( 0 , "MEAN-TIME" );
var txt_relax_size = maxLength( 0 , "RELAX" );
var txt_source_size = maxLength( 0 , "SOURCE" );

for ( m = 0 ; m < lstModel.length ; m++ ){

    model = lstModel[ m ] ;
    
    txt_id_size   = maxLength( txt_id_size , model.mipid ) ;    
    txt_call_size = maxLength( txt_call_size , model.ncall ) ;     
    txt_total_size= maxLength( txt_total_size , model.acctime ) ;     
    txt_mean_size= maxLength( txt_mean_size , model.acctime /  model.ncall  ) ;     
    txt_relax_size= maxLength( txt_relax_size , model.relax  ) ;     
    txt_source_size= maxLength( txt_source_size , model.mipsource.name  ) ;     
}

leftWrite( "MODEL" , txt_id_size + 1 );
leftWrite( "CALL" , txt_call_size + 1); 
leftWrite( "TOTAL-TIME" , txt_total_size + 1 );
leftWrite( "MEAN-TIME" , txt_mean_size + 1 );
leftWrite( "RELAX" , txt_relax_size + 1 );
leftWrite( "SOURCE" , txt_source_size + 1 );

writeln();

leftWrite( "-----" , txt_id_size + 1 );
leftWrite( "----" , txt_call_size + 1 ); 
leftWrite( "----------" ,txt_total_size + 1 ); 
leftWrite( "---------" , txt_mean_size + 1 );
leftWrite( "-----" , txt_relax_size + 1 );
leftWrite( "------" , txt_source_size + 1 );
writeln();


for ( m = 0 ; m < lstModel.length ; m++ ){

 model = lstModel[ m ] ;

leftWrite( model.mipid , txt_id_size + 1 );
leftWrite( model.ncall , txt_call_size + 1 );
leftWrite( model.acctime ,txt_total_size + 1 );
leftWrite( model.acctime /  model.ncall ,txt_mean_size + 1 ); 
leftWrite( model.relax ,txt_relax_size + 1 );
leftWrite( model.mipsource.name ,txt_source_size + 1 );

	writeln();
	
	output_section( "RUNTIME-" + model.mipid );
	output_value( "CALL" , model.ncall );
	output_value( "TOTALTIME" , model.acctime );

}
  
writeln();
lineSep("" ,"-");    
writeln("OVERALL-RUNTIME: " , elapsed_runtime );
lineSep("" ,"-");    
writeln();

output_section( "RUNTIME" );
output_value( "TOTALTIME" , elapsed_runtime );

// free memory
runCplex.end();

} 

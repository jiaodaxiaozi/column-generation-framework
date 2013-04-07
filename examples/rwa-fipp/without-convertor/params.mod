

include "../../../sysmsg.mod" ; // include this line in every global configuration file


int NWAVELENGTH = ... ;


{ string  } NODESET = ...; // set of nodes

// set of directed edges generated from undirected edges
tuple directed_edge_record {

    string id  ;
    string src ; // id of source
    string dst ; // id of destination
}

// set of directed edges
{ directed_edge_record }  EDGESET    = ... ;


tuple demand_record {

    string src   ;  // source  
    string dst   ;  // destination
    int nrequest ;  // number of requests
};

{ demand_record } DEMAND =...; // set of all demands


tuple config_record {

    int   index;
	float cost ;
	float provide[ DEMAND ];	
    float wcost ;
    float pcost ;
    int   working[ EDGESET ];
    int   protecting[ EDGESET ];
}


{ config_record } CONFIGSET = ... ;
{ config_record } CONFIGSET_TMP = ... ;

float dual_wave[0..0] = ... ;
float dual_provide[ DEMAND ] = ... ;
float RELAXOBJ[0..0] = ... ;

int   EXTRA_CALL[ 0..0 ] = ... ;

int   NARROW_FLOW[ DEMAND ][ EDGESET ] = ... ;


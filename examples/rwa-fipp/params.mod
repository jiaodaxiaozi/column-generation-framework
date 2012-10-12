

include "../../sysmsg.mod" ; // include this line in every global configuration file


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


	float cost ;
	float provide[ DEMAND ];	

}

{ config_record } CONFIGSET = ... ;

float dual_wave[0..0] = ... ;
float dual_provide[ DEMAND ] = ... ;
float RELAXOBJ[0..0] = ... ;

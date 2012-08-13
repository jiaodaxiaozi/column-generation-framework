

include "../../sysmsg.mod" ; // include this line in every global configuration file

// a node description 
tuple node_record  {

    string id ; // id of node
    float  pop; // population at node

};

{ node_record } NODESET = ...; // set of nodes

// an undirected edge description
tuple undirected_edge_record {

    string id_va; // id of first vertex
    string id_vb; // id of second vertex

    float distance; // distance between two vertexes
};

// set of undirected edges
{ undirected_edge_record }  UNDIRECTED_EDGESET = ...;

// set of directed edges generated from undirected edges
tuple directed_edge_record {

    string src ; // id of source
    string dst ; // id of destination
    float  distance ; // distance

}

// set of directed edges
{ directed_edge_record }  DIRECTED_EDGESET    = ... ;


int PERIOD = ...; // number of periods
int KPATH_PARAM = ... ; // number of k shortest paths between source and destination
{int} BITRATE = { 10 , 40 , 100 };  // bitrate
{int} TRSET = { 750 , 1500 , 3000 }; // transmission range

float REGENERATOR_COST[ BITRATE ][ TRSET ] = ...; // generate cost of a regenerator of BITRATE and TRANSMISSION RANGE

tuple demand_record {

    int period   ;  // demand at period
    int bitrate  ;  // bitrate
    string src   ;  // source  
    string dst   ;  // destination
    int nrequest ;  // number of requests
};

{ demand_record } DEMAND =...; // set of all demands

float SEED_TRAFFIC = ... ; // unit traffic demand per population

/* for k-shortest path calculation */

tuple SRCDST_record {

    string id_src ;
    string id_dst ;

}


{ SRCDST_record }  K_SDSET = ... ;


/* for multihop calculation */
tuple CALHOP_record {
    string id_src ;
    string id_dst ;
    int    period ;
    int    bitrate ;
}

{ CALHOP_record }   CAL_MULTISET = ... ;


tuple path_record {

    int    index ; // index of single hop lightpath
    string src ;   // source of that lightpath
    string dst ;   // destination of that lightpath
    float  pathLength ; // length of lightpath
}

tuple path_edge_record {

    int indexPath ; // index of single hop lightpath
    int indexEdge ; // index of edge belongs to this lightpath
}


{ path_record } SINGLEHOP_SET = ... ; // set of all single-hop lightpath 
{ path_edge_record } SINGLEHOP_EDGESET = ... ; // set of edges of singlehop lightpaths

// description of a single-hop lightpath with a bitrate in a wavelength configuration
tuple  wavelength_configuration_record {

    int     index ;
    int     indexPath ;
    int     bitrate ;
};

// set of all single hop lightpaths in a wavelength configuration
{ wavelength_configuration_record } WAVELENGTH_CONFIGSET = ... ;

// description of wavelength configuration with cost
tuple   singlehop_configindex_record {

    int index ;
    float cost;
};

// set of single hop configuration 
{ singlehop_configindex_record } WAVELENGTH_CONFIGINDEX = ... ;

// description of multiple hop lightpaths
tuple multihop_configuration_record {

    int index  ; // index of multihop configuration 
    int period ; // period of multihop configuration
    int bitrate; // bitrate of multiple hop lightpaths
    string src ; // source of multiple hop lightpaths
    string dst ; // destination of multiple hop lightpaths
};

// one virtual link of multihop configuration
tuple multihop_link_record {

    int index ;
    string id_vi ; 
    string id_vj ;
};

// set of all multiple hop lightpaths
{ multihop_configuration_record } MULTIHOP_CONFIGSET = ... ;
// set of all multiple hop linkset
{ multihop_link_record } MULTIHOP_LINKSET = ... ;

{ int } FINISH_RELAX_FLAG = ... ;  // finish relax process

// dual provide
float dual_provide[ BITRATE ][ NODESET  ][ NODESET ] = ... ;
// dual requests
float dual_request[ 1..PERIOD ][ BITRATE][ NODESET][ NODESET] = ... ;
// dual availability
float dual_avail[ 1..PERIOD ][ BITRATE][ NODESET][ NODESET] = ... ;
// dual cost
float dummy_cost = 10000000.0;
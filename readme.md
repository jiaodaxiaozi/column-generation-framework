Column Generation Framework
===========================

Column Generation is a very useful approach to solve large-scale linear programming problems. 
This is the column generation framework that I developed during my Ph.D study, written in [OPL][opl]. 
Interested readers are encouraged to see [Column Generation][cgbook].

This source is published under MIT licence. If you use it, it is very appreciate to drop me a few lines.


[opl]: http://www-01.ibm.com/software/integration/optimization/cplex-optimization-studio/
[cgbook]: http://www.amazon.com/Column-Generation-Gerad-25th-Anniversary/dp/0387254854

---

Usage
=====

### Configuration Files:

+ __model.ini__: define states that will be loaded. Each line is formatted as _MODEL "NAME" "modelxxx.mod" [relax]_. If parameter 
_relax_ appears, then the model is relaxed when it is solved.

+ __params.mod__: contain the definition of your data. _sysmsg.mod_ need to be included in this file. The definition of the data as well as the data itself are available to all loaded states.

+ __params.dat__: define some parameters or initialize some variables used in the program.

The following paragraphs give more information.

### Running

_oplrun -D input="datafile" -D output="resultfile" [path-to]/solver.mod_  in your directory.

---

How It works
============

Actually, the program is just a state machine. At the initial step, it loads a list of states from _model.ini_, each state
is assigned to an OPL model. First, the program starts processing a special state named __ROOT__. The state will decide 
which is the next state to be solved. It can also return __empty__ state which means the process is finished. 
The overall optimization process is described as follows. 

-----
load _states_ from _model.ini_
	
state = __ROOT__

while state  != __empty__

  state = __empty__
		
   if solving( state.model )
     
     state = solving.nextmodel

---

APIs
====

There is only one predefined state:

Model __ROOT__: will be called first

otherwise, you can create whatever state you want. Notice that each state must define by itself the next state to be solved.
The final state is responsible to compute the GAP and other metrics by it own.
The system provides the following state-related functions that can be used inside each model:

- isModel( X )      = _true_ if the current solving model is X, _false_ otherwise.
- getModel()       : return the current model.    
- setNextModel( X ): set __X__ the next model to be solved. Parameter is undefined.
- setModelStatus( s ): if __s__ > 0 then display infos of the solving process of each model after it is solved, otherwise do nothing.

__Extra functions__:

- GAP( X , Y ) : return difference in percentage between X and Y in comparison to X.

- timeMarker() : return the current time object.
- elapsedTime( marker ): calculate the elapsed time from __marker__ in seconds.

- AVATAR() : return signature of the program.
- lineSep( label , sep ): display a line of __sep__ with __label__ in middle on screen.
- leftWrite( st , len ) : display a string with length __len__ on screen with __st__ aligned to the left.
- rightWrite( st , len) : display a string with length __len__ on screen with __st__ aligned to the right.
- maxLength( n , st )   : return MAX( n , len( st ) ).


- assertExisted( name ) : check if file __name__ existed or not.
- getPWDPath() : return the directory where you are standing.

---

Output Data:
============

The output file has INI format for which the following functions are provided:

- empty_output(): clear the output.
- output_section( txt ): start writing new Section __txt__.
- output_value( param , value ): write Param __param__ with Value __value__ to the output.

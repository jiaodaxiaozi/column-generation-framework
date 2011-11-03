Column Generation Framework
===========================

Column Generation is a very useful approach to solve large-scale linear programming problems. 
This is the column generation framework that I developed during my Ph.D study, written in [OPL][opl]. 
Interested readers are encouraged to see [Column Generation][cgbook].

This source is published under MIT licence. If you use it, it is very appreciate to drop me a few lines.


[opl]: http://www-01.ibm.com/software/integration/optimization/cplex-optimization-studio/
[cgbook]: http://www.amazon.com/Column-Generation-Gerad-25th-Anniversary/dp/0387254854



Usage
=====

### Configuration Files:

+ __model.ini__: define states that will be loaded. Each line is formatted as _MODEL "NAME" "modelxxx.mod" [relax]_. If parameter 
_relax_ appears, then the model is relaxed when it is solved.

+ __params.mod__: contain the definition of your data. _sysmsg.mod_ need to be included in this file. The definition of the data
as well as the data itself are available to all loaded states.

The following paragraphs give more detail.

### Running

_oplrun -D input="datafile" [path-to]/solver.mod_  in your directory.


### How It works


Actually, the program is just a state machine. At the initial step, it loads a list of states from _model.ini_, each state
is assigned to an OPL model. First, the program starts processing a special state named __START__. The state will decide 
which is the next state to be solved. It can also return __empty__ state which means the process is finished. The result
is reported by compared state __RELAX__, that supposes to be _RELAX RESTRICTED MASTER PROBLEM_, and __FINAL__, that supposes
to be _RESTRICTED MASTER PROBLEM_. The overall optimization process is described as follows. 

1. load _states_ from _model.ini_
1.
2. state = __START__
3.
3. while state  != __empty__
3.
3. 	state = __empty__
3.      if solving( state.model )
4. 		state = solving.nextmodel
5. 	
3. relax objective   = solving( __RELAX__ )
3. integer objective = solving( __FINAL__ )
3.
3. report result


So those are predefined states :

+ START : will be called first
+ RELAX : relax version of Restricted Master Problem (RMP)
+ FINAL : the RMP problem that contains the solution

otherwise, you can create whatever state you want. Notice that each state must define by itself the next state to be solved.
The system provides the following state-related functions that can be used inside each model:

- isModel( X )   = true if the current solving model is X, false otherwise.
- setNextModel( X ) : set the next model to be solved.


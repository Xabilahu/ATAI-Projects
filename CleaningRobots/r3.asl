// mars robot 3

!wander(_).

+!make_garb(_): not garbage(r3) 
			    <- ?pos(r3, X, Y);
				   gen_garb(X, Y);
				   .drop_all_intentions;
				   !wander(_).
+!make_garb(_) <- !wander(_).
		   
+!wander(_) <- move_around(_);  
			   !make_garb(_);
			   !wander(_).
  
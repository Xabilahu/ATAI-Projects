// mars robot 3

+garbage(r3) : true 
			   <- burn(2);
			   	  !ensure_burn(r3).

+!ensure_burn(r3) : garbage(r3) 
				    <- burn(2); 
					   !ensure_burn(r3).
+!ensure_burn(_).
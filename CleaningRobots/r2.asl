// mars robot 2

+garbage(r2) : true 
			   <- burn(1);
			   	  !ensure_burn(r2).

+!ensure_burn(r2) : garbage(r2) 
				    <- burn(1); 
					   !ensure_burn(r2).
+!ensure_burn(_).


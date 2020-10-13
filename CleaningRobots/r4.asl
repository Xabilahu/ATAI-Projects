// mars robot 4

+garbage(r4) : true 
			   <- burn(3);
			   	  !ensure_burn(r4).

+!ensure_burn(r4) : garbage(r4) 
				    <- burn(3); 
					   !ensure_burn(r4).
+!ensure_burn(_).
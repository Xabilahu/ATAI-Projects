// mars robot 5

+garbage(r5) : true 
			   <- burn(4);
			   	  !ensure_burn(r5).

+!ensure_burn(r5) : garbage(r5) 
				    <- burn(4); 
					   !ensure_burn(r5).
+!ensure_burn(_).
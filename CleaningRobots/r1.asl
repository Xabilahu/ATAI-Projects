// mars robot 1

/* Initial beliefs */

at(P) :- pos(P,X,Y) & pos(r1,X,Y).

/* Initial goal */

!check(slots).

/* Plans */

+!check(slots) : not garbage(16,r1) & not garbage(32,r1) & not garbage(64,r1)
   <- next(slot);
      !check(slots).
+!check(slots).

+garbage(T,r1) : T == 16 & not .desire(carry_to(T,r2))
   <- .drop_all_intentions;
      !carry_to(T,r2);
	  !check(slots).
   
+garbage(T,r1) : T == 32 & not .desire(carry_to(T,r3)) //Plastic
   <- .drop_all_intentions;
      !carry_to(T,r3);
	  !check(slots).
   
+garbage(T,r1) : T == 64 & not .desire(carry_to(T,r4)) //Paper
   <- .drop_all_intentions;
      !carry_to(T,r4);
	  !check(slots).

+!carry_to(T,R)
   <- // remember where to go back
      ?pos(r1,X,Y);
      -+pos(last,X,Y);

      // carry garbage to r2
      !take(T,R);

      // goes back and continue to check
      !at(last).

+!take(S,L) : true
   <- !ensure_pick(S);
      !at(L);
      drop(S).

+!ensure_pick(S) : garbage(S, r1)
   <- pick(S);
      !ensure_pick(S).
+!ensure_pick(_).

+!at(L) : at(L).
+!at(L) <- ?pos(L,X,Y);
           move_towards(0,X,Y);
           !at(L).

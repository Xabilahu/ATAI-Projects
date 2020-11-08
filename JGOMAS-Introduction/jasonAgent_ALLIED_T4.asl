debug(3).

// Name of the manager
manager("Manager").

// Team of troop.
team("ALLIED").
// Type of troop.
type("CLASS_SOLDIER").

{ include("jgomas.asl") }

// Plans


/*******************************
*
* Actions definitions
*
*******************************/

/////////////////////////////////
//  GET AGENT TO AIM 
/////////////////////////////////  
/**
* Calculates if there is an enemy at sight.
* 
* This plan scans the list <tt> m_FOVObjects</tt> (objects in the Field
* Of View of the agent) looking for an enemy. If an enemy agent is found, a
* value of aimed("true") is returned. Note that there is no criterion (proximity, etc.) for the
* enemy found. Otherwise, the return value is aimed("false")
* 
* <em> It's very useful to overload this plan. </em>
* 
*/  
+!get_agent_to_aim
<-  ?debug(Mode); if (Mode<=2) { .println("Looking for agents to aim."); }
?fovObjects(FOVObjects);
.length(FOVObjects, Length);

?debug(Mode); if (Mode<=1) { .println("El numero de objetos es:", Length); }

if (Length > 0) {
    +bucle(0);
    
    -+aimed("false");
    
    while (not no_shoot("true") & bucle(X) & (X < Length)) {
        
        //.println("En el bucle, y X vale:", X);
        
        .nth(X, FOVObjects, Object);
        // Object structure
        // [#, TEAM, TYPE, ANGLE, DISTANCE, HEALTH, POSITION ]
        .nth(2, Object, Type);
        
        ?debug(Mode); if (Mode<=2) { .println("Objeto Analizado: ", Object); }
        
        if (Type > 1000) {
            ?debug(Mode); if (Mode<=2) { .println("I found some object."); }
        } else {
            // Object may be an enemy
            .nth(1, Object, Team);
            ?my_formattedTeam(MyTeam);
            
            if (Team == 200) {  // Only if I'm ALLIED
				
                ?debug(Mode); if (Mode<=2) { .println("Aiming an enemy. . .", MyTeam, " ", .number(MyTeam) , " ", Team, " ", .number(Team)); }
                +aimed_agent(Object);
                -+aimed("true");
                
            }  else {
                if (Team == 100) {
                    .nth(3, Object, Angle);
                    if (math.abs(Angle) < 0.1) {
                        +no_shoot("true");
                        .println("ALLIES in front, not aiming!");
                    } 
                }
            }
            
        }
        
        -+bucle(X+1);
        
    }

    if (no_shoot("true")) {
        -aimed_agent(_);
        -+aimed("false");
        -no_shoot("true");
    }
    
    
}

-bucle(_).

/////////////////////////////////
//  LOOK RESPONSE
/////////////////////////////////
+look_response(FOVObjects)[source(M)]
    <-  //-waiting_look_response;
        .length(FOVObjects, Length);
        if (Length > 0) {
            ?debug(Mode); if (Mode<=1) { .println("HAY ", Length, " OBJETOS A MI ALREDEDOR:\n", FOVObjects); }
        };    
        -look_response(_)[source(M)];
        -+fovObjects(FOVObjects);
        //.//;
        !look.
      
        
/////////////////////////////////
//  PERFORM ACTIONS
/////////////////////////////////
/**
* Action to do when agent has an enemy at sight.
* 
* This plan is called when agent has looked and has found an enemy,
* calculating (in agreement to the enemy position) the new direction where
* is aiming.
*
*  It's very useful to overload this plan.
* 
*/
+!perform_aim_action
    <-  // Aimed agents have the following format:
        // [#, TEAM, TYPE, ANGLE, DISTANCE, HEALTH, POSITION ]
        ?aimed_agent(AimedAgent);
        ?debug(Mode); if (Mode<=1) { .println("AimedAgent ", AimedAgent); }
        .nth(1, AimedAgent, AimedAgentTeam);
        ?debug(Mode); if (Mode<=2) { .println("BAJO EL PUNTO DE MIRA TENGO A ALGUIEN DEL EQUIPO ", AimedAgentTeam);             }
        ?my_formattedTeam(MyTeam);


        if (AimedAgentTeam == 200) {
    
                .nth(6, AimedAgent, NewDestination);
                ?debug(Mode); if (Mode<=1) { .println("NUEVO DESTINO DEBERIA SER: ", NewDestination); }
          
            }
 .

/**
* Action to do when the agent is looking at.
*
* This plan is called just after Look method has ended.
* 
* <em> It's very useful to overload this plan. </em>
* 
*/
+!perform_look_action 
    <-  ?tasks(MyTaskList);

        if (.member(task(_, "TASK_GET_OBJECTIVE", _, _, _), MyTaskList)){
            .delete(task(_, "TASK_GET_OBJECTIVE", _, _, _), MyTaskList, MyNewTaskList);
            -+tasks(MyNewTaskList);
            .println("Deleted TASK_GET_OBJECTIVE.");
        }

        ?tasks(TaskListNew);
        if (.member(task(TPriority, TaskType, _, _, _), TaskListNew) & TaskType == "TASK_WALKING_PATH" & task_priority(TaskType, TaskPrio) & TPriority > (TaskPrio + 1)) { //Prevent bug
            .delete(task(TPriority, TaskType, _, _, _), TaskListNew, UnBuggedTaskList1);
            -+tasks(UnBuggedTaskList1);
            .println("Deleted buggy WALKING_PATH");
        }

        ?fovObjects(FovList);
        +min_dist(999999999);
        +min_pos(99999, 99999, 99999);
        // [ObjectID, ObjectTeam, _, _, _, _, pos(ObjectX, ObjectY, ObjectZ)]
        for(.member(CurrentObject, FovList)) {
            .nth(0, CurrentObject, ObjectID);
            .nth(1, CurrentObject, ObjectTeam);
            .nth(6, CurrentObject, pos(ObjectX, ObjectY, ObjectZ));
            if (ObjectTeam == 200) {
                for (.member(CObj, FovList)) {
                    .nth(0, CObj, ObjID);
                    .nth(1, CObj, ObjTeam);
                    .nth(6, CObj, pos(ObjX, ObjY, ObjZ));
                    if (ObjID \== ObjectID & ObjTeam == 200) {
                        !distance(pos(ObjectX, ObjectY, ObjectZ), pos(ObjX, ObjY, ObjZ));
                        ?distance(CurrentDist);
                        -distance(CurrentDist);
                        ?min_dist(MinimumDist);
                        if (CurrentDist < MinimumDist) {
                            -+min_dist(CurrentDist);
                            -+min_pos(ObjectX, ObjectY, ObjectZ);
                        }
                    }
                }
            }
        }

        ?min_dist(MinimumDist);
        -min_dist(_);

        ?tasks(CurrentTaskList);
        if (.member(task(_, "TASK_GOTO_POSITION", _, _, _), CurrentTaskList)){
            .delete(task(_, "TASK_GOTO_POSITION", _, _, _), CurrentTaskList, NewList);
            -+tasks(NewList);
        }

        .my_name(MyName);

        if (MinimumDist < 999999999) {
            ?min_pos(MinX, MinY, MinZ);
            !add_task(task("TASK_GOTO_POSITION", MyName, pos(MinX, MinY, MinZ), ""));
            ?task_priority("TASK_GOTO_POSITION", Priority);
            //-+current_task(task(Priority, "TASK_GOTO_POSITION", MyName, pos(MinX, MinY, MinZ), ""));
            -+state(standing);
            .println("Going to Position: ", MinX, ", ", MinY, ", ", MinZ);
        } else {
            ?flag(FlagX, FlagY, FlagZ);
            !add_task(task("TASK_GOTO_POSITION", MyName, pos(FlagX, FlagY, FlagZ), ""));
            ?task_priority("TASK_GOTO_POSITION", Priority);
            //-+current_task(task(Priority, "TASK_GOTO_POSITION", MyName, pos(FlagX, FlagY, FlagZ), ""));
            -+state(standing);
            .println("Going to Flag Position!");
        }
        -min_pos(_, _, _);
        ?tasks(TList);
        ?current_task(CTask);
        .println("Current Task: ", CTask);
        .println("Task List: ", TList).

/**
* Action to do if this agent cannot shoot.
* 
* This plan is called when the agent try to shoot, but has no ammo. The
* agent will spit enemies out. :-)
* 
* <em> It's very useful to overload this plan. </em>
* 
*/  
+!perform_no_ammo_action . 
   /// <- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR PERFORM_NO_AMMO_ACTION GOES HERE.") }.
    
/**
     * Action to do when an agent is being shot.
     * 
     * This plan is called every time this agent receives a messager from
     * agent Manager informing it is being shot.
     * 
     * <em> It's very useful to overload this plan. </em>
     * 
     */
+!perform_injury_action .
    ///<- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR PERFORM_INJURY_ACTION GOES HERE.") }. 
        

/////////////////////////////////
//  SETUP PRIORITIES
/////////////////////////////////
/**  You can change initial priorities if you want to change the behaviour of each agent  **/
+!setup_priorities
    <-  +task_priority("TASK_NONE",0);
        +task_priority("TASK_GIVE_MEDICPAKS", 200);
        +task_priority("TASK_GIVE_AMMOPAKS", 0);
        +task_priority("TASK_GIVE_BACKUP", 0);
        +task_priority("TASK_GET_OBJECTIVE",600);
        +task_priority("TASK_ATTACK", 1000);
        +task_priority("TASK_RUN_AWAY", 1500);
        +task_priority("TASK_GOTO_POSITION", 1750);
        +task_priority("TASK_PATROLLING", 500);
        +task_priority("TASK_WALKING_PATH", 1750).   



/////////////////////////////////
//  UPDATE TARGETS
/////////////////////////////////
/**
 * Action to do when an agent is thinking about what to do.
 *
 * This plan is called at the beginning of the state "standing"
 * The user can add or eliminate targets adding or removing tasks or changing priorities
 *
 * <em> It's very useful to overload this plan. </em>
 *
 */

+!update_targets
	<-	?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR UPDATE_TARGETS GOES HERE.") }.
	
	
	
/////////////////////////////////
//  CHECK MEDIC ACTION (ONLY MEDICS)
/////////////////////////////////
/**
 * Action to do when a medic agent is thinking about what to do if other agent needs help.
 *
 * By default always go to help
 *
 * <em> It's very useful to overload this plan. </em>
 *
 */
 +!checkMedicAction
     <-  -+medicAction(on).
      // go to help
      
      
/////////////////////////////////
//  CHECK FIELDOPS ACTION (ONLY FIELDOPS)
/////////////////////////////////
/**
 * Action to do when a fieldops agent is thinking about what to do if other agent needs help.
 *
 * By default always go to help
 *
 * <em> It's very useful to overload this plan. </em>
 *
 */
 +!checkAmmoAction
     <-  -+fieldopsAction(on).
      //  go to help



/////////////////////////////////
//  PERFORM_TRESHOLD_ACTION
/////////////////////////////////
/**
 * Action to do when an agent has a problem with its ammo or health.
 *
 * By default always calls for help
 *
 * <em> It's very useful to overload this plan. </em>
 *
 */
+!performThresholdAction
       <-
       
       ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR PERFORM_TRESHOLD_ACTION GOES HERE.") }
       
       ?my_ammo_threshold(At);
       ?my_ammo(Ar);
       
       if (Ar <= At) { 
          ?my_position(X, Y, Z);
          
         .my_team("fieldops_ALLIED", E1);
         //.println("Mi equipo intendencia: ", E1 );
         .concat("cfa(",X, ", ", Y, ", ", Z, ", ", Ar, ")", Content1);
         .send_msg_with_conversation_id(E1, tell, Content1, "CFA");
       
       
       }
       
       ?my_health_threshold(Ht);
       ?my_health(Hr);
       
       if (Hr <= Ht) { 
          ?my_position(X, Y, Z);
          
         .my_team("medic_ALLIED", E2);
         //.println("Mi equipo medico: ", E2 );
         .concat("cfm(",X, ", ", Y, ", ", Z, ", ", Hr, ")", Content2);
         .send_msg_with_conversation_id(E2, tell, Content2, "CFM");

       }
       .

/////////////////////////////////
//  Initialize variables
/////////////////////////////////

+!init
   <- ?objective(FlagX, FlagY, FlagZ);
      +flag(FlagX, FlagY, FlagZ).




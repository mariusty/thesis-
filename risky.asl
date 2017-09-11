result (Sur, Rep, B) :- .random(R)& B = math.round(Sur*0.4 + Rep*0.4+(100*R)*0.2).
random (Ra) :- .random(R)& Ra = math.round(100*R).

+started [source(A)]
    <-  .my_name(Me);
    	.send(A,tell,intro(Me)). 

+request(Task, P) [source(A)] : not participating(_)
    <- 	?random (R1);
    	?random (R2);
    	?random (R3);
    	?random (R4);
    	?random (R5);
    	R = math.average([R1,R2,R3,R4,R5]);
    	-+reputation(R);
    	-+risk(0);
    	if (R >= P) { //PREFERABLE - 0.5R - 1.5R, DOESNT TAKE <0.5R
			if (P >= R*0.5 ) { //Price is between 0.5 and 1 R -DOESN'T WANT TO PARTICIPATE
				S = 0;
			}
			else { 
				S = 100;
			}
		}
		else { 
			if (P >= R*1.5 ) { 
				S = P-R;
			}
			else { //Price is between 1 and 1.5 R
				S = 100; 
			}
		}
		if (S >0) { 
				 Res = math.round(R*0.5 + S*0.5);
				 .println("My reputation is ",R, "   sureness = ", S,"  price = ", P,"   for task = ", Task, " send to ", A, "   EXPECTED RESULT ", Res);
				 .send(A,tell, propose(Task, S, R, Res));
				 +participating(Task)
		}
		else{ 
			.println("I'm not interested in ", Task, ", my reputation is ",R,"  price = ", P );
		}.
        
+request(Task, P) [source(A)] 
    <- 	?reputation (R);
		?risk(Risk);
		//.print("RISK =  ", Risk);
    	if (R >= P) { //PREFERABLE - 0.5R - 1.5R, DOESNT TAKE <0.5R
			if (P >= R*0.5 ) { //Price is between 0.5 and 1 R - DOESN'T WANT TO PARTICIPATE
				S = 0;
			}
			else { 
				S = 100;
			}
		}
		else { 
			if (P >= R*1.5 ) { 
				if (P-R+Risk < 100 ) { 
					S = P-R+Risk;
				}
				else { 
					S = 100; 
				}			}
			else { //Price is between 1 and 1.5 R
				S = 100; 
			}
		}
		if (S >0) { 
				 Res = math.round(R*0.5 + S*0.5);
				 .println("My reputation is ",R, "   sureness = ", S,"  price = ", P,"   for task = ", Task, " send to ", A, "   EXPECTED RESULT ", Res);
				 .send(A,tell, propose(Task, S, R, Res));
				 +participating(Task)
		}
		else{ 
			.println("I'm not interested in ", Task, ", my reputation is ",R,"  price = ", P );
		}.

+accept (S,R) [source(A)] 
    <- ?result(S,R,P);
    .print("My proposal won! I made it for ",P," while sure = ",S," reputation = ",R," source ", A);
    .send (A,tell,result(P, S, R)).

+reject (Ns) : participating (Ns)
    <- 
    ?risk(Risk);
    if (Risk <90 ) { 
		K = Risk + 10;
		-+risk(K);
	}
    .print("I haven't been chosen for ", Ns, " I'll up my risks to ", K).
    
+bad_result(Newreput)[source(A)] 
	<- ?reputation (R);
	-+reputation(Newreput);
	?risk(Risk);
	if (Risk > 5 ) { 
		K = Risk - 5;
		-+risk(K);
	}
    .println("I made it bad, new reputation is ",Newreput, " old reputation ", R).

+good_result(Newreput)[source(A)] 
	<- ?reputation (R);
	-+reputation(Newreput);
    .println("I made it good. My new reputation is ",Newreput, "  old reputation ", R).
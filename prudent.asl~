result (Sur, Rep, B) :- .random(R)& B = math.round(Sur*0.4 + Rep*0.4+(100*R)*0.2).
random (Ra) :- .random(R)& Ra = math.round(100*R).

!st.

+!st
	<-  ?random(R);
	N = math.round(1 + R / 10); //random number of tasks from 1 to 11,
	.print(N);
	.findall(X, .random(X,N), L)  //generate random tasks ids
    for ( .member(X,L) ) { 	
    	K = math.round(X*100);
        !tasks ([task(K)]); 
     }.

+!tasks([]).
+!tasks([task(T)|R])
    <-  !start(task(T));
        !tasks(R).
        
+!start(task(T)) 
    <-  .broadcast(tell, started); 
        .wait(5000); 
        .findall(B,intro(B)[source(A)],LP);
        ?random(P);
        for (.member(M,LP) ) {
			.send(M,tell,request(T, P));
		 }
        .wait(5000);
        .findall(offer(Res,Sureness,Reput,T,Aa), propose(T,Sureness, Reput, Res)[source(Aa)],L); 
        if (L == []) { 
			.print("No proposes for ", T);
		 }
		 else { 
			.print("Proposes  ",L);
			!allocate(T, L);
		 }.

+!allocate(Ns, L) 
        <-  L \== []; 
            .max(L,offer(Res,Sureness,Reput,T,Ag)); // sort offers , the first is the best
            .print("Winner is ",Ag);
            !announce_result(Ns,L, Ag).  

+!feedback (Ns, Predication ,[res(P,S,R,Ag)]) 
	<- if (Predication < R) { 
	 	Newreput = R+P/10;
       .send(Ag,tell,good_result(Newreput));
     }
     if (Predication >= R) { 
     	Newreput = R-P/10;
       .send(Ag,tell,bad_result(Newreput));
     }.


+!announce_result (Ns,[offer(Predication,S,R,_,Ag)|T], Ag) 
       <- .send(Ag,tell,accept(S,R)); 
       .wait(2000);
       .findall(res(P,S,R,Ag), result(P, S, R)[source(Ag)], PP);
       //.print("Returned   ", PP);
       !feedback(Ns, Predication, PP);
       !announce_result(Ns, T, Ag).
       
+!announce_result(Ns,[offer(_,_,_,_,A)|T], Ag) 
       <- .send(A,tell,reject(Ns));
       !announce_result(Ns, T, Ag). 
       
+!announce_result(_,[],_).

+started [source(A)] : not first(_)
    <-  +first(test);
    	?random (R1);
    	?random (R2);
    	?random (R3);
    	?random (R4);
    	?random (R5);
    	R = math.average([R1,R2,R3,R4,R5]);
    	-+reputation(R);
    	//.println("REPUTATION 1 = ",R);
    	.my_name(Me);
    	.send(A,tell,intro(Me)). 

+started [source(A)] 
    <-  .wait(1000);
    	?reputation(R);
    	//.println("REPUTATION 2 = ",R);
    	.my_name(Me);
    	.send(A,tell,intro(Me)). 

+request(Task, P) [source(A)] : not participating(_)
    <- 	?reputation(R);
    	-+risk(0);
    	if (R >= P) { //PREFERABLE - 0.5R - 1.5R, DOESNT TAKE >1.5R
			if (P <= R*0.5 ) { 
				S = 100;
			}
			else { 
				S = P;
			}
		}
		else { 
			if (P >= R*1.5 ) { 
				S = 0;
			}
			else { //Price is between 1 and 1.5 R
				S = P - R; 
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
    	if (R >= P) { //PREFERABLE - 0.5R - 1.5R, DOESNT TAKE >1.5R
			if (P <= R*0.5 ) { 
				S = 100;
			}
			else { 
				S = P + Risk;
			}
		}
		else { 
			if (P >= R*1.5 ) { 
				S = 0; 
			}
			else { //Price is between 1 and 1.5 R
				S = P + Risk; 
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
    <- .print("I haven't been chosen for ", Ns).
    
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
	?risk(Risk);
	if (Risk <95 ) { 
		K = Risk + 5;
		-+risk(K);
	}
    .println("I made it good. My new reputation is ",Newreput, "  old reputation ", R).
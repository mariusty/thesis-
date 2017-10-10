random (Ra) :- .random(R)& Ra = math.round(100*R). //Returns the reputation in the interval [0,100], is also used in tasks number generation
result (Sur, Rep, B) :- .random(R)& B = math.round(Rep*0.7+Sur*0.1+(100*R)*0.2). //calculation of the predicted result
!st. //in the beginning the desire that the loop has to been started should be added so the "initiator" part begins 

//INITIATOR PART
+!st //initiator part beggining
	<-  ?random(R); //get random number from 0 to 100
	N = math.round(R/10); //allocate random number of tasks in interval [0; 10]
	.print(N); 
	if (N > 0) { //if an agent is going to be initiator
		.findall(X, .random(X,N), L)  //generate random tasks ids
		for ( .member(X,L) ) { //for each task	
			K = math.round(X*1000); //task id is in interval [0, 1000]
			!tasks ([task(K)]); //add task to the task list
		}
	}.

+!tasks([]). //if task list is empty – do nothing
+!tasks([task(T)|R]) //if task list is not empty
    <-  !start(task(T)); //start the "auction"
        !tasks(R). //continue with other tasks (if exist)
        
+!start(task(T)) //start task "auction"
    <-  .broadcast(tell, started); //tell other agents that the auction started
        .wait(5000); 
        .findall(B,intro(B)[source(A)],LP); //receive agents list 
        ?random(P); //generate price for the task
        for (.member(M,LP) ) { //for each agent in the list 
			.send(M,tell,request(T, P)); //send request with the price
		 }
        .wait(5000);
        .findall(offer(Res,Sureness,Reput,T,Aa), propose(T,Sureness, Reput, Res)[source(Aa)],L); //collect all offers from agents with their reputation, sureness and expected result
        if (L == []) { //if no one is interested in this taks
			.print("No proposes for ", T, " I'll try it again");
			!tasks ([task(T)]); //start an "auction" again
		 }
		 else { //if there are offers for the task
			.print("Proposes for task  ",T,"  ",L);
			!allocate(T, L, P); //the first "auction" step succeed, go to task allocation 
		 }.

+!allocate(Ns, L, P) //task allocation
        <-  L \== []; 
            .max(L,offer(Res,Sureness,Reput,T,Ag)); // sort received offers , the first is the best
            .print("Winner is ",Ag);
            !announce_result(Ns,L, Ag, P).  //the second "auction" step is completed, go to result announce

+!announce_result (Ns,[offer(Prediction,S,R,_,Ag)|T], Ag, Price) //if the selected agent is the winner
       <- .send(Ag,tell,accept(S,R)); //send the acceptation to winner
       .wait(2000);
       .findall(res(P,S,R,Ag), result(P, S, R)[source(Ag)], PP); //receive the result
       !feedback(Ns, Price, Prediction, PP); //give the feedback to winner
       !announce_result(Ns, T, Ag, Price). //announce "auction" result to other agents
       
+!announce_result(Ns,[offer(_,_,_,_,A)|T], Ag, Price) //if the selected agent is not the winner
       <- .send(A,tell,reject(Ns)); //send the rejection
       !announce_result(Ns, T, Ag, Price). //announce "auction" result to other agents
       
+!announce_result(_,[],_,_). //stop if there are no more agents in the offers list

+!feedback (Ns, Price, Prediction ,[res(P,S,R,Ag)]) //give feedback for a task 
	<- Newreput = Price/10; //reputation increases/decreases for task price/10
	if (P >= Prediction) {	 //if the result is over or equal to the expected 
       		.send(Ag,tell,good_result(Newreput)); //send good news to the winner
     	}
   	else { 
       		.send(Ag,tell,bad_result(Newreput)); //else – tell the winner that he worked bad
          }.

//PARTICIPATOR PART
+started [source(A)] : not first(_) //if there is task and agent had never participated in "auctions" before
    <-  +first(test); //add a "flag" that it's its first task so later the reputation wouldn't be calculated with random function again
    	?random (R1);
    	?random (R2);
    	?random (R3);
    	?random (R4);
    	?random (R5);
    	R = math.average([R1,R2,R3,R4,R5]); //take five random numbers in interval [0,100] and count their average 
    	-+reputation(R); //set the average as agents default reputation
    	.my_name(Me); //get name
    	.send(A,tell,intro(Me)). //introduce agent as a participant to task initiator

+started [source(A)] //if there is task 
    <-  .wait(1000); //wait because on first loop there can be a huge amount of tasks and the program uses multithreads so the reputation default calculation could be started but not finished
    	?reputation(R); //get reputation
    	.my_name(Me);
    	.send(A,tell,intro(Me)). //introduce agent as a participant to task initiator
        
+request(Task, P) [source(A)] //initiator sent a request with task price
    <- 	?reputation (R); //get reputation
    	if (R >= P) { //if reputation is higher than price
			if (P >= R*0.5 ) { //price is between 0.5R and R
				S = P; //set sureness equal to price
			}
			else { //price is under 0.5R
				S = 100; //set sureness equal to 100
			}
		}
		else{ //if price is higher than reputation
			if (P >= R*1.5 ) { //price is over 1.5R
				S = 0; //agent doesn't want to participate
			}
			else { //price is between R and 1.5 R
				S = R*2 - P; //sureness is equal to 2R-P
			}
		}
		if (S >0) { //if agent is interested in a task
				 Res = math.round(R*0.8 + S*0.2); //count the expected result
				 .println("My reputation is ",R, "   sureness = ", S,"  price = ", P,"   for task = ", Task, " send to ", A, "   EXPECTED RESULT ", Res);
				 .send(A,tell, propose(Task, S, R, Res)); //send an offer to initiator
		}
		else{  //if agent isn't interested in task – price is too high
			.println("I'm not interested in ", Task);
		}.

+accept (S,R) [source(A)] //initiator sent message that agent won the "auction"
    <- ?result(S,R,P); //count the actual result (has random variable)
    .print("My proposal won! I made it for ",P," while sure = ",S," reputation = ",R," source ", A);
    .send (A,tell,result(P, S, R)). //send to initiator the actual result

+reject (Ns) //initiator sent message that agent hasn't been chosen
    <- .print("I haven't been chosen for ", Ns).
    
+bad_result(Newreput)[source(A)] //agent receives message that initiator is not satisfied
	<- ?reputation (R); //get current reputation
	if (R - Newreput > 0 ) { //if reputation can be decreased for a value given by initiator without passing the 0
		-+reputation(R - Newreput); //set new reputation as reputation – value given by initiator
	}
	else { 
		-+reputation(0); //else set reputation equal to minimum
	}
	?reputation (Rep);
   	.println("I made it bad, new reputation is ",Rep, " old reputation ", R).

+good_result(Newreput)[source(A)] //agent receives message that initiator is satisfied
	<- ?reputation (R); //get current reputation
	if (R+Newreput < 100 ) { //if reputation can be increased for a value given by initiator without passing the 100
		-+reputation(R + Newreput); //set new reputation as reputation + value given by initiator
	}
	else { 
		-+reputation(100); //else set reputation equal to maximum
	}
	?reputation (Rep);
    	.println("I made it good. My new reputation is ",Rep, "  old reputation ", R).

random (X) :- .random(R)& X = math.round(100*R).

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
        .wait(3000); 
        .findall(B,intro(B)[source(A)],LP);
        ?random(P);
        for (.member(M,LP) ) {
			.send(M,tell,request(T, P));
		 }
        .wait(2000);
        .findall(offer(Res,Sureness,Reput,T,Aa), propose(T,Sureness, Reput, Res)[source(Aa)],L); 
        .print("Proposes  ",L);
        !allocate(T, L).

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
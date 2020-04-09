#-- scenario file --#
# matching pennies test: algorithm 2
#    animal gets reward when it chooses the same side with the computer
#algorithm 0:
#      computer's choice: generated randomly as 0.5:0.5
#algorithm 1 (only use the choice history):
#      1: 5 binomial test in total
#          1) N=0 P(left) = P(right) = 0.5
#          2) N=1 P(right(t)| right(t-1) ) = 0.5 or P(right(t) | left(t-1)) = 0.5 (depends on the choice of privous trials)
#          3) N=2; N=3; N=4;
#      2:
#          1) if there are no significant difference between 0.5 and the animals choice history, then the computer generate the choice randomly as 0.5:0.5
#          2) if there are. then find the probability(P) to choose right corresponding to the smallest p value. The computer will choose right with the probability (1-P)
#algorithm 2 (use both choice and reward history). rest same as algorithm 1

#tips: the random() function returns a random floating number between 0 and 1 (with 0, without 1)

# when I press spacebar, give it water
# when mouse licks either port, give it water
# count water given by manualfeed or induced by licks
# modified from phase0, 500 ms go cue, 3-4s free water, 2-3s no water with white noise

scenario = "phase2_matchingPennies_algorithm1";

active_buttons = 3;	#how many response buttons in scenario
button_codes = 1,2,3;
#target_button_codes = 1,2,3;
# write_codes = true;	#using analog output port to sync with electrophys
response_logging = log_all;	#log all trials
response_matching = simple_matching;	#response time match to stimuli

begin;

#-------SOUND STIMULI-------#
sound {
	wavefile { filename ="tone_5000Hz_0.2Dur.wav"; preload = true; };
} go;

sound {
	wavefile { filename ="wanyu_white_noise_8s.wav"; preload=true; };
} whitenoise;


#--------trial---------#


trial {
   save_logfile {
		filename = "temp.log"; 	# use temp.log in default logfile directory
	};									#save logfile during mid-experiment
}quicksave;

trial {
   trial_type = fixed;
   trial_duration = 100;
	nothing {} startexptleftevent;
   code=51;
}startexptleft;

trial {
   trial_type = fixed;
   trial_duration = 100;
	nothing {} startexptrightevent;
   code=52;
}startexptright;


trial {
	trial_type = fixed;
	trial_duration = 3000;	#at least 500ms between water
	nothing {} waterrewardexptevent;
	code=10;
	response_active = true; #still record the licks
}waterrewardmanual;



trial {
	trial_type = fixed;
	trial_duration = 3000;	#at least 500ms between water
	nothing {} waterrewardleftexptevent;
	code=100;
	response_active = true; #still record the licks
}waterrewardleft;

trial {
	trial_type = fixed;
	trial_duration = 3000;	#at least 500ms between water
	nothing {} waterrewardrightexptevent;
	code=111;
	response_active = true; #still record the licks
}waterrewardright;

trial {
	trial_type = fixed;
	trial_duration = 3000;	#at least 500ms between water
	nothing {} nowaterrewardleftexptevent;
	code=101;
	response_active = true; #still record the licks
}norewardleft;

trial {
	trial_type = fixed;
	trial_duration = 3000;	#at least 500ms between water
	nothing {} nowaterrewardrightexptevent;
	code=110;
	response_active = true; #still record the licks
}norewardright;





trial {
	all_responses = false; #ignore the first 10ms response
   trial_type = first_response;
   trial_duration = 2000;
	nothing {};
   code=51; 
	sound go;
	time=0;
	stimulus_time_in = 10;   # assign response that occur
   stimulus_time_out = 2000; # 0.5-2 s after start of stimulus
	target_button = 2;
}waitlickleft;

trial {
	all_responses = false; #ignore the first 10ms response
   trial_type = first_response;
   trial_duration = 2000;
	nothing {};
   code=52; 
	sound go;
	time=0;
	stimulus_time_in = 10;   # assign response that occur
   stimulus_time_out = 2000; # 0.5-2 s after start of stimulus
	target_button = 2;
}waitlickright;



trial {
  trial_type = fixed;
  trial_duration = 2500;
  nothing {} nolickevent;
  code=19;
}nolick;

trial {
	trial_type = fixed;
	trial_duration = 3000;
	nothing {} pauseevent;
	code=77;
} pause;

begin_pcl;

#for generating exponetial distribution (white noise block)
double minimum=1.0;
double mu=0.33333; #rate parameter for exponential distribution
double truncate=5.0;
double expval=0.0;

term.print("Starting time:");
term.print(date_time());
logfile.add_event_entry(date_time());

display_window.draw_text("Initializing...");

int maxNolick=5;
int num_trials = 1000;  # user enters initial value in dialog before scenario
preset int waterAmount_left = 74;
preset int waterAmount_right = 77;

preset int max_consecMiss = 10;                                                                                 ; #triggers end session, for mice, set to 20
int consecMiss = 0;
	# #msec to open water valve
int manualfeed=0;
int leftlick=0;
int rightlick=0;
int missed = 0;
int rewards = 0;
int numTrials = 0;
int numNLs = 0;
array<int>leftCountMat[5][num_trials];
array<int>rightCountMat[5][num_trials];


array<int>leftCountMatChoice[5][num_trials];
array<int>rightCountMatChoice[5][num_trials];

parameter_window.remove_all();
int manualfeedIndex = parameter_window.add_parameter("Manual feed");
int leftlickIndex = parameter_window.add_parameter("Left Lick");
int rightlickIndex = parameter_window.add_parameter("Right Lick");
int missIndex = parameter_window.add_parameter("ConsecMiss");
int trialIndex = parameter_window.add_parameter("trial_num");
#int nolickIndex = parameter_window.add_parameter("noLick");
int currentAgentIndex = parameter_window.add_parameter("curAgent");
int currentComIndex = parameter_window.add_parameter("curCom");
#int pValueIndex = parameter_window.add_parameter("p-value");
int probIndex = parameter_window.add_parameter("left-prob");
int combIndex = parameter_window.add_parameter("current combination");
int indIndex = parameter_window.add_parameter("current index");
int nolickIndex = parameter_window.add_parameter("#NL");
int meanNLIndex = parameter_window.add_parameter("meanNL");
int rewardRateIndex = parameter_window.add_parameter("reward rate");
array<double> pUse[num_trials];
pUse[1]=0.5;

int choiceLen;
double rand;

#initialize the choice history and reward list
array<int> agentChoiceHistory[0]; array<int> comChoiceHistory[num_trials]; array<int> rewardHistory[0];
array<int> allRewardHistory[num_trials];
#2: left choice, 3: right choice for choice history
#0: no reward, 1:reward for reward history
# set up parallel port for water reward
array<int> ChoiceHistory[num_trials];  #to store all the choices including miss

#create array to save the counting results
array<int> dynChoiceCount[512];
#the first 4 elements represent reward history: r_-4. r_-3. r_-2, r_-1
#last 5 elements represent choice history: c_-4, c_-3, c_-2, c_-1, c_0(this one is what need to count
array<int> dynChoiceCountChoice[32];
#this array are used to represent the 32 (2^5) combinations of left and right under N=4 condition
#using 0,1 to represent left and right in the commentchoice):
#[00000][00001][00010][00011][00100][00101][00110][00111][01000][01001][01010][01011][01100][01101][01110][01111]
#[10000][10001][10010][10011][10100][10101][10110][10111][11000][11001][11010][11011][11100][11101][11110][11111]
#to update the number, using the last 5 trials to get the index, then plus 1
#for N=3,using [1xxxx]+[0xxxx]....
array<int> curComb[4];#to store current combination
array<int> curCombChoice[5];#to store current combination

array<int> baseSeq[0]; #sequence to be searched in every trial
array<int> baseSeqChoice[0]; #sequence to be searched in every trial
double prob=0.5;
double minProb=0.5;
double nullP = 0.5; #for binomial test
double maxP = 0.05;
double meanNL = 0.0;
double rewardRate = 0.0;
int leftCount=0;
int rightCount=0;  #this left and right are for binomial test
int totalCount=0;
int leftCountChoice=0;
int rightCountChoice=0;  #this left and right are for binomial test
int totalCountChoice=0;
array<int>totaltime[0];

double pValue=0.05;
double pValueChoice=0.05;

#record the time to run the binomial test 
int curInd;
int curIndChoice;
#read in the binomial test-p value cheatsheet
input_file f=new input_file;
array<string> lines[0];
string path="C:\\Users\\KWANBEH05\\Desktop\\Presentation\\hongli\\matchingpennies\\binomialtest_cheatsheet.txt";
f.open(path);
string line=f.get_line();
loop until !f.last_succeeded() begin
	lines.add(line);
	line=f.get_line();
end;

array<double> pValueList[500][500];
loop int i=1 until i>lines.count() begin
	array<string> words[0];
	lines[i].split(" ", words);
	loop int word=1 until word>words.count() begin
		if (words[word] != "") then
			pValueList[i][word]=double(words[word]);
		end;
		word=word+1;
	end;
	i=i+1;
end;

array<int> IndNeed[0];
array<int> Ind1[8];
Ind1={0, 4, 8, 12, 16, 20, 24, 28};
IndNeed.append(Ind1);
loop int k=1;
until k>8
begin
	Ind1[k]=Ind1[k]+64;
	k=k+1;
end;
IndNeed.append(Ind1);
array<int> temp[16];
loop int k=1;
until k>16
begin
	temp[k]=IndNeed[k]+128;
	k=k+1;
end;
IndNeed.append(temp);
array<int> temp2[32];
loop int k=1;
until k>32
begin
	temp2[k]=IndNeed[k]+256;
	k=k+1;
end;
IndNeed.append(temp2);
					
#use subroutines to write several functions

#exponential calculation
sub
  double exponential (double base, int expo)
begin
  double exp;
  if expo==0 then
    exp=1.0;
  else
    exp=1.0;
    loop
    until
       expo<1
    begin
       exp=exp*base;
       expo=expo-1;
    end;
   end;
   return exp;
end;

#this function is used to slice the array
sub
    array<int,1> slice (array<int,1>& inputArray, int startNum, int endNum)
begin
	 array<int> slice[0];
    loop
       int i=startNum;
    until
       i>endNum
    begin
       slice.add(inputArray[i]);
       i=i+1;
    end;
    return slice;
end;

sub int trans_index(array<int,1>& comb)
#input an array, digits representing left and right choice by 0 and 1 respectively
#transfer to 10 to get the corrresponding index of the counting array
begin
	int ind=1;
	int leng=comb.count();
	loop
		int i=1
	until i>leng
	begin
		ind=ind+(comb[i]-2)*int(exponential(2.0, (leng-i)));
		i=i+1;
	end;
	#index starts at 1 instead of 0
	return ind
end;

output_port port = output_port_manager.get_port(1);

display_window.draw_text("Water reward with left lick or right lick or Spacebar...");

rand =random();
if (rand <= 0.5) then
   comChoiceHistory[1]=2;
else
   comChoiceHistory[1]=3;
end;

int timeStart=0;
int timeEnd=0;

loop
	int i = 1
until	consecMiss >= max_consecMiss
begin
	missed = 0;
	parameter_window.set_parameter(currentComIndex,string(comChoiceHistory[i]));
	if comChoiceHistory[i]==2 then
		waitlickleft.present(); #waitlick event may be missed in the logfile, this event is added to make sure there is a start mark for the trial
   elseif comChoiceHistory[i]==3 then
		waitlickright.present();
	end;
	
  #generate the computer's choice here (not sure about the consequence, if it takes too much time, then it may delay the response recording, wait for later testing)
  #for algorithm 1, need to do 5 binomial test first.

      #i equals to the length of agentChoiceHistory
  
	parameter_window.set_parameter(currentComIndex,string(comChoiceHistory[i]));
	if response_manager.response_count()>0 then
		if (response_manager.last_response() == 1) then	#if spacebar
			port.set_pulse_width(waterAmount_left);
			port.send_code(4);		#give water reward to left
			port.set_pulse_width(waterAmount_right);
			port.send_code(8);		#give water reward to right
			waterrewardmanual.present();
			manualfeed = manualfeed + 1;
			parameter_window.set_parameter(manualfeedIndex, string(manualfeed));
			consecMiss=0;
		elseif (response_manager.last_response() == comChoiceHistory[i]) then	#if licking the same port as the computer chooses
			rewardHistory.add(3);
			rewards = rewards + 1;
			numTrials = numTrials + 1;
			allRewardHistory[i]=1;
			if (comChoiceHistory[i]==2) then
				agentChoiceHistory.add(2);
				ChoiceHistory[i]=2;
			   port.set_pulse_width(waterAmount_left);
			   port.send_code(4);		#give water reward to left
			   waterrewardleft.present();
			   leftlick = leftlick + 1;
			   parameter_window.set_parameter(leftlickIndex,string(leftlick));
			   consecMiss=0;
			   parameter_window.set_parameter(missIndex,string(consecMiss));
			elseif (comChoiceHistory[i]==3) then
				agentChoiceHistory.add(3);
				ChoiceHistory[i]=3;
				port.set_pulse_width(waterAmount_right);
				port.send_code(8);		#give water reward to right
				waterrewardright.present();
				rightlick = rightlick + 1;
				parameter_window.set_parameter(rightlickIndex,string(rightlick));
				consecMiss=0;
				parameter_window.set_parameter(missIndex,string(consecMiss));
			end;
		elseif (response_manager.last_response() != comChoiceHistory[i]) then
			rewardHistory.add(2);
			numTrials = numTrials + 1;
			allRewardHistory[i]=0;
			if ((response_manager.last_response()==2)) then
				agentChoiceHistory.add(2);
				ChoiceHistory[i]=2;
				leftlick = leftlick + 1;
				norewardright.present();  #nowaterrewardright means the computer chooses right
				parameter_window.set_parameter(leftlickIndex,string(leftlick));
				consecMiss=0;
				parameter_window.set_parameter(missIndex,string(consecMiss));
			elseif ((response_manager.last_response()==3)) then
				agentChoiceHistory.add(3);
				ChoiceHistory[i]=3;
				rightlick = rightlick + 1;
				norewardleft.present();
				parameter_window.set_parameter(rightlickIndex,string(rightlick));
				consecMiss=0;
				parameter_window.set_parameter(missIndex,string(consecMiss));
			end;
		end;

	else
		pause.present();
		missed = 1;
		#agentChoiceHistory.add(0); #0 represent missed trial
	   #rewardHistory.add(0);
		ChoiceHistory[i]=0;
		consecMiss=consecMiss+1;
		allRewardHistory[i]=0;
		parameter_window.set_parameter(missIndex,string(consecMiss));
	end;

   parameter_window.set_parameter(currentAgentIndex,string(ChoiceHistory[i]));

	#update the choice counting
	#representation:
	#update the count
	curComb.resize(4);
	choiceLen=agentChoiceHistory.count(); 
	if choiceLen>=5 && ChoiceHistory[i]!=0 then
		curComb=slice(rewardHistory, choiceLen-4, choiceLen-1);
		curCombChoice=slice(agentChoiceHistory, choiceLen-4, choiceLen);
		curComb.append(curCombChoice);

		#first 4 reward his, then 5 choice His
		curInd=trans_index(curComb);
		curIndChoice=trans_index(curCombChoice);
		if curInd>0 then 
			dynChoiceCount[curInd]=dynChoiceCount[curInd]+1;
			dynChoiceCountChoice[curIndChoice]=dynChoiceCountChoice[curIndChoice]+1;
		end
	end;
	
	i=i+1;
	
	minProb=0.5;
	maxP=0.05;
	int baseInd;
	int baseIndChoice;

	if choiceLen<=5 then
        rand =random();
        if (rand <= 0.5) then
            comChoiceHistory[i]=2;
        else
            comChoiceHistory[i]=3;
        end;
   else
        loop
            int j=0
        until
            j>4
        begin 
				leftCount=0;
				rightCount=0;
				if j>0 then
					baseSeq.resize(j);
					baseSeqChoice.resize(0);
					baseSeq=slice(rewardHistory,choiceLen-j+1,choiceLen);
				#add missed choice history(between reward history and choice history)
				#total digits should be 8
				
				
					loop int k=1;
					until k>4-j
					begin
						baseSeq.add(2);
						k=k+1;
					end;
					baseSeq.append(slice(agentChoiceHistory,choiceLen-j+1,choiceLen));
					baseSeq.add(2); #get the correct index
					baseInd=trans_index(baseSeq);
					baseSeqChoice.append(slice(agentChoiceHistory,choiceLen-j+1,choiceLen));
					baseSeqChoice.add(2); #get the right index
					baseIndChoice=trans_index(baseSeqChoice);
				end;
				
				if j==4 then
					leftCount=dynChoiceCount[0+baseInd];
					rightCount=dynChoiceCount[1+baseInd];
					leftCountChoice=dynChoiceCountChoice[0+baseIndChoice];
					rightCountChoice=dynChoiceCountChoice[1+baseIndChoice];
				elseif j==0 then
					leftCount=leftlick;
					rightCount=rightlick;
					leftCountChoice=0;
					rightCountChoice=0;
				elseif j==1 then
					#IndNeed is the 64 index we need to updata the choice count while j=1;
					#there should be easier ways to do this. 
					
					#adding the choice count
					loop int k=1
					until k>64
					begin
						leftCount=leftCount+dynChoiceCount[IndNeed[k]+baseInd];
						rightCount=rightCount+dynChoiceCount[IndNeed[k]+1+baseInd];
						k=k+1;
					end;
					#adding
					leftCountChoice=dynChoiceCountChoice[0+baseIndChoice]+dynChoiceCountChoice[4+baseIndChoice]+dynChoiceCountChoice[8+baseIndChoice]+dynChoiceCountChoice[12+baseIndChoice]+dynChoiceCountChoice[16+baseIndChoice]+dynChoiceCountChoice[20+baseIndChoice]+dynChoiceCountChoice[24+baseIndChoice]+dynChoiceCountChoice[28+baseIndChoice];
					rightCountChoice=dynChoiceCountChoice[1+baseIndChoice]+dynChoiceCountChoice[5+baseIndChoice]+dynChoiceCountChoice[9+baseIndChoice]+dynChoiceCountChoice[13+baseIndChoice]+dynChoiceCountChoice[17+baseIndChoice]+dynChoiceCountChoice[21+baseIndChoice]+dynChoiceCountChoice[25+baseIndChoice]+dynChoiceCountChoice[29+baseIndChoice];
					
				elseif j==2 then
					leftCount=dynChoiceCount[0+baseInd]+dynChoiceCount[8+baseInd]+dynChoiceCount[16+baseInd]+dynChoiceCount[24+baseInd]+dynChoiceCount[128+baseInd]+dynChoiceCount[136+baseInd]+dynChoiceCount[144+baseInd]+dynChoiceCount[152+baseInd]+dynChoiceCount[256+baseInd]+dynChoiceCount[264+baseInd]+dynChoiceCount[272+baseInd]+dynChoiceCount[280+baseInd]+dynChoiceCount[384+baseInd]+dynChoiceCount[392+baseInd]+dynChoiceCount[400+baseInd]+dynChoiceCount[408+baseInd];
					rightCount=dynChoiceCount[1+baseInd]+dynChoiceCount[9+baseInd]+dynChoiceCount[17+baseInd]+dynChoiceCount[25+baseInd]+dynChoiceCount[129+baseInd]+dynChoiceCount[137+baseInd]+dynChoiceCount[145+baseInd]+dynChoiceCount[153+baseInd]+dynChoiceCount[257+baseInd]+dynChoiceCount[265+baseInd]+dynChoiceCount[273+baseInd]+dynChoiceCount[281+baseInd]+dynChoiceCount[385+baseInd]+dynChoiceCount[393+baseInd]+dynChoiceCount[401+baseInd]+dynChoiceCount[409+baseInd];
					leftCountChoice=dynChoiceCountChoice[0+baseIndChoice]+dynChoiceCountChoice[8+baseIndChoice]+dynChoiceCountChoice[16+baseIndChoice]+dynChoiceCountChoice[24+baseIndChoice];
					rightCountChoice=dynChoiceCountChoice[1+baseIndChoice]+dynChoiceCountChoice[9+baseIndChoice]+dynChoiceCountChoice[17+baseIndChoice]+dynChoiceCountChoice[25+baseIndChoice];
				elseif j==3 then
					
					leftCount=dynChoiceCount[0+baseInd]+dynChoiceCount[16+baseInd]+dynChoiceCount[256+baseInd]+dynChoiceCount[272+baseInd];
					rightCount=dynChoiceCount[1+baseInd]+dynChoiceCount[17+baseInd]+dynChoiceCount[257+baseInd]+dynChoiceCount[273+baseInd];
					leftCountChoice=dynChoiceCountChoice[0+baseIndChoice]+dynChoiceCountChoice[16+baseIndChoice];
					rightCountChoice=dynChoiceCountChoice[1+baseIndChoice]+dynChoiceCountChoice[17+baseIndChoice];
				end;
				#test begin
            #for test:
            leftCountMat[j+1][i-1] = leftCount;
            rightCountMat[j+1][i-1] = rightCount;

				leftCountMatChoice[j+1][i-1] = leftCountChoice;
            rightCountMatChoice[j+1][i-1] = rightCountChoice;

				totalCount = leftCount+rightCount;
				totalCountChoice = leftCountChoice+rightCountChoice;

				pValue=pValueList[leftCount+1][rightCount+1];
				pValueChoice=pValueList[leftCountChoice+1][rightCountChoice+1];
				if (pValue < maxP) then
					prob = double(rightCount)/double(totalCount);
					if abs(prob-0.5)>abs(minProb-0.5) then
						minProb=prob;
					end;
				end;
				if (pValueChoice < maxP) then
					prob = double(rightCountChoice)/double(totalCountChoice);
					if abs(prob-0.5)>abs(minProb-0.5) then
						minProb=prob;
					end;
				end;
				
				j=j+1;
         end;
			#parameter_window.set_parameter(pValueIndex, string(maxP));
         
			#the loop above is for find the minimum p-value in binomial test and the corresponding probobility to choose right

         rand =random();

         if i<=num_trials then
				if (rand > (1.0-minProb)) then
                 comChoiceHistory[i]=2;
				else
                 comChoiceHistory[i]=3;
				end;
				pUse[i]=minProb;
			end;
   end;
 
	parameter_window.set_parameter(probIndex, string(minProb));
	parameter_window.set_parameter(trialIndex,string(i));
	
	
	int nLicks=1; #initialize the lick count
	int numNolick=0;
   loop until nLicks == 0 || numNolick>=maxNolick
	begin
     int numLicks=0;
     loop
	      expval=minimum-1.0/mu*log(random())
     until
	      expval<truncate
     begin
	      expval=minimum-1.0/mu*log(random())
     end;
     nolick.set_duration(int(1000.0*expval));
     nolick.present();
	  numNolick=numNolick+1;
	  if missed == 0 then
			numNLs = numNLs + 1;
	  end;
	  parameter_window.set_parameter(nolickIndex,string(numNolick));	
     nLicks=response_manager.response_count();
   end;

  if numTrials != 0 then
		rewardRate = double(rewards) / double(numTrials) ;
		meanNL = double(numNLs) / double(numTrials); 
		parameter_window.set_parameter(meanNLIndex,string(meanNL));
		parameter_window.set_parameter(rewardRateIndex,string(rewardRate));
	end;
	
#show the choice
   
	parameter_window.set_parameter(trialIndex,string(i));

	if (i%5) == 0 then		#every 5 trials, save a temp logfile
		quicksave.present();
	end;

end;

 
term.print("\nAverage NL period: ");
term.print(meanNL);
term.print("\n"); 
term.print("\nAverage reward rate: ");
term.print(rewardRate);
term.print("\n"); 

	
	
display_window.draw_text("Free water session has ended.");
term.print("Ending time:");
term.print(date_time());

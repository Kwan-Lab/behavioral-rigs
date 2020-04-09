## Reversal Rrobabilistic Reward Task Version 7/27/18
# Only Go cue updated compared to 5/30/2018 version
#
#NOTES:  70:10 Probability Reward - Reversal
#        Switch Criteria: 10 Greedy Side for each side + Random 
#        1 second no lick period before next trial
#
#MODIFICATIONS: fixed startcode decreased to 100ms 4/7/18
#          

#-------HEADER PARAMETERS-------#
scenario = "Phase3_R71NoCue";
active_buttons = 3;							#how many response buttons in scenario
button_codes = 1,2,3;	
target_button_codes = 1,2,3;
response_logging = log_all;				#log all trials
response_matching = simple_matching;	#response time match to stimuli
default_all_responses = true;
begin;

sound {
	wavefile { filename ="SAM_5k_20FM_AM50.wav"; preload = true; };
} soundCue;

#-------SDL EVENTS ('TRIALS')-------#
trial {                           #START TRIAL
   trial_type = fixed;
   trial_duration = 100; 
	nothing {};  
	code = 41;
}startTrial1;

trial {                           #START TRIAL
   trial_type = fixed;
   trial_duration = 100; 
	nothing {};  
	code = 42;
}startTrial2;

trial {
	trial_type = fixed;
	trial_duration = 3000;	#3sec to drink LEFT
	nothing {};
	code=5;
} rewardLeft;

trial {
	trial_type = fixed;
	trial_duration = 3000;	#3sec to drink RIGHT
	nothing {};
	code=6;
} rewardRight;
trial {
	trial_type = fixed;
	trial_duration = 3000; 
	nothing {};
	code=7;
} manual;

trial {
	trial_type = fixed;
	trial_duration = 3000;
	nothing {};
	code=75; 
} norewardLeft;

trial {
	trial_type = fixed;
	trial_duration = 3000;
	nothing {};
	code=76; 
} norewardRight;

trial {                      # MISS 
	trial_type = fixed;
	trial_duration = 3000;
	nothing {};
	code=8;
} pause;

trial {                    #Intertrial No lick period 
	trial_type = fixed;
   trial_duration = 3000; 
   nothing{};
	code=90;
} noLicks;

trial {
   save_logfile {
		filename = "temp.log"; 	# use temp.log in default logfile directory
	};									#save logfile during mid-experiment
}quicksave;

#-----
trial {
	#all_responses = false;	#first_response, but ignore the responses before stimulus_time_in
	trial_type = first_response;
	trial_duration = 2000;
	sound soundCue;	# Go Cue
   code = 21; 
   target_button = 2,3;   
} responseWindow;

#--------PCL---------------
begin_pcl;
display_window.draw_text("Phase 3 - Reversal");
term.print("Starting time:");
term.print(date_time());

# PCL subroutines
string scenario =  "phase3_R71NoCue";
include "setup_Phase3R_Bandit.pcl";       # Setup file (PCL script)
include "sub_arrayMean.pcl";					# For RT
include "sub_rewardDeliveryPR.pcl"			# rewardDelivery(string target_side)
parameter_window.set_parameter(animalIDind,animalID);	

#-------------TRIAL STRUCTURE------------------------------
loop
	int i = 0
	
until
	consecMiss >= max_consecMiss
begin
	parameter_window.set_parameter(trialnumIndex,string(i) + " ("+string(block)+")"); # Trial/block in window for current trial

## Wait Cue Period  - Wait for no lick for at least 1 sec
	int nLicks = 1;        # initialize the lick count
	double expval=0.1;     # Zador biorxiv (2016)
	int numNolick = 0;
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
			
		noLicks.set_duration(int(1000.0*expval));
		state="wait cue";
		parameter_window.set_parameter(state_Index,state + "("+string(expval)+")");
		noLicks.present();
		numNolick = numNolick+1;
		nLicks    = response_manager.response_count(); #wait until no licks within 2-sec
	end;
		
## Send TT Pulse For TwoPhoton Image
	#logfile.add_event_entry("ImaTrigger");
	#port.send_code(portcode_trig, 100);  # Send pulse to SCANIMAGE for post-hoc synchronization	
## Start Trial
	state = "response_window";
	parameter_window.set_parameter(state_Index,state);		
	
	if        block==1 then startTrial1.present();
		elseif block==2 then startTrial2.present(); end;

## Response Period - After Response
	responseWindow.present();
	side="none"; 		
	double n = random();
	if response_manager.response_count()>0 then   # lick, not miss
		stimulus_data last = stimulus_manager.last_stimulus_data();
		int  RT            = last.reaction_time();
		if 	(response_manager.last_response()==2) then side = "left"; 
				leftRT.add(RT);  int meanRT = arrayMean(leftRT);   
				parameter_window.set_parameter(leftRT_index,string(RT));
				parameter_window.set_parameter(leftMeanRT_index,string(meanRT));
			elseif 	(response_manager.last_response()==3) then side = "right";
				rightRT.add(RT);  int meanRT = arrayMean(rightRT);  
				parameter_window.set_parameter(rightRT_index,string(RT));
				parameter_window.set_parameter(rightMeanRT_index,string(meanRT));
			elseif   (response_manager.last_response()==1) then side = "manual"; 
		end;
		
		if 		(block==1 && side=="left") || (block==2 && side=="right") then
						reward_threshold = 0.7; 
						nTrials_hiP = nTrials_hiP+1; 
						nTrials_hiP_total = nTrials_hiP_total+1;
						parameter_window.set_parameter(nTrials_hiP_totalIndex,string(nTrials_hiP_total));
						parameter_window.set_parameter(nTrials_hiP_blockIndex,string(nTrials_hiP));
						HPS = 1;

		elseif 	(block==2 && side=="left") || (block==1 && side=="right") then
						reward_threshold = 0.1;
						HPS = 0;

		elseif   side =="manual" then
					   reward_threshold = 1 ;
						state = "manual reward";
						parameter_window.set_parameter(state_Index,state);	
		end;
		
		if n <= reward_threshold then
			if	side=="right" then
				state="reward";
	         parameter_window.set_parameter(state_Index,state);
				rewardDeliveryPR(side);         #subrountine give water - Right
				right_r = right_r + 1;
				parameter_window.set_parameter(right_rIndex,string(right_r));
			elseif side=="left" then 
				state="reward";
	         parameter_window.set_parameter(state_Index,state);
				rewardDeliveryPR(side);          #subrountine give water - Left
				left_r = left_r +1;
				parameter_window.set_parameter(left_rIndex,string(left_r));
			elseif side=="manual" then
				state="ManualReward";
	         parameter_window.set_parameter(state_Index,state);
				if consecOutcomeL>consecOutcomeR then
				port.set_pulse_width(waterAmount_right/2);
				port.send_code(8);		#give water reward to right
				manual.present();
				else
				port.set_pulse_width(waterAmount_left/2);
				port.send_code(4);		#give water reward to left
				manual.present();
				end
			end;
			if HPS==1 then
				indHPS = indHPS + 1; end;        # Count Hit Side Reward
		else
			state="no reward";
	      parameter_window.set_parameter(state_Index,state);
			if	side=="right" then
				norewardRight.present(); # no reward
				right_no_r = right_no_r + 1;
				parameter_window.set_parameter(right_no_rIndex,string(right_no_r));
			else
				norewardLeft.present();  # no reward
				left_no_r = left_no_r +1;
				parameter_window.set_parameter(left_no_rIndex,string(left_no_r));
			end;
	   end;
		consecMiss = 0; 
		parameter_window.set_parameter(consecmissIndex,string(consecMiss));	
	else 
		state="miss pause";
	   parameter_window.set_parameter(state_Index,state);
		pause.present(); #no response --> next trial	
		consecMiss = consecMiss + 1;
		indMiss	  = indMiss + 1;
		parameter_window.set_parameter(consecmissIndex,string(consecMiss));
		parameter_window.set_parameter(indMissIndex,string(indMiss));
	end;


## Supression Failed	
	if numNolick==5 then
		state="lick supression failed";
		parameter_window.set_parameter(state_Index,state + "("+string(expval)+")");
		indNolick = indNolick +1;
	end;
	
## Control Side Lick
	if side == "left"  then
   consecOutcomeL = consecOutcomeL +1;
   consecOutcomeR =0; 
   parameter_window.set_parameter(conOutL,string(consecOutcomeL));
   parameter_window.set_parameter(conOutR,string(consecOutcomeR));
   elseif  side == "right"  then
	consecOutcomeR = consecOutcomeR +1;
   consecOutcomeL =0;
   parameter_window.set_parameter(conOutL,string(consecOutcomeL));
   parameter_window.set_parameter(conOutR,string(consecOutcomeR));
   end; 

## Update BlockType if reached maxHit 
	if nTrials_hiP>=SwitchHit then  
		if i_geo>=ii then
				block_length = 0;                        # reset  trial number within current block
				nTrials_hiP  = 0;                        # reset count
				i_geo        = double(0);                # reset i_geo 		
				if     block == 1 then block = 2;        # switch block
				elseif block == 2 then block = 1; end;
				count_switch = count_switch + 1;
				
		else i_geo = i_geo + double(1);
		end;	
	end;
	
## Random Number for Block Length: sample from truncated geometric distribution, update only after switch of high reward 
	if i_geo==double(0) && block_length==0 then
		  double shift_threshold = 1.000-0.0909; # sucess probability = 1/(mean+1),  0.0909
		  m                      = ceil(double(950)*random());
		  ii                     = double(0); #reset ii
		  double cp              = pow(shift_threshold,ii)*(double(1)-shift_threshold)*double(1000);# cummulative probablity
	   loop until m < cp
		begin
			ii = ii+double(1);
			cp = cp+pow(shift_threshold,ii)*(double(1)-shift_threshold)*double(1000);
		end;
		logfile.add_event_entry("BlockLen_"+ string(ii+10));   # indicate number of trials in a block
	end;
	
	## Window updates - details of block
	block_length = block_length+1;
	i            = i+1;	
	n_trial      = i;	# total trial number
	parameter_window.set_parameter(block_Index,string(block));           # display high reward side
	parameter_window.set_parameter(switch_count,string(count_switch));   # display # of Switches
	parameter_window.set_parameter(geo_Index,"ii="+string(ii)+" i_geo="+string(i_geo)+"m"+string(m)); # display i_geo

	if left_r+right_r>2 &&  nTrials_hiP_total>2 then
	  parameter_window.set_parameter(hiP_rateIndex,string(nTrials_hiP_total*100/(n_trial-indMiss))+"%");  # HPS preference 
	  parameter_window.set_parameter(re_Index,string(100*(left_r+right_r)/(n_trial-indMiss))+"%");  # ALL Reward Rate over All trials
	end;

	if (i%5) == 0 then		#every 5 trials, save a temp logfile
	  quicksave.present();
	end;

end;

term.print("\nFinished:");
term.print(date_time());
term.print("\nTotalLeftLick:");
term.print(string(left_no_r+left_r));
term.print("\nTotalRightLick:");
term.print(string(right_no_r+right_r));
term.print("\nWater Amount Left:");
term.print(string(waterAmount_left));
term.print("\nWater Amount Right:");
term.print(string(waterAmount_right));
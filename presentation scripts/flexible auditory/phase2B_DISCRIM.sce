#--DISCRIMINATION PHASE 2B--#
#--Sound discrimination training: "novice mode" with grace period and random ITIs--#
#
# PURPOSE: Training for two-choice auditory-motor mapping task. Phase 2B introduces random intertrial intervals (ITI).
#
# AUDITORY-MOTOR MAPPINGS: [UPSWEEP::LEFT LICK] AND [DOWNSWEEP::RIGHT LICK] REWARDED; INCORRECTs TRIGGER TIMEOUT
#
# OTHER NOTES:
# 1. "Novice mode": 3 consecutive hits on one side without contralateral hit --> automatic contralateral stimulus (see subs)
# 2. "Grace period": Responses registered within the first 500 ms of stimulus are unreinforced and do not affect control flow of trial.
# 3. Random intertrial interval(ITI) for all trials. Next cue is presented X ms post response, where X ~ Exp(p) 
#		or (1000+X) ms post cue offset for miss trials (to match minimum inter-cue interval from hit trials).
# 4. Reserve codes {1,2,3} for responses, {1:20} for non-stimulus events, and {21:end} for stimulus events.
#
# TRAINING PROGRESSION:
# 1. phase0_FREEWATER: 		Introduce collection of water from lickports until ~100 total licks/session (1-2 days)
# 2. phase1_ALTERNATION:	(2 days)
# 3. phase2A_DISCRIM:		Grace period (see SDL defaults) and novice mode (see subs) included; 
#										constant ITI; timeout ITI longer than ITI for hits. 
#										Train to three consecutive days above chance performance.
# 4. phase2B_DISCRIM: 		Random (exponential) ITI. 
#										Train to three consecutive days above 90%.
# 5. phase2C_DISCRIM:		Grace period removed. Licks are immediately reinforced and affect control flow of trial.
# 6. phase2D_DISCRIM:		Novice mode removed; "expert mode." Subjects are now ready for Rule Switching Task.
#
# AUTHORS: MJ Siniscalchi and AC Kwan, 6/9/17
# LAST EDIT:  

#-------SDL HEADER----------------------------------------------------------------------------------------#
scenario = "phase2B_DISCRIM";

active_buttons = 3;	# Number of response buttons in experiment (need three for lick_left, lick_right, & spacebar in earlier phases)
button_codes = 1,2,3; 	
target_button_codes = 1,2,3;
response_logging = log_all; # Log all responses, even when stimuli are inactive
response_matching = simple_matching;	# response time match to stimuli

#DEFAULTS
default_all_responses = false;
default_trial_type = fixed;
default_stimulus_time_in = 500; # For phase2a and 2b of training: "grace period"

begin;

#-------LOAD SDL SOUND STIMULI----------------------------------------------------------------------------#

sound {
	wavefile { filename ="UpSweeps.wav"; preload = true; };
} upsweep;

sound {
	wavefile { filename ="DownSweeps.wav"; preload = true; };
} downsweep;

sound {
	wavefile { filename ="whitenoise1sec.wav"; preload=true; };
} whitenoise;

#-------SDL EVENTS-------#

trial { #START TRIAL
   trial_duration = 500; 
	nothing {}; 
	code = 4;
}startTrial;

trial { #REWARD COLLECTION PERIOD (LEFT)
	trial_duration = 3000;	#3 sec to retrieve water drop
	nothing {};
	code = 5;
}rewardLeft;

trial { #REWARD COLLECTION PERIOD (RIGHT)
	trial_duration = 3000;	# 3 sec to retrieve water drop
	nothing {};
	code = 6;
}rewardRight;

trial { #TIMEOUT AFTER INCORRECT
	trial_duration = 3000; # Extra 3 sec added to ITI as punishment. 
	sound whitenoise;			
	code = 7; 	
}timeout;

trial { #PAUSE AFTER MISS
   trial_duration = 1500;	# To match ~duration of miss trials with shortest hit trial. 
	nothing {}; # Without grace period, use 1000 ms.
	code = 8; 
}pause;

trial { #END TRIAL  
   trial_duration = 500; 
	nothing {};
	code = 9;
}endTrial;

trial { #SAVE TEMP LOGFILE
	save_logfile {	
		filename = "temp.log"; # Path is default logfile dir
	}; # Save every 5 trials in case of failure.
}quickSave;


#-------SDL STIMULUS PRESENTATION EVENTS-------#

trial { #UPSWEEP
	trial_type = first_response;	
	trial_duration = 2000;	
	sound upsweep;  
	code = 21;	
	target_button = 2;
}upsweepCue;

trial { #DOWNSWEEP
	trial_type = first_response;	
	trial_duration = 2000;	
	sound downsweep;  
	code = 22;	
	target_button = 3;
}downsweepCue;		

#-------PCL---------------------------------------------------------------------------------------#

begin_pcl;

#SET TASK PARAMETERS AND INITIALIZE TRIAL VARIABLES
include "ini_DISCRIM.pcl"; # Initialization file (PCL script) 

# SETUP LOGFILE, OUTPUT FILES, DISPLAY, TERMINAL, & PARAMETER WINDOW
include "setup_DISCRIM.pcl"; # Setup file (PCL script)

# PCL SUBROUTINES
include "sub_noviceStim.pcl";				# int noviceStim(int trial_type, array<int> consec_hits[2]) 
include "sub_rewardDelivery.pcl";		# rewardDelivery(string target_side)
include "sub_printStats.pcl";				# printStats(output_file ofile)
include "sub_printConfig_DISCRIM.pcl"; # print_BehaviorConfig(string fname output_file ofile)
include "sub_drawExpITIs.pcl";			# array <int,1> drawExpITIs(int min, int max, double lambda, int nTrials)

# RANDOM INTERTRIAL INTERVALS
ITI = drawExpITIs(EXP_min, EXP_max, EXP_lambda, max_trials);

# PARAMETER LOG
print_BehaviorConfig(fname_parameterLog, parameterLog);

#-------BEGIN SESSION-------#
display_window.draw_text("Phase 2B: Sound Discrimination (Random ITIs)...");
term.print("Starting time:");
term.print(startTime);

loop int i = 1
until	consecMiss >= max_consecMiss || i > max_trials
begin

# SET TRIAL PARAMETERS 
trialType = int(ceil(random()*double(2))); # Randomize cue
trialType = noviceStim(trialType,consecHits); # Novice mode.
endTrial.set_duration(ITI[i]); # Set intertrial interval (int value in ms)

# BEGIN TRIAL AND PRESENT SOUND CUE
port.send_code(portcode_trig, 500);  # Send pulse to SCANIMAGE for post-hoc synchronization
startTrial.present();	
 
if trialType==1 then # Upsweep trial
	upsweepCue.present();
	targetSide = "left";
elseif trialType==2 then # Downsweep trial	
	downsweepCue.present();
	targetSide = "right";
end; 

# TRIAL OUTCOME
if (response_manager.hits() > 0) then	# Correct trial
	rewardDelivery(targetSide);
	outcome = 1;
	consecMiss = 0;
elseif (response_manager.incorrects() > 0) then	# Incorrect trial
	timeout.present();
	outcome = 2;	
	consecMiss = 0;
else	# Miss
	pause.present();
	outcome = 3;
	consecMiss = consecMiss + 1;
end;

# UPDATE TRIAL STATS
outcomeArray[trialType][outcome] = outcomeArray[trialType][outcome] + 1; 

int temp = outcomeArray[trialType][1]+outcomeArray[trialType][2];
if temp > 0 then
	hitRates[trialType] = outcomeArray[trialType][1]*100/temp; # Hitrate by trialType: hit/hit+incorrect
end;

temp = response_manager.total_hits() + response_manager.total_incorrects();
if temp > 0 then totalHitRate = response_manager.total_hits()*100/temp;
else totalHitRate = 0; # Overall hitrate: hit/hit+incorrect
end;

if outcome==1 then  # For novice mode: update consecHits 
	if trialType==1 then 
		consecHits[2] = 0; 
	elseif trialType==2 then
		consecHits[1] = 0;
	end;
	consecHits[trialType] = consecHits[trialType]+1;
end;

# PARAMETER WINDOW
string tempStr = string(outcomeArray[trialType][1])+"   "+string(outcomeArray[trialType][2])
	+ "   " + string(outcomeArray[trialType][3]) + "     " + string(hitRates[trialType]);
parameter_window.set_parameter(trialTypeIdx[trialType], tempStr);
parameter_window.set_parameter(consecmissIndex, string(consecMiss));
parameter_window.set_parameter(trialnumIndex, string(i)+" ("+string(totalHitRate)+"%)");
parameter_window.set_value_width(parameter_window.TEXT_COLUMN_WIDTH); #set width to max text width

# DISPLAY WINDOW
tempStr = string(rewardRight.duration() + endTrial.duration() + startTrial.duration());
display_window.erase();
display_window.draw_text("ITI: "+tempStr+" ms"); # Display ITI

# UPDATE STATS LOG
printStats(fname_statsLog, statsLog);

# QUICKSAVE
if mod(i,5)==0 then
quickSave.present(); # Save temp logfile every five trials.
end;

# INCREMENT TRIAL
endTrial.present();	
i=i+1;

end; # End main trial loop.

# TERMINAL OUTPUT	
display_window.draw_text("Training has ended. Congratulate your mouse!");
term.print("\nEnding time:");
term.print(date_time());
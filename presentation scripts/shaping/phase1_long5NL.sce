#--DISCRIMINATION PHASE 1--#

#
# PURPOSE: Training for lick-based water collection in two-choice tasks. Lick suppression
#
# OTHER NOTES:
# 1. Reserve codes {1,2,3} for responses, {1:20} for non-stimulus events, and {21:end} for stimulus events.
#
# TRAINING PROGRESSION:
# 1. phase0_FREEWATER: 		Introduce collection of water from lickports until ~100 total licks/session (1-2 days)
# 2. phase1_long5NL:

#
# AUTHORS: Hongli Wang, modified from MJ Siniscalchi and AC Kwan, 6/26/17
# LAST EDIT:

#-------SDL HEADER----------------------------------------------------------------------------------------#
scenario = "phase0_NOLICK";

active_buttons = 3;	# Number of response buttons in experiment (need three for lick_left, lick_right, & spacebar in earlier phases)
button_codes = 1,2,3;
target_button_codes = 1,2,3;
response_logging = log_all; # Log all responses, even when stimuli are inactive
response_matching = simple_matching;

#DEFAULTS
default_all_responses = true;
default_trial_type = fixed;

begin;

#-------SOUND STIMULI-------#
sound {
	wavefile { filename ="tone_5000Hz_0.2Dur.wav"; preload = true; };
} go;

#-------SDL EVENTS-------#

trial { #START TRIAL
   trial_duration = 100;
	nothing {};
	code = 5;
}startTrial;

trial {
   trial_type = first_response;
   trial_duration = 2000;
	nothing {};
   code=0;
	sound go;
}waitlick;

trial { #REWARD COLLECTION PERIOD (LEFT)
	trial_duration = 3000;	#3 sec to retrieve water drop
	nothing {};
	code = 10;
}reward;

trial { #REWARD COLLECTION PERIOD (RIGHT)
	trial_duration = 3000;	# 3 sec to retrieve water drop
	nothing {};
	code = 7;
}rewardRight;

trial { #REWARD COLLECTION PERIOD (BOTH SIDES)
	trial_duration = 3000;	#3 sec to retrieve water drop
	nothing {};
	code = 8;
}rewardBothSides;


trial {
	trial_type = fixed;
	trial_duration = 1000;
	nothing {} pauseevent;
	code = 6;
}pause;

trial {
	trial_type = fixed;
	trial_duration = 2500;
	nothing {} nolickevent;
	code=19;
}nolick;

trial { #SAVE TEMP LOGFILE
	save_logfile {
		filename = "temp.log"; # Path is default logfile dir
	}; # Save every 5 trials in case of failure.
}quicksave;

#-------PCL---------------------------------------------------------------------------------------

begin_pcl;

# SET TASK PARAMETERS AND INITIALIZE TRIAL VARIABLES

#GET INI FILE
preset string user_name = "DEFAULT"; # Prompt user for file prefix, e.g., initials "MJS"
string ini_pathname = "C:\\Users\\MITRAL\\Desktop\\Presentation\\ini_"+user_name+".pcl";

#SET TASK PARAMETERS
include "sub_getParameterValue.pcl";

int waterAmount_left = int(get_parameterValue(ini_pathname,"waterAmount_left",60)); # Valve open duration in ms
int waterAmount_right = int(get_parameterValue(ini_pathname,"waterAmount_right",60));
int max_rewards = int(get_parameterValue(ini_pathname,"max_rewards",1000));  # Normally, set arbitrarily high.
int interpulse_interval = 500; # Time between left and right pulses for manual feed - necessary for single reservoir ("parallel circuit").

#INITIALIZE BEHAVIORAL VARIABLES
int manualFeed = 0;
int leftLicks = 0;
int rightLicks = 0;
preset int max_consecMiss = 20;                                                                                 ; #triggers end session, for mice, set to 20
int consecMiss = 0;

#INITIALIZE OUTPUT PORT VARIABLES
output_port port = output_port_manager.get_port(1);
int portcode_left = 4; # Digital I/O # is log base2 of portcode
int portcode_right = 8;

#LOGFILE & PARAMETER LOG
string dateStr = (date_time("yymmddhhnn")); # Store startTime in str for naming files
logfile.set_filename(logfile.subject() +"_FREEWATER_"+ dateStr + ".log"); #unique filename for session, e.g., M40_DISCRIM_1706221807

string fname_parameterLog = "parameterLog_" + logfile.subject() +"_"+ dateStr + ".txt";
output_file parameterLog = new output_file;

#for generating exponetial distribution (white noise block)
double minimum=1.0;
double mu=0.333333; #rate parameter for exponential distribution
double truncate=5.0;
double expval=0.0;

#SETUP TERMINAL WINDOW
term.print("Starting time: ");
term.print(date_time());
logfile.add_event_entry(date_time());
display_window.draw_text("Initializing...");

#SETUP PARAMETER WINDOW
int count; # Response counter
int idx; # Index for displaying response counts
parameter_window.remove_all();
int manualFeedIndex = parameter_window.add_parameter("Manual Feeds");
int leftLickIndex = parameter_window.add_parameter("Left Rewards");
int rightLickIndex = parameter_window.add_parameter("Right Rewards");
int missIndex = parameter_window.add_parameter("ConsecMiss");
int nolickIndex = parameter_window.add_parameter("#NL");
int maxNoLick=5;

#-------BEGIN SESSION-------#
display_window.draw_text("Phase 0: Licks to left or right port trigger water reward. Press <SPACE> for manual feed to both ports...");

loop int i = 1
	until	leftLicks + rightLicks >= max_rewards
	begin

	startTrial.present();
# WAIT FOR RESPONSE
	waitlick.present();

	if response_manager.response_count()>0 then
		if response_manager.response_count(2)>0 then			# Left lick detected?
			port.send_code(portcode_left, waterAmount_left); # Give pulse for water reward
			reward.present();
			leftLicks = leftLicks + 1; # Response count for parameter window.
			idx = leftLickIndex;
			count = leftLicks;

		elseif response_manager.response_count(3)>0 then	# Right lick detected?
			port.send_code(portcode_right, waterAmount_right); #give pulse for water reward
			reward.present();
			rightLicks = rightLicks + 1;
			idx = rightLickIndex; # For parameter window.
			count = rightLicks;

		elseif response_manager.response_count(1)>0 then	# Manual feed.
			port.send_code(portcode_left, waterAmount_left); #give pulse for water reward
			wait_interval(interpulse_interval);
			port.send_code(portcode_right, waterAmount_right); #give pulse for water reward
			reward.present();
			manualFeed = manualFeed+1;
			idx = manualFeedIndex;
			count = manualFeed;
		end;
		parameter_window.set_parameter(idx,string(count));
	else
		pause.present();
		consecMiss=consecMiss+1;
		parameter_window.set_parameter(missIndex,string(consecMiss));
	end;

	#logfile.add_event_entry("nolickloop_begin");
   int nLicks=1; #initialize the lick count
	int numNoLick=0;
   loop until nLicks == 0 || numNoLick>=maxNoLick
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
	  numNoLick=numNoLick+1;
	  parameter_window.set_parameter(nolickIndex,string(numNoLick));
     nLicks=response_manager.response_count();
   end;


# TEMP LOGFILE
	if (i%5) == 0 then	# Every 5 trials, save a temporary logfile (in case of power outage, etc.).
		quicksave.present();
	end;

	i=i+1; # Increment trial.

end; # End loop

display_window.draw_text("Phase 0 training has ended.");
term.print("Ending time:");
term.print(date_time());

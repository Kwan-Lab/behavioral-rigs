#-- scenario file --#

scenario = "florent_blocks";

active_buttons = 3;	#how many response buttons in scenario
button_codes = 1,2,3;		#button_code 1 = lick, 2 = spacebar
target_button_codes = 1,2,3; #target_button_code 1 = lick, 2 = spacebar
#write_codes = true;	#using analog output port to sync with electrophys		
response_logging = log_all;	#log all trials
response_matching = simple_matching;	#response time match to stimuli

begin;

trial {
   save_logfile {
		filename = "temp.log"; 	# use temp.log in default logfile directory
	};									#save logfile during mid-experiment
}quicksave;

trial {
	trial_type = fixed;
	trial_duration = 100;
	nothing {} startwaterevent;
   code=0; #port_code=1;
	target_button = 1,2,3;
}startwaterblock;

trial {
	trial_type = fixed;
	trial_duration = 100;
	nothing {} startsmallevent;
   code=1; #port_code=1;
	target_button = 1,2,3;
}startsmallblock;

trial {
	trial_type = fixed;
	trial_duration = 100;
	nothing {} startlargeevent;
   code=2; #port_code=1;
	target_button = 1,2,3;
}startlargeblock;


trial {
	trial_type = fixed;
	trial_duration = 100;
	nothing {} waitwaterevent;
   code=7; #port_code=1;
	target_button = 1,2,3;
}waitwaterblock;

trial {
	trial_type = fixed;
	trial_duration = 100;
	nothing {} waitsmallevent;
   code=8; #port_code=1;
	target_button = 1,2,3;
}waitsmallblock;

trial {
	trial_type = fixed;
	trial_duration = 100;
	nothing {} waitlargeevent;
   code=9; #port_code=1;
	target_button = 1,2,3;
}waitlargeblock;

trial {
	trial_type = fixed;
	trial_duration = 5000;
	nothing {} waterevent;
	code=3; #port_code=1.5;
	target_button = 1,2,3;
}waterreward;

trial {
	trial_type = fixed;
	trial_duration = 5000;
	nothing {} smallevent;
	code=4; #port_code=2;
	target_button = 1,2,3;
}smallreward;

trial {
	trial_type = fixed;
	trial_duration = 5000;
	nothing {} largeevent;
	code=5; #port_code=2.5;
	target_button = 1,2,3;
}largereward;

begin_pcl;

term.print("Starting time:");
term.print(date_time());
logfile.add_event_entry(date_time());

display_window.draw_text("Initializing...");

int num_trials = 10000;  # user enters initial value in dialog before scenario
preset int water_amount = 22;	# #msec to open water valve
preset int second_amount = 22;	# #msec to open water valve
preset int third_amount = 22;	# #msec to open water valve
int hit=0;
int rewardNum=0;
int timer = 0;  #(in ms) 

array <int> blockConc[4]={1, 2, 3, 2}; 
int currBlock=1;

parameter_window.remove_all();
int blockIndex = parameter_window.add_parameter("Block");
int rewardSizeIndex = parameter_window.add_parameter("Reward size");
int timeIndex = parameter_window.add_parameter("Time");
int hitIndex = parameter_window.add_parameter("# Lick");
int rewardNumIndex = parameter_window.add_parameter("# Reward");

# set up parallel port for water reward
output_port port = output_port_manager.get_port(1);

display_window.draw_text("Training has started...");

loop
	int i = 1
until
	i > num_trials
begin
	
	if i==1 then
		timer=clock.time();
		port.set_pulse_width(100);  #send pulse to National Inst Board
		port.send_code(32);
	end;

	parameter_window.set_parameter(blockIndex,string(currBlock));
	int sucroseConc=blockConc[currBlock];
	parameter_window.set_parameter(rewardSizeIndex,string(sucroseConc));								

	#look for at least 1 reward to start 60 sec timer
	loop
		int jj = 0
	until
		jj > 0		#jj is a flag, 0 = wait more, 1 = go to 60sec window
	begin
		
		if (clock.time()-timer > 59999) then  #to start new file every 60s if total <10 licks 
			port.set_pulse_width(100);  #send pulse to National Inst Board
			port.send_code(32);
			timer = clock.time();
		end;
		
		if sucroseConc==1 then
			waitwaterblock.present();
		elseif sucroseConc==2 then
			waitsmallblock.present();
		elseif sucroseConc==3 then
			waitlargeblock.present();
		end;
		if (response_manager.hits() > 0) then
			hit = hit + response_manager.hits();			
		end;
		if hit>9 then		#FR10, if more than 10 licks has occurred	
			rewardNum = rewardNum + 1;
			parameter_window.set_parameter(rewardNumIndex,string(rewardNum));
			if sucroseConc==1 then
				port.set_pulse_width(water_amount);
				port.send_code(4);		#give water reward	
				waterreward.present();
			elseif sucroseConc==2 then
				port.set_pulse_width(second_amount);
				port.send_code(8);		#give 3% sucrose reward	
				smallreward.present();
			elseif sucroseConc==3 then
				port.set_pulse_width(third_amount);
				port.send_code(16);		#give 10% sucrose reward	
				largereward.present();			
			end;
			hit = 0;	#reset #lick to start counting again
			jj= 1;	#reward block is 5 s long
		end;	
			
		parameter_window.set_parameter(hitIndex,string(hit));		
		parameter_window.set_parameter(timeIndex,string(jj));	
	end;
	
	# start 60 sec for repeated rewards of same type
	port.set_pulse_width(100);  #send pulse to National Inst Board
	port.send_code(32);
	
	loop
		int jj = 0
	until
		jj > 59999		#at 60 sec, move to next block
	begin
		if sucroseConc==1 then
			startwaterblock.present();
		elseif sucroseConc==2 then
			startsmallblock.present();
		elseif sucroseConc==3 then
			startlargeblock.present();
		end;
		jj=jj+100;	#start block is 0.1 s long
		if (response_manager.hits() > 0) then
			hit = hit + response_manager.hits();			
		end;
		if hit>9 then		#FR10, if more than 10 licks has occurred	
			rewardNum = rewardNum + 1;
			parameter_window.set_parameter(rewardNumIndex,string(rewardNum));
			if sucroseConc==1 then
				port.set_pulse_width(water_amount);
				port.send_code(4);		#give water reward	
				waterreward.present();
			elseif sucroseConc==2 then
				port.set_pulse_width(second_amount);
				port.send_code(8);		#give 3% sucrose reward	
				smallreward.present();
			elseif sucroseConc==3 then
				port.set_pulse_width(third_amount);
				port.send_code(16);		#give 10% sucrose reward	
				largereward.present();			
			end;
			hit = 0;	#reset #lick to start counting again
			jj=jj+5000;	#reward block is 5 s long
		end;	
			
		parameter_window.set_parameter(hitIndex,string(hit));		
		parameter_window.set_parameter(timeIndex,string(jj/1000));	
	end;
	
	if currBlock<4 then
		currBlock=currBlock+1;
		
	elseif currBlock==4 then
		currBlock=1;
	end;
	
	i=i+1;
	if (i%5) == 0 then		#every 5 trials, save a temp logfile
		quicksave.present();
	end;
end;

display_window.draw_text("Training has ended.");
term.print("Ending time:");
term.print(date_time());
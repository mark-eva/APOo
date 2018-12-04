#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use File::Copy;
use Env;
use Term::ANSIColor;



#-----------------------------------------------------------------------------------------
#Global Variables
#-----------------------------------------------------------------------------------------
our $APOO = "/oracle/scripts/APOo";
our $ORACLE_HOME = "";
our $ORACLE_SID  = "";
our $ORACLE_USER = $ENV {'USER'};
our $SQL_SCRIPTS = "/oracle/scripts/APOo/stop_and_start";
our $CONF_DIR = "$APOO/config";
our $AUTOSTART = "";
our $oratab_pe  = "";


our $CMD_DISCOVER_ALL_INSTANCE = "sqlplus / as sysdba \@$SQL_SCRIPTS/discover_all_instance.sql";
our $CMD_DELETE_GENERAL_CONFIG = "rm $APOO/config/all_instance.log";
our $CMD_TOUCH_GENERAL_CONFIG = "touch $APOO/config/all_instance.log";

our $GENERATE_PE_CONF = "cat $CONF_DIR/all_instance.log | grep -i primary | grep -i enterprise > $CONF_DIR/pe.conf";
our $GENERATE_SE_CONF = "cat $CONF_DIR/all_instance.log | grep -i standby | grep -i enterprise > $CONF_DIR/se.conf";
our $GENERATE_PS_CONF = "cat $CONF_DIR/all_instance.log | grep -i primary | grep Standard | grep -v MOUNTED  > $CONF_DIR/ps.conf";
our $GENERATE_SS_CONF = "cat $CONF_DIR/all_instance.log | grep -i mounted | grep Standard > $CONF_DIR/ss.conf";

our $CMD_COUNT_DB_INSTANCE_0= "cat $CONF_DIR/pe.conf | wc -l";
our $CMD_COUNT_DB_INSTANCE_1= "cat $CONF_DIR/se.conf | wc -l";
our $CMD_COUNT_DB_INSTANCE_2= "cat $CONF_DIR/ps.conf | wc -l";
our $CMD_COUNT_DB_INSTANCE_3= "cat $CONF_DIR/ss.conf | wc -l";

our $CMD_SHUTDOWN_EE =  "$APOO/stop_and_start/dbshut_EE $ORACLE_HOME";
our $CMD_SHUTDOWN_SE =  "$APOO/stop_and_start/dbshut_SE $ORACLE_HOME";

our $CMD_STARTUP_PS = "$APOO/stop_and_start/dbstart_primary_standard $ORACLE_HOME";
our $CMD_STARTUP_PE = "$APOO/stop_and_start/dbstart_primary_enterprise $ORACLE_HOME";


chomp $ORACLE_HOME;
chomp $ORACLE_SID;
chomp $ORACLE_USER;


`$CMD_TOUCH_GENERAL_CONFIG`;
`$CMD_DELETE_GENERAL_CONFIG`;


#-----------------------------------------------------------------------------------------
#Detect database versions and Roles for each instance and set up the corresponding config
#-----------------------------------------------------------------------------------------

open (FILE, "/etc/oratab") || die "Cannot open your file";
while (my $line = <FILE> )
{
        chomp $line;
	($ORACLE_SID, $ORACLE_HOME ) = (split /:/, $line)[0, 1];

	$ENV{ORACLE_SID}="$ORACLE_SID";
	$ENV{ORACLE_HOME}="$ORACLE_HOME";


	`$CMD_DISCOVER_ALL_INSTANCE`;			
}
close (FILE);

#---Segregate config for Primary/Standby and EE/SE version

`$GENERATE_PE_CONF`;
`$GENERATE_SE_CONF`;
`$GENERATE_PS_CONF`;
`$GENERATE_SS_CONF`;

#--Check if there are any database instance on each config file

our $PE_COUNT = `$CMD_COUNT_DB_INSTANCE_0`;
our $SE_COUNT = `$CMD_COUNT_DB_INSTANCE_1`;
our $PS_COUNT = `$CMD_COUNT_DB_INSTANCE_2`;
our $SS_COUNT = `$CMD_COUNT_DB_INSTANCE_3`;

print  color ("green"),  "Primary Databases on Enterprise:", color ("reset");
print "$PE_COUNT";
print  color ("green"),  "Standby Databases on Enterprise:", color ("reset");
print "$SE_COUNT";
print  color ("green"),  "Primary Databases on Standard:", color ("reset");
print "$PS_COUNT";
print  color ("green"),  "Standby Databases on Standard:", color ("reset");
print "$SS_COUNT\n";

#---Clean up previous config files
our $CMD_DEL_CONF0 = "rm $CONF_DIR/primary_ee.conf 2>/dev/null";
our $CMD_DEL_CONF1 = "rm $CONF_DIR/standby_ee.conf 2>/dev/null";
our $CMD_DEL_CONF2 = "rm $CONF_DIR/primary_se.conf 2>/dev/null";
our $CMD_DEL_CONF3 = "rm $CONF_DIR/standby_se.conf 2>/dev/null";
our $CMD_DEL_CONF4 = "rm $CONF_DIR/ee.conf 2>/dev/null";


`$CMD_DEL_CONF0`;
`$CMD_DEL_CONF1`;
`$CMD_DEL_CONF2`;
`$CMD_DEL_CONF3`;
`$CMD_DEL_CONF4`;



#--Process each config file that has a database instance in it

#------------------------------------------
#Primary Database running on Enterprise   |------------------------------------------------------------------------------------------------
#------------------------------------------
if ($PE_COUNT > 0 )
{

	open (FILE, "$CONF_DIR/pe.conf") || die "Cannot open your file";
	while (my $line = <FILE> )
	{
           chomp $line;
           my @fields =	($ORACLE_SID, $ORACLE_HOME, $AUTOSTART ) = (split /:/, $line)[3, 4, 5];
	   my $filename = "$CONF_DIR/primary_ee.conf";	
           my $oratab_pe  = "$ORACLE_SID:$ORACLE_HOME:$AUTOSTART \n";
	  
	   
	
	  
	   open(FH, '>>', $filename) or die $!;	
	   print FH $oratab_pe;
	   close(FH);
	
	}
	close (FILE);
	
}
else 
{
	my $temp_config = "touch $CONF_DIR/primary_ee.conf";
	`$temp_config`;
}

#-----------------------------------------
#Standby  Database running on Enterprise  |------------------------------------------------------------------------------------------------
#-----------------------------------------

if ($SE_COUNT > 0 )
{

        open (FILE, "$CONF_DIR/se.conf") || die "Cannot open your file";
        while (my $line = <FILE> )
        {
           chomp $line;
           my @fields = ($ORACLE_SID, $ORACLE_HOME, $AUTOSTART ) = (split /:/, $line)[3, 4, 5];
           my $filename = "$CONF_DIR/standby_ee.conf";
           my $oratab_pe  = "$ORACLE_SID:$ORACLE_HOME:$AUTOSTART \n";



           open(FH, '>>', $filename) or die $!;
           print FH $oratab_pe;
           close(FH);

        }
        close (FILE);

}
else
{
	my $temp_config = "touch $CONF_DIR/standby_ee.conf";
	`$temp_config`;
}

#-----------------------------------------
#Primary  Database running on Standard   |------------------------------------------------------------------------------------------------
#-----------------------------------------

if ($PS_COUNT > 0 )
{
        open (FILE, "$CONF_DIR/ps.conf") || die "Cannot open your file";
        while (my $line = <FILE> )
        {
           chomp $line;
           my @fields = ($ORACLE_SID, $ORACLE_HOME, $AUTOSTART ) = (split /:/, $line)[3, 4, 5];
           my $filename = "$CONF_DIR/primary_se.conf";
           my $oratab_pe  = "$ORACLE_SID:$ORACLE_HOME:$AUTOSTART \n";



           open(FH, '>>', $filename) or die $!;
           print FH $oratab_pe;
           close(FH);

        }
        close (FILE);

}
else
{
	my $temp_config = "touch $CONF_DIR/primary_se.conf";
	`$temp_config`;
}

#-----------------------------------------
#Standby  Database running on Standard   |------------------------------------------------------------------------------------------------
#-----------------------------------------

if ($SS_COUNT > 0 )
{

        open (FILE, "$CONF_DIR/ss.conf") || die "Cannot open your file";
        while (my $line = <FILE> )
        {
           chomp $line;
           my @fields = ($ORACLE_SID, $ORACLE_HOME, $AUTOSTART ) = (split /:/, $line)[3, 4, 5];
           my $filename = "$CONF_DIR/standby_se.conf";
           my $oratab_pe  = "$ORACLE_SID:$ORACLE_HOME:$AUTOSTART \n";



           open(FH, '>>', $filename) or die $!;
           print FH $oratab_pe;
           close(FH);

        }
        close (FILE);

}
else
{
	my $temp_config = "touch $CONF_DIR/standby_se.conf";
	`$temp_config`;
}

#----------------------------------------------
#Combine all EE instances in one config file   |------------------------------------------------------------------------------------------------
#----------------------------------------------
our $COUNT_EE_INSTANCES = $PE_COUNT + $SE_COUNT;
print color ("green"), "Enterprise Databases total:", color ("reset");
print "$COUNT_EE_INSTANCES\n";

if ($COUNT_EE_INSTANCES > 0 )
{
   if ($PE_COUNT > 0)
     {	
	open (FILE, "$CONF_DIR/primary_ee.conf") || die "Cannot open your file";
	while (my $line = <FILE> )
	{
	   chomp $line;
	   my @fields = ($ORACLE_SID, $ORACLE_HOME, $AUTOSTART ) = (split /:/, $line)[0, 1, 2];
	   my $filename = "$CONF_DIR/ee.conf";
	   my $oratab_pe  = "$ORACLE_SID:$ORACLE_HOME:$AUTOSTART \n";


	   open(FH, '>>', $filename) or die $!;
	   print FH $oratab_pe;
	   close(FH);
	}	
	close (FILE);
     }

   
   if ($SE_COUNT > 0) 
     { 
	open (FILE, "$CONF_DIR/standby_ee.conf") || die "Cannot open your file";
	while (my $line = <FILE> )
	{
	   chomp $line;
	   my @fields = ($ORACLE_SID, $ORACLE_HOME, $AUTOSTART ) = (split /:/, $line)[0, 1, 2];
	   my $filename = "$CONF_DIR/ee.conf";
	   my $oratab_pe  = "$ORACLE_SID:$ORACLE_HOME:$AUTOSTART \n";


	   open(FH, '>>', $filename) or die $!;
	   print FH $oratab_pe;
	   close(FH);
	}
	close (FILE);
     }
}	
else 
{
	print "No Enterprise Database running on this box \n";
	my $temp_config = "touch $CONF_DIR/ee.conf";
	`$temp_config`;
	
}

#----------------------------------------------
#Combine all SE instances in one config file   |------------------------------------------------------------------------------------------------
#----------------------------------------------
our $COUNT_SE_INSTANCES = $PS_COUNT + $SS_COUNT;
print color ("green"), "Standard Database total:", color ("reset");
print "$COUNT_SE_INSTANCES \n";

if ($COUNT_SE_INSTANCES > 0 )
{
   if ($PS_COUNT > 0)
     {	
	open (FILE, "$CONF_DIR/primary_se.conf") || die "Cannot open your file";
	while (my $line = <FILE> )
	{
	   chomp $line;
	   my @fields = ($ORACLE_SID, $ORACLE_HOME, $AUTOSTART ) = (split /:/, $line)[0, 1, 2];
	   my $filename = "$CONF_DIR/se.conf";
	   my $oratab_ps  = "$ORACLE_SID:$ORACLE_HOME:$AUTOSTART \n";


	   open(FH, '>>', $filename) or die $!;
	   print FH $oratab_ps;
	   close(FH);
	}	
	close (FILE);
     }

   
   if ($SS_COUNT > 0) 
     { 
	open (FILE, "$CONF_DIR/standby_se.conf") || die "Cannot open your file";
	while (my $line = <FILE> )
	{
	   chomp $line;
	   my @fields = ($ORACLE_SID, $ORACLE_HOME, $AUTOSTART ) = (split /:/, $line)[0, 1, 2];
	   my $filename = "$CONF_DIR/se.conf";
	   my $oratab_ss  = "$ORACLE_SID:$ORACLE_HOME:$AUTOSTART \n";


	   open(FH, '>>', $filename) or die $!;
	   print FH $oratab_ss;
	   close(FH);
	}
	close (FILE);
     }
}	
else 
{
	my $temp_config = "touch $CONF_DIR/se.conf";
	`$temp_config`;
	
}

#----------------------------------------------
#Patch Enterprise databases if there is any   |------------------------------------------------------------------------------------------------
#----------------------------------------------

#---Check if ee config has some databases in it
if ($COUNT_EE_INSTANCES > 0 )
{
	open (FILE, "$CONF_DIR/ee.conf") || die "Cannot open your file";

	while (my $line = <FILE> )
	{	
        	chomp $line;
	        my @sid = $line =~ /\:(.*?)\:/;

        	foreach (@sid)
        	{
        	 $ORACLE_HOME = pop @sid;

       		}
	}
close (FILE);
print "Enterprise ORACLE_HOME variable has been set as: \n";
print "$ORACLE_HOME \n";

#--- patch compibility Checks

our $cmd_check_patch  = "$ORACLE_HOME/OPatch/opatch prereq CheckConflictAgainstOHWithDetail -ph ./ > $APOO/logs/pre-patch_check.log";
system ($cmd_check_patch);
our $cmd_check = "grep passed $APOO/logs/pre-patch_check.log  | wc -l";
our $proceed_patch = `$cmd_check`;

	if ($proceed_patch == 0 )
	{
        	print "Pre-check failed. Program will be terminated \n";
        	print "View logs to check failure reason: \n";
        	print "$APOO/logs/pre-patch_check.log \n";
        	exit;
	}
	else
	{
		print "Shutting down Enterprise databases \n";
		#-----------------------------------------------------------	
		#Shutdown all Enterprise database including the listener   |
		#-----------------------------------------------------------
	
		$ENV{ORACLE_OWNER}="oracle";
		$ENV{ORACLE_HOME}="$ORACLE_HOME";
	
		system ($CMD_SHUTDOWN_EE);
		sleep (5);

		#---Apply Patch 
		print "Applying patch on Enterprise Oracle Home\n";
                my $CMD_PATCH1 = "$ORACLE_HOME/OPatch/opatch apply -silent -ocmrf $APOO/config/apo.rsp";
		print "$CMD_PATCH1 \n";
		system ($CMD_PATCH1);

		#--Postpatch Standby Database on Enterprise
				
		#--Postpatch Primary Database on Enterprise
		print "Starting Enterprise Standby Databases on Mount mode......  \r\n";
		my $CMD_STARTUPMOUNT_EE = "$APOO/stop_and_start/dbstart_mounted_standby_ee $ORACLE_HOME";
		system ($CMD_STARTUPMOUNT_EE);

		open (FILE, "$CONF_DIR/standby_ee.conf") || die "Cannot open your file";

		while (my $line = <FILE> )
		{
		chomp $line;
		my @sid = $line =~ /^(.*?):\//;

		foreach  (@sid)
			{        
                                 print "Applying logs on:\n";
				 print "$_ \r\n";
				 my $apply_logs = "sqlplus / as sysdba \@$SQL_SCRIPTS/apply_log.sql";
				
				 $ENV{ORACLE_SID}="$_";
				 $ENV{ORACLE_HOME}="$ORACLE_HOME";
				 sleep (5); 
				 system ($apply_logs);
				
				 

			}
		}	
		close (FILE);
	
		
		




	
		#--Postpatch Primary Database on Enterprise
		print "Applying datapatch on each Primary Databases on Enterprise Edition  \r\n";
		system ($CMD_STARTUP_PE);

		open (FILE, "/oracle/scripts/APOo/config/primary_ee.conf") || die "Cannot open your file";
		while (my $line = <FILE> )
		{
		 chomp $line;
		  my @sid = $line =~ /^(.*?):\//;

		 foreach  (@sid)
 		{
       		 print "$_ \r\n";
       		 my $cmd_setsid = "export ORACLE_SID=$_";
       		 my $cmdpatch = "$ORACLE_HOME/OPatch/datapatch -verbose -skip_upgrade_check";


       		 print "$cmd_setsid\r\n";
       		 print "$cmdpatch\r\n";

       		 $ENV{ORACLE_SID}="$_";
       		 $ENV{ORACLE_HOME}="$ORACLE_HOME";
       		 sleep (10);
        	 system($cmdpatch);

		

		 }
		}
		close (FILE);



	}


}

#----------------------------------------------
#Patch Standard databases if there is any     |------------------------------------------------------------------------------------------------
#----------------------------------------------

#---Check if se config has some databases in it
if ($COUNT_SE_INSTANCES > 0 )
{
        open (FILE, "$CONF_DIR/se.conf") || die "Cannot open your file";

        while (my $line = <FILE> )
        {
                chomp $line;
                my @sid = $line =~ /\:(.*?)\:/;

                foreach (@sid)
                {
                 $ORACLE_HOME = pop @sid;

                }
        }
	close (FILE);
print "Standard ORACLE_HOME variable has been set as: \n";
print "$ORACLE_HOME \n";

#--- patch compibility Checks

our $cmd_check_patch  = "$ORACLE_HOME/OPatch/opatch prereq CheckConflictAgainstOHWithDetail -ph ./ > $APOO/logs/pre-patch_check.log";
system ($cmd_check_patch);
our $cmd_check = "grep passed $APOO/logs/pre-patch_check.log  | wc -l";
our $proceed_patch = `$cmd_check`;

	if ($proceed_patch == 0 )
	{
        	print "Pre-check failed. Program will be terminated \n";
        	print "View logs to check failure reason: \n";
        	print "$APOO/logs/pre-patch_check.log \n";
        	exit;
	}
	else
	
	{
		 print "All patching codes goes here \n";
		 print "shutting down Standard Databases \n";
		 #-----------------------------------------------------------
		 #Shutdown all Standard database including the listener     |
		 #-----------------------------------------------------------

		 open (FILE, "$CONF_DIR/se.conf") || die "Cannot open your file";

		 while (my $line = <FILE> )
	 	 {
			chomp $line;
			my @sid = $line =~ /\:(.*?)\:/;

			foreach (@sid)
			{
		 	$ORACLE_HOME = pop @sid;

			}
		 }
		 close (FILE);

			

		 $ENV{ORACLE_OWNER}="oracle";
	 	 $ENV{ORACLE_HOME}="$ORACLE_HOME";
		

		print "current ORACLE_HOME is $ORACLE_HOME \n";
		system ($CMD_SHUTDOWN_SE);
		sleep (5);	

		 #---Apply Patch
		 print "Applying patch on Standard Oracle Home\n";
		 my $CMD_PATCH = "$ORACLE_HOME/OPatch/opatch apply -silent -ocmrf $APOO/config/apo.rsp";
		 print "$CMD_PATCH \n";
		 system ($CMD_PATCH);

		 #--Post Patch
		 print "Starting Standby Databases on Mount mode......  \r\n";
		 my $CMD_STARTUPMOUNT_SS = "$APOO/stop_and_start/dbstart_mounted_standby $ORACLE_HOME";
		 system ($CMD_STARTUPMOUNT_SS);

		 open (FILE, "$CONF_DIR/standby_se.conf") || die "Cannot open your file";

		 while (my $line = <FILE> )
		 {
		        chomp $line;
		        my @sid = $line =~ /^(.*?):\//;

		        foreach  (@sid)
	        	{
        	 		 print "$_ \r\n";

       			}
		 }
		 close (FILE);	

		print "Applying datapatch on each Primary Databases on Standard Edition  \r\n";
	        system ($CMD_STARTUP_PS);

		open (FILE, "/oracle/scripts/APOo/config/primary_se.conf") || die "Cannot open your file";
		while (my $line = <FILE> )
		{
       		 chomp $line;
        	 my @sid = $line =~ /^(.*?):\//;

           	 foreach  (@sid)
       	         {
          		print "$_ \r\n";
          		my $cmd_setsid = "export ORACLE_SID=$_";
          		my $cmdpatch = "$ORACLE_HOME/OPatch/datapatch -verbose -skip_upgrade_check";


         		print "$cmd_setsid\r\n";
         		print "$cmdpatch\r\n";

          		$ENV{ORACLE_SID}="$_";
         		$ENV{ORACLE_HOME}="$ORACLE_HOME";
          		sleep (10);
          		system($cmdpatch);

 	       }
	     }
             close (FILE);


	     print "Patching Complete \r\n";
		


	}



}


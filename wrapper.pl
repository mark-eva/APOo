#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use File::Copy;
use Env;
use Term::ANSIColor;
use List::MoreUtils qw(uniq);
use Time::Piece; 
use Date::Manip;

our $ORACLE_HOME;
our $ORACLE_SID;

our $patch_base_dir = "/oracle/scripts/APOo/";
our $patcher_cmd = "/oracle/scripts/APOo/patcher.pl";
our $patch_dir = "/oracle/scripts/APOo/patch_downloader/";
our $psu_latest_patch_dir = "/oracle/scripts/APOo/patch_downloader/PSU";
our $ojvm_latest_patch_dir = "/oracle/scripts/APOo/patch_downloader/OJVM";


#-- MOS credentials
our $mos_user = "mark.eva\@fivium.co.uk";
our $mos_pass = "Mandems123";


#-- Refresh the master patch note document

our $dl_master_patchnote = "$patch_dir/master_patch_download.sh > /dev/null 2>&1";
our $cmd_del_cookies = "rm $patch_dir/cookies > /dev/null 2>&1";
our $cmd_del_patch_note = "rm $patch_dir/patch_master_note.txt > /dev/null 2>&1";

`$cmd_del_cookies`;
`$cmd_del_patch_note`;
system ($dl_master_patchnote);

#-- Delete existing patch folders
`rm -rf $psu_latest_patch_dir/* > /dev/null 2>&1`;
`rm -rf $ojvm_latest_patch_dir/* > /dev/null 2>&1`;

#-- Delete commented lines  as well as  white spaceson /etc/oratab
our $oratab_conf = "/etc/oratab";
our $oratab_cleaner_cmd = "sudo sed -i \'/^\\s*[@#]/ d\' $oratab_conf";
chomp $oratab_cleaner_cmd;
`$oratab_cleaner_cmd`;

our $clean_white_space = "sudo sed -i  \'/^\\s*\$/d\' /etc/oratab";
chomp $clean_white_space;
`$clean_white_space`;



#----------------------------------------------------------------------------------
#Find out current patch for each all $ORACLE_HOME
#----------------------------------------------------------------------------------
our $latest_psu_patch_id;
our $latest_ojvm_patch_id;


#--find out  distinct ORACLE_HOMES in the box

our $data =  `cat /etc/oratab`;
our @homes = ( $data =~ /:(.*)\:/g);
our @distinct_homes = uniq @homes;

$ORACLE_HOME = $distinct_homes [0];
chomp $ORACLE_HOME;
print "setting environment variable for ORACLE_HOME:  $ORACLE_HOME \n";

our $unix_path_variable = $ENV{PATH} .= ":$ORACLE_HOME/bin";

print "setting environment variable for PATH:  $unix_path_variable \n";



#print map { "$_\n" } @distinct_homes;

#--check the number of different ORACLE_HOMES in the box
my $size = @distinct_homes;

#--check current PSU and OJVM patchers for each ORACLE_HOMES found
our $psu_patch_number;
our $ojvm_patch_number;

our $psu_details;
our $psu_release_date;

our $ojvm_details;
our $ojvm_release_date;


if ($size ==1)
{

foreach (@distinct_homes)
  {
    print color ("red"), "Running Opatch checker for ORACLE_HOME\n", color("reset") ;
    print "------------------------------------------\n";
    print color ("yellow"),  "$_ \r\n" , color("reset");
    $ENV{ORACLE_HOME}=$ORACLE_HOME;

    
    #--get psu and java full details
     my $psu_patch_checker = "$ORACLE_HOME/OPatch/opatch lsinventory | grep -i -A 2 -B 2 -m 1 update";
     my $ojvm_patch_checker = "$ORACLE_HOME/OPatch/opatch lsinventory | grep -i -A 2 -B 2 javavm";

     $psu_details = `$psu_patch_checker`;
    

    #--get psu_patch_number 
     my $psu_first_line_cmd  = "$ORACLE_HOME/OPatch/opatch lsinventory | grep -i -A 2 -B 2 -m 1 update | grep -m 1 Patch";
     my $get_first_line_string = `$psu_first_line_cmd`;
 
     $psu_patch_number = substr($get_first_line_string, 7,12);
     print  color ("green"),"PSU patch number is:" , color("reset") . $psu_patch_number;
     print "\n";

    #--get psu_patch_release_date
     my $psu_third_line_cmd  = "$ORACLE_HOME/OPatch/opatch lsinventory | grep -i -A 2 -B 2 -m 1 update | grep -m 3 Update";
     my $get_third_line_string_psu = `$psu_third_line_cmd`;

     $psu_release_date = substr($get_third_line_string_psu, 58, 6);
     print color ("green"),"PSU patch release date is:", color("reset") . $psu_release_date ;
     print "\n";
     print "------------------------------------------\n";
    
       
    #--get java_patch_number
     my $ojvm_first_line_cmd  = "$ORACLE_HOME/OPatch/opatch lsinventory | grep -i -A 2 -B 2 -m 1 javavm | grep -m 1 Patch";
     my $get_first_line_string_ojvm = `$ojvm_first_line_cmd`;
    
     $ojvm_patch_number = substr($get_first_line_string_ojvm, 7,12);
     print color ("green"),"OJVM patch number is:", color("reset") . $ojvm_patch_number ;
     print "\n";
   
    #--get patch release date
     my $ojvm_third_line_cmd  = "$ORACLE_HOME/OPatch/opatch lsinventory | grep -i -A 2 -B 2 javavm | grep -m 3 Component";
     my $get_third_line_string_ojvm = `$ojvm_third_line_cmd`;

     $ojvm_release_date = substr($get_third_line_string_ojvm, 43, 6);
     
     print color ("green"),"OJVM patch release date is:", color("reset") . $ojvm_release_date;  
     print "\n"; 
     $ojvm_details = `$ojvm_patch_checker`;
  }
}

#----------------------------------------------------------------------------------
#Check if the current patches are older than 3 months
#----------------------------------------------------------------------------------


our $current_date_cmd = `date +"%y%m%d"`;
our $three_months_ago_cmd= "date +\"%y%m%d\" --date=\"93 day ago\"";
our $three_months_ago_date=`$three_months_ago_cmd`;

#-- psu release date and current date to seconds from epoch

our $epoch_psu_release_date  = UnixDate( ParseDate($psu_release_date), "%s" ); 
our $epoch_three_months_ago_date  = UnixDate( ParseDate($three_months_ago_date), "%s" );
our $epoch_current_date  = UnixDate( ParseDate($current_date_cmd), "%s" ); 


#-- ojvm release date and current date to seconds from epoch
my $epoch_ojvm_release_date  = UnixDate( ParseDate($ojvm_release_date), "%s" ); 

#-- check current psu patch implemented is older than 3 months

#-- Download and install the latest OPatch 


$ENV{mosUser} = "$mos_user";
$ENV{mosPass} = "$mos_pass";

our $dir_opatch = "/oracle/scripts/APOo/patch_downloader/OPatch";
our $cmd_dl_latest_OPatch = "/oracle/scripts/APOo/patch_downloader/getMOSPatch.sh patch=6880880 regexp=\".*122010.*\"";

chdir ($dir_opatch);
our $cmd_del_old_Opatch = "rm p* > /dev/null 2>&1";
`$cmd_del_old_Opatch`;

system ($cmd_dl_latest_OPatch);

chdir ($ORACLE_HOME);
our $cmd_del_current_opatch = "rm -rf OPatch/";
`$cmd_del_current_opatch`;


chdir ($dir_opatch);
print  color ("blue"), "Installating the latest OPatch \n" , color("reset");
our $cmd_unzip_new_opatch = "unzip p6880880_122010_Linux-x86-64.zip -d $ORACLE_HOME/";


system ($cmd_unzip_new_opatch);



if ($epoch_psu_release_date <= $epoch_three_months_ago_date)
{
   print "------------------------------------------\n";
   print  color ("red"), "Current PSU patch is older than the latest release. Downloading the latest one \n" , color("reset");
  

   #-- parse the latest master patch document
   my $sed =  "sed -n -e 's/^.*\\(patchId=\\)/\\1/p'";
   chomp $sed;

   my $latest_id_psu  = "cat $patch_dir/patch_master_note.txt |grep -i  -B 3 \"<td>Database PSU 12.1.0.2\" | $sed";
   my  $latest_patch_id_psu = `$latest_id_psu`;
   sleep (1);
   $latest_psu_patch_id = substr($latest_patch_id_psu, 8, 8);
   print color ("green"), "Latest psu patch number is:", color("reset") . $latest_psu_patch_id;


   #-- set up the environment variables required for the patch download
   $ENV{mosUser} = "$mos_user";
   $ENV{mosPass} = "$mos_pass";

   #-- invoke the patch downloader passing the latest PSU patch number
   chdir ($psu_latest_patch_dir);
   
   my $dl_psu_patch = "$patch_dir/getMOSPatch.sh patch=$latest_psu_patch_id";
   system ($dl_psu_patch);

   #-- unzip the newly downloaded patch
   my $zipname = `ls  | grep -i p$latest_psu_patch_id`;
   print "Name of the new PSU patch: $zipname \n";
   my $unzip_psu_patch_cmd = `unzip $zipname`;

   #-- apply the latest patch on all Oracle instance within the box
   chdir ($latest_psu_patch_id);
   system ($patcher_cmd);
   
      
   
   print "\n";

}
else
{
   print "------------------------------------------\n";
   print color ("green"), "Current PSU patch is the latest one. Nothing to do here my son!\n"  , color("reset");

}

#-- check current ojvm patch implemented is older than 3 months


if ($epoch_ojvm_release_date <= $epoch_three_months_ago_date)
{
   print "------------------------------------------\n";
   print  color ("red"), "Current OJVM patch is older than the latest release. Downloading the latest one \n"  , color("reset");


   #-- parse the latest master patch document
   my $sed =  "sed -n -e 's/^.*\\(patchId=\\)/\\1/p'";
   chomp $sed;
  
   my $latest_id  = "cat $patch_dir/patch_master_note.txt |grep -i  -B 3 \"JavaVM Component Database PSU 12.1.0.2\" | grep -i unix | $sed";  
   my $latest_patch_id = `$latest_id`;
   $latest_ojvm_patch_id = substr($latest_patch_id, 8, 8);
   print color ("green"), "Latest ojvm patch number is:", color("reset") . $latest_ojvm_patch_id;


   #-- set up the environment variables required for the patch download
   $ENV{mosUser} = "$mos_user";
   $ENV{mosPass} = "$mos_pass";

   #-- invoke the patch downloader passing the latest PSU patch number
   chdir ($ojvm_latest_patch_dir);
   
   my $dl_ojvm_patch = "$patch_dir/getMOSPatch.sh patch=$latest_ojvm_patch_id";
   system ($dl_ojvm_patch);

   #-- unzip the newly downloaded patch
   my $zipname = `ls  | grep -i p$latest_ojvm_patch_id`;
   print "Name of the new OJVM patch: $zipname \n";
   my $unzip_psu_patch_cmd = `unzip $zipname`;

   #-- apply the latest patch on all Oracle instance within the box
   chdir ($latest_ojvm_patch_id);
   system ($patcher_cmd);

  





   
   print "\n"; 
     


}
else
{
   print "------------------------------------------\n";
   print color ("green"), "Current OJVM patch is the latest one. Nothing to do here my son!\n" , color("reset");
 

}























































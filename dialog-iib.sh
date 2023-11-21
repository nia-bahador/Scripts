#!/bin/bash

#	clearing screen
clear;

#########################################
#	write by BaHaDoR Pajouhesh NiA	#
#########################################

#	test for running mqsilist
node_Test=`mqsilist 2>&1`
if [ $? -ne 0 ]
then
	dialog --msgbox 'IIB is not runninig' 0 0 
	exit 1;
fi

#	show mqsilist
node_List=(`grep -oP "(?<=Integration node ').*?(?=')" <<< "${node_Test}"`)
for index in "${!node_List[@]}"
do
	node_QM=`grep "${node_List[index]}" <<< "${node_Test}" | grep -oP "(?<=on queue manager ').*?(?=')"`
	node_Status=`grep "${node_List[index]}" <<< "${node_Test}" | grep -oP '(?=is ).*'`
	menu_List+=("${node_List[index]}" "on queue manager $node_QM $node_Status")
done
menu_List+=("SSH" "")
node_Choice=`dialog --menu 'Integeration Nodes' 0 0 0 "${menu_List[@]}" 3>&2 2>&1 1>&3`
if [ $? -eq 1 ]
then
	exit 1 && logout
fi
if [ "$node_Choice" == "SSH" ]
then
	reset
	/bin/bash
	exit 0;
fi

#	show Integration node options
options_List=("Start" "" "Stop" "" "Restart" "")
choice=`dialog --menu "Change $node_Choice" 0 0 0 "${options_List[@]}" 3>&2 2>&1 1>&3`
if [ $? -eq 1 ]
then
	exit 1 && logout
fi
if [ "$choice" == "Start" ]
then
	nohup strmqm "$node_QM" 2>&1 & disown 
	nohup mqsistart $node_Choice 2>&1 & disown
        exec_Time=0
        while true
        do
                echo "$exec_Time"
                ps_Status=`ps aux | grep mqsistart | wc -l`
                if [ $ps_Status -eq 1 ]
                then
                        break;
                fi
                exec_Time=$(($exec_Time + 1))
                sleep 1
        done | dialog --gauge "Please Wait!" 0 0 "$exec_Time"
elif [ "$choice" == "Stop" ]
then
	nohup mqsistop $node_Choice 2>&1 & disown
	exec_Time=0
	while true
	do
		echo "$exec_Time"
		ps_Status=`ps aux | grep mqsistop | wc -l`
		if [ $ps_Status -eq 1 ]
		then
			break;
		fi
		exec_Time=$(($exec_Time + 1))
		sleep 1
	done | dialog --gauge "Please Wait!" 0 0 "$exec_Time" 
elif [ "$choice" == "Restart" ]
then
	nohup mqsistop $node_Choice 2>&1 & disown
        nohup mqsistart $node_Choice 2>&1 & disown
        exec_Time=0
        while true
        do
                echo "$exec_Time"
                ps_Status=`ps aux | grep mqsistop | wc -l`
                if [ $ps_Status -eq 1 ]
                then
                        break;
                fi
                exec_Time=$(($exec_Time + 1))
                sleep 1
        done | dialog --gauge "Please Wait!" 0 0 "$exec_Time"
fi

#	show command output in dialog
out_Msg=`cat nohup.out`
dialog_Msg=`grep -oP '(?<=: ).*' <<< "$out_Msg"`
dialog --msgbox "$dialog_Msg" 0 0
rm -f nohup.out

#	unset variable to free memory
unset out_Msg exec_Time ps_Status dialog_Msg
unset node_Test node_List
unset index node_Status menu_List
unset node_Choice choice 

#	clear screen
clear;

exit 0;


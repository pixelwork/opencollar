//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//       _   ___     __            __  ___  _                               //
//      | | / (_)___/ /___ _____ _/ / / _ \(_)__ ___ ________ ________      //
//      | |/ / / __/ __/ // / _ `/ / / // / (_-</ _ `/ __/ _ `/ __/ -_)     //
//      |___/_/_/  \__/\_,_/\_,_/_/ /____/_/___/\_, /_/  \_,_/\__/\__/      //
//                                             /___/                        //
//                                                                          //
//                                        _                                 //
//                                        \`*-.                             //
//                                         )  _`-.                          //
//                                        .  : `. .                         //
//                                        : _   '  \                        //
//                                        ; *` _.   `*-._                   //
//                                        `-.-'          `-.                //
//                                          ;       `       `.              //
//                                          :.       .        \             //
//                                          . \  .   :   .-'   .            //
//                                          '  `+.;  ;  '      :            //
//                                          :  '  |    ;       ;-.          //
//                                          ; '   : :`-:     _.`* ;         //
//           Spy - 170916.2              .*' /  .*' ; .*`- +'  `*'          //
//                                       `*-*   `*-*  `*-*'                 //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2014 - 2017 littlemousy, Wendy Starfall, Garvin Twine     //
// ------------------------------------------------------------------------ //
//  This script is free software: you can redistribute it and/or modify     //
//  it under the terms of the GNU General Public License as published       //
//  by the Free Software Foundation, version 2.                             //
//                                                                          //
//  This script is distributed in the hope that it will be useful,          //
//  but WITHOUT ANY WARRANTY; without even the implied warranty of          //
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the            //
//  GNU General Public License for more details.                            //
//                                                                          //
//  You should have received a copy of the GNU General Public License       //
//  along with this script; if not, see www.gnu.org/licenses/gpl-2.0        //
// ------------------------------------------------------------------------ //
//                          www.virtualdisgrace.com                         //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

//string g_sAppVersion = "4.5";
string g_sBuildVersion = "170916.2";

integer g_iHaveConsent;

string g_sChatBuffer;  //if this has anything in it at end of interval, then tell owners (if listen enabled)

integer g_iListener;

integer g_iTraceEnabled=FALSE;
integer g_iListenEnabled=FALSE;
integer g_iNotifyEnabled=FALSE;
integer g_iLoginEnabled;
integer g_iTouchEnabled;
integer g_iSitEnabled;

//MESSAGE MAP
//integer CMD_ZERO                  = 0;
integer CMD_OWNER                   = 500;
//integer CMD_TRUSTED               = 501;
integer CMD_GROUP                 = 502;
integer CMD_WEARER                  = 503;
integer CMD_EVERYONE              = 504;
//integer CMD_RLV_RELAY             = 507;
//integer CMD_SAFEWORD              = 510; 
//integer CMD_RELAY_SAFEWORD        = 511;
//integer CMD_BLOCKED               = 520;

integer NOTIFY = 1002;
//integer NOTIFY_OWNERS = 1003;
//integer SAY = 1004;
integer REBOOT = -1000;
integer LINK_DIALOG = 3;
//integer LINK_RLV = 4;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;
integer LM_SETTING_SAVE = 2000;
integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
//integer LM_SETTING_EMPTY = 2004;

integer MENUNAME_REQUEST    = 3000;
integer MENUNAME_RESPONSE   = 3001;
integer MENUNAME_REMOVE     = 3003;
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string g_sSettingToken = "spy_";
string g_sGlobalToken = "global_";

string UPMENU = "BACK";

list g_lOwners;
list g_lTempOwners;
string g_sWearerName;
key g_kWearer;
string g_sDeviceName;

list g_lMenuIDs;
integer g_iMenuStride = 3;
integer g_iSerial;
list g_lToucher;
integer g_iSits;
integer g_iReportCount;
list g_lSitting;

/*
integer g_iProfiled;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to 
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+") :\n" + sStr);
}
*/

string location() {
    vector vPos=llGetPos();
    string sRegionName=llGetRegionName();
    return "http://maps.secondlife.com/secondlife/"+llEscapeURL(sRegionName)+"/"+(string)llFloor(vPos.x)+"/"+(string)llFloor(vPos.y)+"/"+(string)llFloor(vPos.z);
}

string GetTime(integer iSeconds) {
    integer iMins = iSeconds/60;
    integer iHours = iMins/60;
    iMins = iMins % 60;
    string sMins = (string)iMins;
    if (iMins < 10) sMins = "0"+sMins;
    return (string)iHours+":"+sMins+" SLT";
}

DoReports(string sChatLine, integer sendNow, integer fromTimer) {
    if (!(g_iSitEnabled||g_iTouchEnabled||g_iTraceEnabled||g_iListenEnabled)) return;
    
    integer iMessageLimit=500;
    //store chat
    if (g_iListenEnabled && sChatLine != "") g_sChatBuffer += sChatLine+"\n";

    string sLocation;
    if (g_iTraceEnabled) {
        sLocation += " "+g_sWearerName+" is at "+location();
    }
    string sTouchNotify;
    string sTouchNotifyCounts;
    if (g_iTouchEnabled) {
        integer i = llGetListLength(g_lToucher);
        while (i) {
            string sAction = "opened ";
            if (llList2Integer(g_lToucher,1) == CMD_EVERYONE)  sAction = "tried to open ";
            integer iCount = llList2Integer(g_lToucher,2);
            if (iCount) sAction += g_sWearerName+"'s Collar Main Menu "+(string)(iCount+1)+" times starting at ";
            else sAction += g_sWearerName+"'s Collar Main Menu at ";
            string sToucher = llKey2Name(llList2Key(g_lToucher,0));
            sTouchNotify += sToucher+" has "+sAction+GetTime(llList2Integer(g_lToucher,3))+" in "+llList2String(g_lToucher,4)+".\n";
            g_lToucher = llDeleteSubList(g_lToucher,0,4);
            i = i-5;
        } 
    }
    string sSitNotify;
    if (g_iSitEnabled) {
        integer i = llGetListLength(g_lSitting);
        while (i) {
            string sAction = " sat down ";
            if (!llList2Integer(g_lSitting,0)) sAction = " stood up ";
            sSitNotify += g_sWearerName+sAction+"at "+GetTime(llList2Integer(g_lSitting,1))+" in "+llList2String(g_lSitting,2)+".\n";
            g_lSitting = llDeleteSubList(g_lSitting,0,2);
            i = i-3;
        }
    }
    string sHeader="["+(string)g_iSerial + "]"+sLocation+"\n";
    integer iMessageLength=llStringLength(sHeader)+llStringLength(g_sChatBuffer)+llStringLength(sTouchNotify)+llStringLength(sSitNotify);
    if (iMessageLength > iMessageLimit || ((sSitNotify!="" || sTouchNotify!="" || g_sChatBuffer!="") && fromTimer) || sendNow) { //if we have too much chat, or the timer fired and we have something to report, or we got a sendnow
        //Debug("Sending report");
        while (iMessageLength > iMessageLimit){
            g_sChatBuffer=sHeader+sTouchNotify+sSitNotify+g_sChatBuffer;
            iMessageLength=llStringLength(g_sChatBuffer);
            //Debug("message length:"+(string)iMessageLength);
            //Debug("header length:"+(string)llStringLength(sHeader));
            integer index=iMessageLimit;
            while (llGetSubString(g_sChatBuffer,index,index) != "\n"){
                index--;
            }
            //Debug("Found a return at "+(string) index);
            if (index <= llStringLength(sHeader)){
                index=iMessageLimit;
                while (llGetSubString(g_sChatBuffer,index,index) != " "){
                    index--;
                }
                if (index <= llStringLength(sHeader)) {
                    index=iMessageLimit;
                    //Debug("Found no breaks, breaking at "+(string) index);
                //} else {
                    //Debug("Found a space at "+(string) index);
                }
            }
            string sMessageToSend=llGetSubString(g_sChatBuffer,0,index);
            //Debug("send length:"+(string)llStringLength(sMessageToSend));
            NotifyOwners(sMessageToSend);
            g_iSerial++;
            sHeader="["+(string)g_iSerial + "]\n";
            
            g_sChatBuffer=llGetSubString(g_sChatBuffer,index+1,-1);
            iMessageLength=llStringLength(sHeader)+llStringLength(g_sChatBuffer);
            //Debug("remaining:"+(string)iMessageLength);
        }
        if (sendNow || fromTimer){
            sHeader="["+(string)g_iSerial + "]"+sLocation+"\n";
            if (!~llSubStringIndex(g_sChatBuffer,sTouchNotify)) g_sChatBuffer += sTouchNotify;
            if (!~llSubStringIndex(g_sChatBuffer,sSitNotify)) g_sChatBuffer += sSitNotify;
            if (g_sChatBuffer != "" || sLocation != "") {
                NotifyOwners(sHeader+g_sChatBuffer);
                g_iSerial++;
                g_sChatBuffer="";
            }
            //Debug("Emptied buffer");
        }
        //make a warning for the user
        if (g_iNotifyEnabled){
            string sActivityWarning="\n\nThe Spy app is reporting your ";
            if (g_iTraceEnabled) sActivityWarning += "location, ";
            if (g_iListenEnabled)  sActivityWarning += "chat activity, ";
            if (g_iTouchEnabled) sActivityWarning += "collar touchers, ";
            if (g_iSitEnabled) sActivityWarning += "when you sit or stand up, ";
            if (g_iLoginEnabled) sActivityWarning += "your logins, ";
            sActivityWarning += "to your primary owners.\n";
            Notify(g_kWearer,sActivityWarning,FALSE);
        }        
    } else  return;
}

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);
    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) 
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else 
        g_lMenuIDs += [kID, kMenuID, sName];
} 

DialogSpy(key kID, integer iAuth) {
    string sPrompt="\n[http://www.opencollar.at/spy.html Virtual Disgrace™ Spy]";
    list lButtons ;
    if(g_iTraceEnabled) lButtons += ["☒ Trace"];
    else lButtons += ["☐ Trace"];
    if (g_iListenEnabled) lButtons += ["☒ Listen"];
    else lButtons += ["☐ Listen"];
    if (g_iTouchEnabled) lButtons += ["☒ Touch"];
    else lButtons += ["☐ Touch"];
    if (g_iLoginEnabled) lButtons += ["☒ Login"];
    else lButtons += ["☐ Login"];
    if (g_iSitEnabled) lButtons += ["☒ Sit"];
    else lButtons += ["☐ Sit"];
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth,"spy");
}

ConsentReply(key kID) {
    string sPrompt;
    string sMenuName = "ConsentMenu";
    if (kID != g_kWearer) {
        sMenuName += (string)kID;
        sPrompt = "\nsecondlife:///app/agent/"+(string)kID+"/inspect wants to use your spy app.\n";
        llDialog(kID,"\nSpy is not functional yet. secondlife:///app/agent/"+(string)g_kWearer+"/inspect has to consent to its use at least once before the app can start. Sending them a confirmation dialog...",["OK"],-12345);
    }
    sPrompt += "\nBecause of its privacy sensitive nature, this app requires you to consent to its use at least once.\n\nIf you choose to consent, please proceed with [Yes].\n\nwww.opencollar.at/spy";
    Dialog(g_kWearer,sPrompt,["Yes","No"],["Cancel"],0,CMD_WEARER,sMenuName);

}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer){
    string sObjectName = llGetObjectName();
    if (g_sDeviceName != sObjectName) llSetObjectName(g_sDeviceName);
    if (kID == g_kWearer) {
        while (llStringLength(sMsg)>1000){
            string sSendString=llGetSubString(sMsg,0,1000);
            llOwnerSay(sSendString);
            sMsg=llGetSubString(sMsg,1001,-1);
        }
        llOwnerSay(sMsg);
    } else {
        //Debug("Notifying "+(string)kID);
        if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
        else if (kID) llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
    llSetObjectName(sObjectName);
}

NotifyOwners(string sMsg) {
    integer n;
    integer iStop = llGetListLength(g_lOwners+g_lTempOwners);
    if (iStop) {
        for (n = 0; n < iStop; ++n) {
        //while (n < iStop) {
            key kAv = (key)llList2String(g_lOwners+g_lTempOwners, n);
            //we don't want to bother the owner if he/she is right there, so check distance
            vector vOwnerPos = (vector)llList2String(llGetObjectDetails(kAv, [OBJECT_POS]), 0);
            if (vOwnerPos == ZERO_VECTOR || llVecDist(vOwnerPos, llGetPos()) > 20.0) {//vOwnerPos will be ZERO_VECTOR if not in sim
                //Debug("notifying " + (string)kAv);
                if (kAv) Notify(kAv, sMsg,FALSE);
            }
        }
    }
}

UserCommand (integer iAuth, string sStr, key kID, integer remenu) {
    sStr = llToLower(sStr);
    if ("runaway" == sStr && kID == g_kWearer) {
        g_iListenEnabled    = FALSE;
        g_iLoginEnabled     = FALSE;
        g_iTouchEnabled     = FALSE;
        g_iSitEnabled       = FALSE;
        g_iTraceEnabled     = FALSE;
        g_iNotifyEnabled    = FALSE;
        llListenRemove(g_iListener);
        g_iListener = 0;
        g_lOwners = [];
        g_lTempOwners = [];
        llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"all", "");
        llMessageLinked(LINK_DIALOG, NOTIFY,"0"+"Spy settings reset.", g_kWearer);
        return;
    } else if (sStr == "spy" || sStr == "menu spy") {
        if (!g_iHaveConsent) ConsentReply(kID);
        else DialogSpy(kID, iAuth);
    } else if (sStr ==  "rm spy") {
        if (iAuth == CMD_OWNER || kID == g_kWearer) 
            Dialog(kID, "\nDo you really want to uninstall the Spy App?", ["Yes","No","Cancel"], [], 0, iAuth,"rmspy");
        else Notify(kID,"Access denied.",FALSE);
    }
    if (sStr == "☐ trace" || sStr == "trace on") {
        if (iAuth == CMD_OWNER) {
            if (!g_iHaveConsent) ConsentReply(kID);
            else if (!g_iTraceEnabled) {
                g_iTraceEnabled=TRUE;
                Notify(kID,"\n\nTrace enabled.\n",TRUE);
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"trace=1", "");
            }
        } else Notify(kID,"Access denied.",TRUE);
    } else if(sStr == "☒ trace" || sStr == "trace off") {
        if (iAuth == CMD_OWNER) {
            if (g_iTraceEnabled){
                g_iTraceEnabled=FALSE;
                Notify(kID,"\n\nTrace disabled.\n",TRUE);
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"trace", "");
            }
        } else Notify(kID,"Access denied.",TRUE);
    } else if(sStr == "☒ touch" || sStr == "touch off") {
        if (iAuth == CMD_OWNER) {
            if (g_iTouchEnabled){
                g_iTouchEnabled=FALSE;
                Notify(kID,"\n\nTouch disabled.\n",TRUE);
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"touch", "");
            }
        } else Notify(kID,"Access denied.",TRUE);
    } else if(sStr == "☐ touch" || sStr == "touch on") {
        if (iAuth == CMD_OWNER) {
            if (!g_iHaveConsent) ConsentReply(kID);
            else if (!g_iTouchEnabled){
                g_iTouchEnabled=TRUE;
                Notify(kID,"\n\nTouch enabled.\n",TRUE);
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"touch=1", "");
            }
        } else Notify(kID,"Access denied.",TRUE);
    } else if(sStr == "☒ sit" || sStr == "sit off") {
        if (iAuth == CMD_OWNER) {
            if (g_iSitEnabled){
                g_iSitEnabled=FALSE;
                Notify(kID,"\n\nSit notify disabled.\n",TRUE);
                llSetTimerEvent(300);
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"sit", "");
            }
        } else Notify(kID,"Access denied.",TRUE);
    } else if(sStr == "☐ sit" || sStr == "sit on") {
        if (iAuth == CMD_OWNER) {
            if (!g_iHaveConsent) ConsentReply(kID);
            else if (!g_iSitEnabled){
                g_iSitEnabled=TRUE;
                Notify(kID,"\n\nSit notify enabled.\n",TRUE);
                llSetTimerEvent(10);
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"sit=1", "");
            }
        } else Notify(kID,"Access denied.",TRUE);
    } else if(sStr == "☒ login" || sStr == "login off") {
        if (iAuth == CMD_OWNER) {
            if (g_iLoginEnabled){
                g_iLoginEnabled=FALSE;
                Notify(kID,"\n\nLogin notify disabled.\n",TRUE);
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"login", "");
            }
        } else Notify(kID,"Access denied.",TRUE);
    } else if(sStr == "☐ login" || sStr == "login on") {
        if (iAuth == CMD_OWNER) {
            if (!g_iHaveConsent) ConsentReply(kID);
            else if (!g_iLoginEnabled){
                g_iLoginEnabled=TRUE;
                Notify(kID,"\n\nLogin notify enabled.\n",TRUE);
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"login=1", "");
            }
        } else Notify(kID,"Access denied.",TRUE);
    } else if(sStr == "☐ listen" || sStr == "listen on") {
        if (iAuth == CMD_OWNER) {
            if (!g_iHaveConsent) ConsentReply(kID);
            else if (!g_iListenEnabled) {
                g_iListenEnabled=TRUE;
                Notify(kID,"\n\nChat Spy enabled.\n",TRUE);
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"listen=1", "");
                llListenRemove(g_iListener);
                g_iListener = llListen(0, "", g_kWearer, "");
            }
        } else Notify(kID,"Access denied.",TRUE);
    } else if(sStr == "☒ listen" || sStr == "listen off") {
        if (iAuth == CMD_OWNER) {
            if (g_iListenEnabled) {
                g_iListenEnabled=FALSE;
                Notify(kID,"\n\nChat Spy disabled.\n",TRUE);
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"listen", "");
                llListenRemove(g_iListener);
                g_iListener = 0;
            }
        } else Notify(kID,"Access denied.",TRUE);
    } else if (sStr == "spynotify on") {
        if (kID == g_kWearer) {
            if (!g_iNotifyEnabled) {
                g_iNotifyEnabled = TRUE;
                Notify(kID,"\n\nSpy notifications enabled.\n",TRUE);
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"notify=1", "");
            }
        } else Notify(kID,"\n\nOnly the wearer may enable spy notifications.\n",TRUE);
    } else if (sStr == "spynotify off") {
        if (kID == g_kWearer) {
            if (g_iNotifyEnabled){
                g_iNotifyEnabled = FALSE;
                Notify(kID,"\n\nSpy notifications disabled.\n",TRUE);
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"notify", "");
            }
        } else Notify(kID,"\n\nOnly the wearer may enable spy notifications.\n",TRUE);
    }
    if (remenu) DialogSpy(kID,iAuth);
}

default {
    state_entry() {
        //llSetMemoryLimit(32768);  //2015-05-06 (6622 bytes free)
        if (llGetInventoryType("vd_installer") == INVENTORY_SCRIPT) return;
        g_kWearer = llGetOwner();
        g_sDeviceName = llGetObjectName();
        g_sWearerName = llKey2Name(g_kWearer);
        g_lOwners = [g_kWearer];  // initially self-owned until we hear a db message otherwise
        llSetTimerEvent(300);
        if ((llGetInventoryPermMask(llGetScriptName(),MASK_OWNER) & PERM_COPY) == PERM_COPY)
            llListen(-287549127,"","","vd_app version?");
        ConsentReply(g_kWearer);
        //Debug("Starting");
    }

    listen(integer iChannel, string sName, key kID, string sMessage) {
        if (kID == g_kWearer && iChannel == 0) {
            //process emotes, replace with sub name
            if(llGetSubString(sMessage, 0, 3) == "/me ") sMessage = g_sWearerName + llGetSubString(sMessage, 3, -1);
            else sMessage = g_sWearerName+": " + sMessage;
            DoReports(sMessage,FALSE,FALSE);
        } else if (iChannel == -287549127)
            llRegionSayTo(kID,iChannel,"spy:"+g_sBuildVersion);
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (g_iTouchEnabled) {
            if ((iNum == CMD_GROUP || iNum == CMD_EVERYONE) && sStr == "menu") {
                integer index = llListFindList(g_lToucher,[kID]);
                if(~index)
                    g_lToucher = llListReplaceList(g_lToucher,[llList2Integer(g_lToucher,index+2)+1],index+2,index+2);
                else g_lToucher += [kID,iNum,0,llGetWallclock(),location()];
            }
        }
        if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID, FALSE);
        else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (llSubStringIndex(sToken, g_sSettingToken+"")==0) { //spy data
                if (!g_iHaveConsent) return; //we dont load nothing without consent!
                if (sToken == g_sSettingToken+"trace") {
                    if (!g_iTraceEnabled) {
                        g_iTraceEnabled=TRUE;
                        Notify(g_kWearer,"\n\nTrace enabled.\n",FALSE);
                    }
                } else if (sToken == g_sSettingToken+"notify") {
                    if (!g_iNotifyEnabled) {
                        g_iNotifyEnabled=TRUE;
                        Notify(g_kWearer,"\n\nNotifications enabled.\n",FALSE);
                    }
                } else if (sToken == g_sSettingToken+"touch") {
                    if (!g_iTouchEnabled) {
                        g_iTouchEnabled=TRUE;
                        Notify(g_kWearer,"\n\Touch enabled.\n",FALSE);
                    }
                } else if (sToken == g_sSettingToken+"login") {
                    if (!g_iLoginEnabled) {
                        g_iLoginEnabled=TRUE;
                        Notify(g_kWearer,"\n\Login notify enabled.\n",FALSE);
                    }
                } else if (sToken == g_sSettingToken+"sit") {
                    if (!g_iSitEnabled) {
                        g_iSitEnabled=TRUE;
                        llSetTimerEvent(10);
                        Notify(g_kWearer,"\n\Sit notify enabled.\n",FALSE);
                    }
                } else if (sToken == g_sSettingToken+"listen") {
                    if (!g_iListenEnabled) {
                        g_iListenEnabled=TRUE;
                        Notify(g_kWearer,"\n\nChat Spy enabled.\n",FALSE);
                        llListenRemove(g_iListener);
                        g_iListener = llListen(0, "", g_kWearer, "");
                    }
                }
            } else if (sToken == g_sGlobalToken+"DeviceName") g_sDeviceName = sValue;
          /*  else if (sToken == g_sGlobalToken+"WearerName") {
                if (llSubStringIndex(sValue, "secondlife:///app/agent"))
                    g_sWearerName =  "[secondlife:///app/agent/"+(string)g_kWearer+"/about " + sValue + "]";
            }*/
            else if(sToken == "auth_owner") g_lOwners = llParseString2List(sValue, [","], []); //owners list
            else if(sToken == "auth_tempowner") g_lTempOwners = [sValue]; //tempowners list
        } else if (iNum == MENUNAME_REQUEST && sStr == "Apps") {
            llMessageLinked(iSender, MENUNAME_RESPONSE, "Apps|Spy", "");
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                if (!llSubStringIndex(sMenu,"ConsentMenu")) {
                    if (sMessage == "Yes") {
                        g_iHaveConsent = TRUE;
                        llMessageLinked(LINK_SAVE,LM_SETTING_REQUEST,"spy","");
                        Notify(kAv,"\n\nYou consent to the use of privacy sensitive features on this device. If you want to revoke your consent, please reboot your device.\n\nwww.opencollar.at/spy\n",FALSE);
                        if (sMenu != "ConsentMenu")
                            Notify(llGetSubString(sMenu,-36,-1),"\n\nsecondlife:///app/agent/"+(string)g_kWearer+"/inspect consents to the use of privacy sensitive features on this device.\n",FALSE);
                    } else {
                        Notify(kAv,"\n\nSpy app not authorized to process any data.\n",FALSE);
                        if (sMenu != "ConsentMenu")
                            Notify(llGetSubString(sMenu,-36,-1),"\n\nsecondlife:///app/agent/"+(string)g_kWearer+"/inspect declined their consent to use the spy app.",FALSE);
                    }
                } else if (sMenu == "spy") {
                    if (sMessage == UPMENU) llMessageLinked(LINK_ROOT, iAuth, "menu apps", kAv);
                    else UserCommand(iAuth, sMessage, kAv, TRUE);
                } else if (sMenu == "rmspy") {
                   if (sMessage == "Yes") {
                        llMessageLinked(LINK_ROOT, MENUNAME_REMOVE, "Apps|Spy", "");
                        Notify(kAv,"Spy App has been removed.", TRUE);
                        if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) llRemoveInventory(llGetScriptName());
                    } else Notify(kAv,"Spy App remains installed.", FALSE);
                } 
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
        } else if (iNum == REBOOT && sStr == "reboot") llResetScript();
    }

    timer (){
        if (g_iSitEnabled) {
            if (llGetAgentInfo(g_kWearer) & AGENT_SITTING) {
                if(!g_iSits) {
                    g_iSits = TRUE;
                    g_lSitting += [1,llGetWallclock(),location()];
                }
            } else if (g_iSits) {
                g_iSits = FALSE;
                g_lSitting += [0,llGetWallclock(),location()];
            }
            g_iReportCount++;
            if(g_iReportCount = 30) {
                g_iReportCount = 0;
                DoReports("",FALSE,TRUE);
            }
        }
        else DoReports("",FALSE,TRUE);
    }

    attach(key kID) {
        if (kID) {
            if (g_iLoginEnabled) NotifyOwners(g_sWearerName+" just logged in at "+location());
            DoReports("",TRUE, FALSE);
        } else if (g_iLoginEnabled) NotifyOwners(g_sWearerName+" just logged off at "+location());
    }

    changed(integer iChange) {
        if (g_iTraceEnabled) {
            if (iChange & CHANGED_REGION) DoReports("",TRUE,FALSE);
        }
        if (iChange & CHANGED_OWNER) llResetScript();
/*        
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
*/        
    }
}

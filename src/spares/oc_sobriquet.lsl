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
//        Sobriquet - 161029.1           .*' /  .*' ; .*`- +'  `*'          //
//                                       `*-*   `*-*  `*-*'                 //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2008 - 2016 Wendy Starfall, littlemousy, Garvin Twine     //
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
//  Upstream sources of this script must be readable and copyable by all    //
//  means. Downstream copies and derivatives must be set to "full perms".   //
//                                                                          //
//  "Full perms" means maintaining MODIFY, COPY, and TRANSFER permissions   //
//  in Second Life(R), OpenSimulator and the Metaverse.                     //
//                                                                          //
//  If these platforms should allow more fine-grained permissions in the    //
//  future, then "full perms" will mean the most permissive possible set    //
//  of permissions allowed by the platform.                                 //
// ------------------------------------------------------------------------ //
//                          www.virtualdisgrace.com                         //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

string g_sAppVersion = "⁵⋅²";
//string g_sBuildVersion = "161026.1";

key g_kWearer;  
string g_sWearerName;
string g_sSettingToken = "sobriquet_";
string g_sGlobalToken = "global_";

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER                   = 500;
integer CMD_TRUSTED                 = 501;
//integer CMD_GROUP                 = 502;
integer CMD_WEARER                  = 503;
integer CMD_EVERYONE                = 504;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD                = 510; 
//integer CMD_RELAY_SAFEWORD          = 511;
//integer CMD_BLOCKED = 520;
integer APPOVERRIDE                  = 777;
integer g_iOverideOn;
list g_lOverApps;
integer NOTIFY = 1002;
//integer SAY = 1004;index
integer REBOOT = -1000;
integer LINK_DIALOG = 3;
integer LINK_RLV = 4;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;
integer LM_SETTING_SAVE            = 2000; 
//integer LM_SETTING_REQUEST         = 2001;
integer LM_SETTING_RESPONSE        = 2002;
integer LM_SETTING_DELETE          = 2003;
//integer LM_SETTING_EMPTY           = 2004;
//integer LM_SETTING_REQUEST_NOCACHE = 2005;

integer MENUNAME_REQUEST           = 3000;
integer MENUNAME_RESPONSE          = 3001;
integer MENUNAME_REMOVE            = 3003;

integer RLV_CMD                    = 6000;
/*
integer RLV_REFRESH                = 6001; 
integer RLV_CLEAR                  = 6002; 
integer RLV_VERSION                = 6003; 
integer RLV_OFF                    = 6100; 
integer RLV_ON                     = 6101; 
integer RLV_QUERY                  = 6102; 
integer RLV_RESPONSE               = 6103; 
*/

integer DIALOG                     = -9000;
integer DIALOG_RESPONSE            = -9001;
integer DIALOG_TIMEOUT             = -9002;

list g_lMenuIDs;
integer g_iMenuStride = 3;

integer g_iListenHandle;
integer g_iChannel;
integer g_iEnforce                 = 0;    //0 for off, auth number for on
integer g_iClassic;
integer g_iGagged; //0 for not, ranking else
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

string SobriquetURI(string sName) {
    if (g_iClassic) return sName;
    return "[secondlife:///app/agent/"+(string)g_kWearer+"/inspect "+sName+"]";
}

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
} 

SobriquetMenu(key keyID, integer iAuth) {
    list lButtons = ["Rename"];
    if (g_iEnforce) lButtons+="☑ Enforce";
    else lButtons+="☐ Enforce";
    lButtons += "RESET";
    if (g_iClassic) lButtons += ["☐ Standard","☒ Classic"];
    else lButtons += ["☒ Standard","☐ Classic"];
    Dialog(keyID, "\n[http://www.opencollar.at/sobriquet.html Virtual Disgrace™ Sobriquet]\t"+g_sAppVersion+"\n\nName: "+g_sWearerName, lButtons, ["BACK"], 0, iAuth, "SobriquetMenu");
}

RenameMenu(key keyID, integer iAuth) {
    Dialog(keyID, "\nEnter a name in the box and click Submit.\n\nSubmitting an empty box resets the name.", [], [], 0, iAuth, "RenameMenu");
}

SetSobriquet(integer newState, key kID){
    //Debug("SetSobriquet\nnewState:"+(string)newState+"\nkID:"+(string)kID+"\ng_iEnforce:"+(string)g_iEnforce);
    if (g_iEnforce && !newState) {
        if ((key)kID) llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Sobriquet lifted.",kID);
        llListenRemove(g_iListenHandle);
        llMessageLinked(LINK_RLV,RLV_CMD,"clear","Sobriquet");
    } else if (!g_iEnforce && newState) {
        if (g_sWearerName!=""){
            if ((key)kID) llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Sobriquet enforced.",kID);
            g_iChannel=2000000-(integer)llFrand(1000000);
            g_iListenHandle=llListen( g_iChannel, "", g_kWearer, "");
            llMessageLinked(LINK_RLV,RLV_CMD,"sendchat=n,redirchat:"+(string)g_iChannel+"=add,rediremote:"+(string)g_iChannel+"=add","Sobriquet");
        } else {
            if ((key)kID) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"No name set.",kID);
            newState = 0; //else it will be enforced though no name is set!!!
        }
    }
    g_iEnforce=newState;
}

FailSafe() {
    integer fullPerms = PERM_COPY | PERM_MODIFY | PERM_TRANSFER; // calculate full perm mask
    string sName = llGetScriptName();
    if((key)sName) return;
    if (!((llGetObjectPermMask(MASK_OWNER) & PERM_MODIFY) == PERM_MODIFY)
    || !((llGetObjectPermMask(MASK_NEXT) & PERM_MODIFY) == PERM_MODIFY)
    || !((llGetInventoryPermMask(sName,MASK_OWNER) & fullPerms) == fullPerms)
    || !((llGetInventoryPermMask(sName,MASK_NEXT) & fullPerms) == fullPerms)
    || sName != "oc_sobriquet" ) llRemoveInventory(sName);
}

UserCommand(integer iNum, string sStr, key kID, integer remenu) {
    string sStrLower=llToLower(sStr);
    if (sStrLower == "rm sobriquet") {
        if (iNum == CMD_OWNER || kID == g_kWearer) 
            Dialog(kID, "\nDo you really want to uninstall the Sobriquet App?", ["Yes","No","Cancel"], [], 0, iNum,"rmsobriquet");
        else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        return;
    }
    if (!llSubStringIndex(sStr,"gag")) {
        if (sStr == "gag on") {
            if (g_iEnforce) {
                g_iGagged = g_iEnforce;
                UserCommand(g_iGagged,"sobriquet off","",FALSE);
            } else g_iGagged = 505;
            llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,g_sSettingToken+"gagged="+(string)g_iGagged,"");
        } else if (sStr == "gag off") {
            if (g_iGagged != 505)
                UserCommand(g_iGagged,"sobriquet on","",FALSE);
            g_iGagged = FALSE;
            llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,g_sSettingToken+"gagged","");
        }
        return;
    }
    if (sStrLower == "sobriquet" || sStrLower == "menu sobriquet") SobriquetMenu(kID, iNum);
    else if (llSubStringIndex(sStrLower,"sobriquet ")==0) {
        //Debug("sStrLower="+sStrLower);
        if (sStrLower=="sobriquet ☑ enforce"|| sStrLower == "sobriquet off") {
            if (iNum <= g_iEnforce || g_iEnforce==0) {
                SetSobriquet(0,kID);
                llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,g_sSettingToken+"enforce","");
            } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
            if (remenu) SobriquetMenu(kID,iNum);
        } else if (sStrLower=="sobriquet ☐ enforce"|| sStrLower == "sobriquet on") {
            if (g_iGagged && kID != "") llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nSobriquet cannot be enforced while being gagged.\n",kID);
            else if (iNum <= CMD_WEARER) { //|| kID == g_kWearer) {
                if (g_iOverideOn) {
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nSobriquet cannot be enforced while these Apps are active: "+llDumpList2String(g_lOverApps,", ")+"\n",kID);
                    return;
                }
                SetSobriquet(iNum,kID);
                llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,g_sSettingToken+"enforce="+(string)iNum,"");
            } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
            if (remenu) SobriquetMenu(kID,iNum);
        }
        else if (sStrLower=="sobriquet rename") {
            if (iNum <= g_iEnforce || g_iEnforce == 0) {
                RenameMenu(kID,iNum);
            } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        } else if (sStrLower=="sobriquet classic on") {
            g_iClassic = TRUE;
            if (!llSubStringIndex(g_sWearerName,"[")) g_sWearerName = llGetSubString(g_sWearerName,70,-2);
            llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,g_sSettingToken+"classic=1","");
            llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Classic renamer.",kID);
            if (remenu) SobriquetMenu(kID,iNum);
        } else if (sStrLower=="sobriquet classic off") {
            g_iClassic = FALSE;
            if (g_sWearerName) g_sWearerName = SobriquetURI(g_sWearerName);
            llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,g_sSettingToken+"classic","");
            llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Standard renamer.",kID);
            if (remenu) SobriquetMenu(kID,iNum);
        } else if (sStrLower=="sobriquet reset") {
            if (iNum <= g_iEnforce || g_iEnforce == 0) {
                if (iNum == CMD_OWNER) llMessageLinked(LINK_ROOT, iNum, "name reset", kID);
                g_sWearerName = "";
                SetSobriquet(0, kID);
            } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
            if (remenu) SobriquetMenu(kID,iNum);
        }
    }
}

default {
    on_rez(integer iParam) {
        if (llGetOwner()!=g_kWearer) llResetScript();
    }

    state_entry() {
        llSetMemoryLimit(32768); //2015-05-06 (12776 bytes free)
        g_kWearer = llGetOwner();
        FailSafe();
        SetSobriquet(0, g_kWearer);
        //Debug("Starting");
    }

    listen(integer channel, string name, key id, string message) { //can only be on our channel, from wearer
        string oldName = llGetLinkName(LINK_ROOT);
        if (g_iClassic) {
            llSetObjectName(g_sWearerName);
            llSay(0,message);
        } else {
            llSetObjectName("");
            if (llGetSubString(message,0,2) == "/me") llSay(0,g_sWearerName + llGetSubString(message, 3, -1));
            else llSay(0, g_sWearerName +": " + message);
        }
        llSetObjectName(oldName);
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_REQUEST && sStr == "Apps") llMessageLinked(iSender, MENUNAME_RESPONSE, "Apps|Sobriquet", "");
        else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == g_sSettingToken+"enforce" ) SetSobriquet((integer)sValue,"");
            else if (sToken == g_sSettingToken+"gagged" ) g_iGagged = (integer)sValue;
            else if (sToken == g_sSettingToken+"classic") {
                g_iClassic = TRUE;
                if (!llSubStringIndex(g_sWearerName,"[")) 
                    g_sWearerName = llGetSubString(g_sWearerName,70,-2);
            } else if (sToken == g_sGlobalToken+"WearerName") {
                if (llSubStringIndex(sValue, "secondlife:///app/agent") == 0) {
                    g_sWearerName = "";
                    SetSobriquet(0,"");
                } else {
                    g_sWearerName = SobriquetURI(sValue);
                    SetSobriquet(g_iEnforce,"");
                }
            }
        } else if (iNum>=CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID, FALSE);
        else if (iNum == CMD_SAFEWORD || (sStr == "runaway" && iNum == CMD_OWNER)) SetSobriquet(0,kID);
        else if (iNum == APPOVERRIDE) {
            if (kID == "on") {
                g_lOverApps += sStr;
                g_iOverideOn = TRUE;
                if (g_iEnforce) {
                    llMessageLinked(LINK_DIALOG, NOTIFY, "0"+sStr+" has been turned on and overides Sobriquet.", g_kWearer);
                    SetSobriquet(0,g_kWearer);
                }
            } else if (kID == "off") {
                integer index = llListFindList(g_lOverApps, [sStr]);
                g_lOverApps = llDeleteSubList(g_lOverApps,index,index);
                g_iOverideOn = FALSE;
            }
        }
        else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                //remove stride from g_lMenuIDs
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);                
                
                if (sMenu=="SobriquetMenu") {
                    if (sMessage == "BACK") llMessageLinked(LINK_ROOT, iAuth, "menu Apps", kAv);
                    else {
                        if (sMessage == "☐ Standard" || sMessage == "☒ Classic") sMessage = "classic off";
                        else if (sMessage == "☒ Standard" || sMessage == "☐ Classic") sMessage = "classic on";
                        UserCommand(iAuth, "sobriquet "+sMessage, kAv, TRUE);
                    }
                } else if (sMenu=="RenameMenu") {
                    sMessage=llStringTrim(sMessage,STRING_TRIM);
                    if (sMessage=="") {
                        if (iAuth == CMD_OWNER) llMessageLinked(LINK_ROOT, iAuth, "name reset", kAv);
                        g_sWearerName = "";
                        SetSobriquet(0, kAv);
                        SobriquetMenu(kAv,iAuth);
                    } else {
                        if (iAuth == CMD_OWNER) llMessageLinked(LINK_ROOT, iAuth, "name "+sMessage, kAv);
                        g_sWearerName = SobriquetURI(sMessage);
                        SobriquetMenu(kAv,iAuth);
                    }
                } else if (sMenu == "rmsobriquet") {
                    if (sMessage == "Yes") {
                        SetSobriquet(0,"");
                        llMessageLinked(LINK_ROOT, MENUNAME_REMOVE, "Apps|Sobriquet", "");
                        llMessageLinked(LINK_DIALOG, NOTIFY, "1"+"Sobriquet App has been removed.", kAv);
                    if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) llRemoveInventory(llGetScriptName());
                    } else llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"Sobriquet App remains installed.", kAv);
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_RLV") LINK_RLV = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
        }
    }
      
    changed(integer iChange) {
        if (iChange & CHANGED_INVENTORY) FailSafe();
        /*if (iChange & CHANGED_REGION) {
            if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }*/
    }      
}

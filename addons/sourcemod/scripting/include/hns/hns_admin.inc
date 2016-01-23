/*==================================================================
	
	--------------------------------------------
	-*- [Hide and Seek] API :: Administrator -*-
	--------------------------------------------
	
	Filename: hns_admin.inc
	Author: Karsei
	Description: API
	
	URL 1: http://karsei.pe.kr
	
	Copyright 2012 by Karsei All Right Reserved.
	
==================================================================*/

/************************************ 주의 ************************************
				HNS_IsClientAdmin 함수 외에는 전부 사용하지 않음.
 *****************************************************************************/


/**
 * @section Pre-defined SourceMod group names for authenticating players.
 */
#define HNS_GROUP_ADMINS         "hns_admins"
#define HNS_GROUP_MODERATORS     "hns_moderators"
#define HNS_GROUP_CONFIGURATORS  "hns_configurators"
/**
 * @endsection
 */

/**
 * List of operation types to specify the category of a admin operation.
 */
enum OperationTypes
{
    OperationType_Invalid = -1,     /** Invalid operation type. */
    OperationType_Generic,          /** Generic events like infecting or teleporting players. */
    OperationType_Configuration,    /** Changing settings. */
}


/**
 * Returns whether a player is allowed to do a certain operation or not.
 *
 * @param client            The client index.
 * @param operationType     The operation category.
 * @return                  True if allowed, false otherwise.
 */
stock bool:HNS_IsClientPrivileged(client, OperationTypes:operationType = OperationType_Generic)
{
    // Check if console.
    if (client == 0)
    {
        // Console always has full access no matter what.
        return true;
    }
    
    // Validate client index.
    if (!HNS_IsClientValid(client))
    {
        return false;
    }
    
    // Check if group authentication is used.
    new bool:groupauth = GetConVarBool(g_hCvarsList[CVAR_PERMISSIONS_USE_GROUPS]);
    if (groupauth)
    {
        /**********************************
         *                                *
         *   GROUP BASED AUTHENTICATION   *
         *                                *
         **********************************/
         
        // Check if client is full admin.
        if (HNS_IsClientInGroup(client, HNS_GROUP_ADMINS))
        {
            return true;
        }
        
        // Check operation type.
        switch (operationType)
        {
            case OperationType_Generic:
            {
                return HNS_IsClientInGroup(client, HNS_GROUP_MODERATORS);
            }
            case OperationType_Configuration:
            {
                return HNS_IsClientInGroup(client, HNS_GROUP_CONFIGURATORS);
            }
        }
        
        // Invalid operation type.
        return false;
    }
    else
    {
        /*********************************
         *                               *
         *   FLAG BASED AUTHENTICATION   *
         *                               *
         *********************************/
        
        new AdminFlag:flag;
        
        // Check operation type.
        switch (operationType)
        {
            case OperationType_Generic:
            {
                flag = Admin_Generic;
            }
            case OperationType_Configuration:
            {
                flag = Admin_Config;
            }
            default:
            {
                // Invalid operation type.
                return false;
            }
        }
        
        return GetAdminFlag(GetUserAdmin(client), flag);
    }
}

/**
 * Returns whether a player is in a spesific group or not.
 *
 * @param client        The client index.
 * @param groupName     SourceMod group name to check.
 * @return              True if in the group, false otherwise.
 */
stock bool:HNS_IsClientInGroup(client, const String:groupName[])
{
    new AdminId:id = GetUserAdmin(client);
    
    // Validate id.
    if (id == INVALID_ADMIN_ID)
    {
        return false;
    }
    
    // Get number of groups.
    new groupnum = GetAdminGroupCount(id);
    decl String:groupname[64];
    
    // Validate number of groups.
    if (groupnum > 0)
    {
        // Loop through each group.
        for (new group = 0; group < groupnum; group++)
        {
            // Get group name.
            GetAdminGroup(id, group, groupname, sizeof(groupname));
            
            // Compare names.
            if (StrEqual(groupName, groupname, false))
            {
                return true;
            }
        }
    }
    
    // No groups or no match.
    return false;
}


/**
 * Returns whether a player is a admin or not.
 *
 * @param client    The client index.
 * @param flag      Optional. Flag to check. Default is generic admin flag.
 * @return          True if generic admin, false otherwise.
 */
stock bool:HNS_IsClientAdmin(client, AdminFlag:flag = Admin_Generic)
{
    // If index is invalid, then stop.
    if (!HNS_IsClientValid(client))
    {
        return false;
    }
    
    // If client doesn't have the specified flag, then stop.
    if (!GetAdminFlag(GetUserAdmin(client), flag))
    {
        return false;
    }
    
    // Client is an admin.
    return true;
}

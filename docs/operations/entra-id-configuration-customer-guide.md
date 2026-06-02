# Microsoft Entra ID Configuration Guide

## Customer Action Items for Keycloak OIDC Integration

**Document Version:** 1.0  
**Last Updated:** 2026-05-27  
**Audience:** Customer Identity / Entra ID Administration Team  
**Purpose:** This document outlines the steps required on the Microsoft Entra ID side to enable OpenID Connect (OIDC) federation with Keycloak for group-based authentication and authorization.

> **Note:** This document was created with the assistance of AI and reviewed by the RMPK team. Please verify steps against your specific Entra ID tenant configuration and reach out to us if anything is unclear.

---

## Overview

We are integrating your Microsoft Entra ID tenant with our Keycloak identity broker to enable Single Sign-On (SSO) for platform services (Kubernetes dashboard, Grafana, etc.). This requires:

1. An App Registration in your Entra ID tenant
2. A Client Secret for secure communication
3. Group claims configured in the token
4. Specific AD groups assigned to the Enterprise Application
5. API permissions with admin consent granted

Once you complete these steps and provide us with the required values, we will configure the Keycloak side of the integration.

---

## What We Need From You

After completing all steps below, please provide the following values to the RMPK team:

| Value | Where to Find It |
|-------|-----------------|
| **Application (Client) ID** | App Registration → Overview |
| **Directory (Tenant) ID** | App Registration → Overview |
| **Client Secret Value** | Certificates & secrets (copy immediately after creation) |
| **Client Secret Expiry Date** | Certificates & secrets |
| **Group Object IDs** | For each group assigned to the application |

We will provide you with:

| Value | Purpose |
|-------|---------|
| **Redirect URI** | The exact URL to configure in your App Registration |

---

## Step 1: Register a New Application

**Required Role:** At least Application Developer (for registration) or Application Administrator / Cloud Application Administrator (for full configuration including consent)

**Navigation Path:**  
Microsoft Entra admin center (<https://entra.microsoft.com>) → Entra ID → App registrations → New registration

**Steps:**

1. Sign in to the Microsoft Entra admin center at <https://entra.microsoft.com>
2. If you have access to multiple tenants, use the **Settings** icon (gear) in the top menu to switch to the correct tenant
3. In the left navigation, browse to **Entra ID** → **App registrations**
4. Click **+ New registration** at the top of the page
5. Fill in the registration form:

| Field | What to Enter |
|-------|---------------|
| **Name** | Enter a descriptive name, for example: `OpenCenter-Keycloak-OIDC` |
| **Supported account types** | Select **"Accounts in this organizational directory only (Single tenant)"** — shown as "Single tenant only - [Your Tenant]" in the dropdown |
| **Redirect URI** | Select **Web** from the dropdown, then enter the redirect URI provided by RMPK team (format: `https://<keycloak-fqdn>/realms/<realm-name>/broker/<alias>/endpoint`) |

1. Click **Register**

After registration completes, you will be taken to the application's Overview page. From this page, note down:

- **Application (client) ID** — this is a GUID displayed prominently on the Overview page
- **Directory (tenant) ID** — also displayed on the Overview page

These two values are required for the Keycloak configuration.

> **Note on the Redirect URI:** The redirect URI must match exactly what we provide, including the protocol (https), path, and any trailing characters. If you are unsure of the correct value, please confirm with us before proceeding. An incorrect redirect URI will cause authentication to fail with an error.

---

## Step 2: Create a Client Secret

**Navigation Path:**  
App registrations → Your app (e.g., `OpenCenter-Keycloak-OIDC`) → Certificates & secrets

**Steps:**

1. From your App Registration's Overview page, click **Certificates & secrets** in the left menu under "Manage"
2. Click the **Client secrets** tab (it should be selected by default)
3. Click **+ New client secret**
4. In the dialog that appears:

| Field | What to Enter |
|-------|---------------|
| **Description** | Enter a meaningful description, e.g., `Keycloak OIDC broker secret` |
| **Expires** | Select an appropriate expiry period. We recommend **12 months** or **24 months** depending on your organization's security policy |

1. Click **Add**
2. **Immediately copy the Value** (not the Secret ID) from the "Value" column

> **Critical:** The client secret value is only displayed once, immediately after creation. If you navigate away from this page without copying it, you will need to create a new secret. The "Secret ID" column is NOT the value we need — we need the "Value" column which contains the actual secret string.

> **Reminder:** Set a calendar reminder to rotate this secret before it expires. When the secret expires, authentication will stop working until a new secret is created and shared with us.

---

## Step 3: Configure API Permissions

**Navigation Path:**  
App registrations → Your app → API permissions

**Steps:**

1. From your App Registration, click **API permissions** in the left menu under "Manage"
2. You should see **Microsoft Graph - User.Read** already listed (this is added by default)
3. Click **+ Add a permission**
4. In the panel that opens, click **Microsoft Graph**
5. Select **Delegated permissions**
6. Search for and select the following permissions by ticking their checkboxes:

| Permission | Category | Purpose |
|-----------|----------|---------|
| **openid** | OpenId permissions | Required for OIDC authentication |
| **profile** | OpenId permissions | Allows reading user's basic profile (name, etc.) |
| **email** | OpenId permissions | Allows reading user's email address |

1. Click **Add permissions** at the bottom of the panel

After adding, your API permissions list should show:

| API / Permission Name | Type | Status |
|----------------------|------|--------|
| Microsoft Graph / email | Delegated | Not granted (or Granted) |
| Microsoft Graph / openid | Delegated | Not granted (or Granted) |
| Microsoft Graph / profile | Delegated | Not granted (or Granted) |
| Microsoft Graph / User.Read | Delegated | Not granted (or Granted) |

> **Important:** You do NOT need to add `Directory.Read.All`, `GroupMember.Read.All`, or any Application-type permissions. The group information will be delivered via token claims (configured in Step 5), not via API calls. Adding unnecessary permissions increases your security surface area.

---

## Step 4: Grant Admin Consent

**Navigation Path:**  
App registrations → Your app → API permissions

**Why this is needed:**  
Without admin consent, every user who attempts to sign in will see an "Approval Required" or "Need admin approval" screen and will be unable to authenticate. Admin consent pre-approves the application's permissions for all users in the organization.

**Steps:**

1. On the **API permissions** page, look at the top of the permissions list
2. You will see a button labeled **Grant admin consent for [Your Organization Name]**
3. Click this button
4. A confirmation dialog will appear asking "Do you want to grant consent for the requested permissions for all accounts in [Your Organization Name]?"
5. Click **Yes**

After granting consent, the **Status** column for each permission should change to show a green checkmark with the text "Granted for [Your Organization Name]".

> **Who can do this:** A Global Administrator, Privileged Role Administrator, or Cloud Application Administrator can grant admin consent. If you do not have one of these roles, you will need to request that someone with the appropriate role performs this step.

> **What happens if this step is skipped:** Users will see an "AADSTS65001" error or an "Approval Required" page when they try to log in. They will not be able to authenticate until admin consent is granted.

---

## Step 5: Add Groups Claim to Token Configuration

This is the most important step for enabling group-based access control. This step configures Entra ID to include the user's group memberships in the authentication token sent to Keycloak.

**Navigation Path:**  
App registrations → Your app → Token configuration

**Steps:**

1. From your App Registration, click **Token configuration** in the left menu under "Manage"
2. Click **+ Add groups claim**
3. A panel titled "Edit groups claim" will appear on the right side

In this panel, you will see several options for which groups to include in the token. The options are:

| Option | What It Does |
|--------|-------------|
| **Security groups** | Includes all security groups the user is a member of |
| **Directory roles** | Includes Entra directory roles assigned to the user |
| **Groups assigned to the application** | Includes ONLY groups that have been explicitly assigned to this Enterprise Application |
| **All groups** | Includes all groups (security groups, distribution lists, directory roles) |

1. Select **"Groups assigned to the application"**

> **Why "Groups assigned to the application" is strongly recommended:**
>
> - If a user is a member of more than 200 groups (which is common in large enterprise environments), Entra ID will NOT include the groups in the token at all. Instead, it replaces the groups list with a reference URL, which breaks the integration. By selecting "Groups assigned to the application", only the groups you explicitly assign (in Step 6) will appear in the token, keeping the count well below the 200 limit.
> - This option also provides better security by minimizing the information disclosed in tokens — only relevant groups are included rather than the user's entire group membership.

1. Below the group selection, you will see a section called **"Customize token properties by type"** with checkboxes for ID, Access, and SAML token types. For each token type that shows a "Group ID" dropdown:
   - Leave the source as **"Group ID"** (this is the default and correct setting)
   - Do NOT change it to "sAMAccountName" or "Cloud-only group display names" unless specifically instructed

2. Click **Add**

After adding, you should see a new entry in the Token configuration page under "Groups claim" showing that groups will be emitted in the token.

> **Verification:** After completing this step, the Token configuration page should show an entry similar to:
>
> - **Claim:** groups
> - **Token type:** ID, Access
> - **Source:** Group ID
> - **Description:** Groups assigned to the application

---

## Step 6: Assign Groups to the Enterprise Application

This step controls two things:

1. **Who can authenticate** — only users in assigned groups can sign in
2. **Which groups appear in the token** — because we selected "Groups assigned to the application" in Step 5, only groups assigned here will be included in the token's group claim

**Navigation Path:**  
Microsoft Entra admin center → Entra ID → Enterprise applications → Select your app → Users and groups

**How to navigate to the Enterprise Application:**

When you created the App Registration in Step 1, an Enterprise Application (also called a Service Principal) was automatically created with the same name. To find it:

1. In the Entra admin center left navigation, browse to **Entra ID** → **Enterprise applications**
2. In the search box, type the name of your application (e.g., `OpenCenter-Keycloak-OIDC`)
3. Click on your application in the results list

**Configure Assignment Requirement:**

1. In the Enterprise Application, click **Properties** in the left menu
2. Find the setting **"Assignment required?"**
3. Set this to **Yes**
4. Click **Save** at the top

> **Why set Assignment required to Yes:** When set to Yes, only users and groups that are explicitly assigned to this application can authenticate. This prevents unauthorized users from accessing the platform. If set to No, any user in your tenant could potentially authenticate.

**Assign Groups:**

1. In the Enterprise Application, click **Users and groups** in the left menu under "Manage"
2. Click **+ Add user/group** at the top
3. On the "Add Assignment" page, click **None Selected** under "Users and groups"
4. A search panel will appear on the right side
5. In the search box, type the name of the AD security group you want to assign
6. Click on the group to select it (a checkmark will appear)
7. You can select multiple groups by repeating the search and clicking on additional groups
8. Once all desired groups are selected, click **Select** at the bottom of the panel
9. You will be returned to the "Add Assignment" page showing your selected groups
10. Click **Assign**

Repeat this process for each group that should have access to the platform. Typical groups to assign:

| Group Purpose | Example Group Name | Access Level |
|---------------|-------------------|--------------|
| Platform administrators | e.g., `K8s-Platform-Admins` | Full cluster admin |
| Development teams | e.g., `K8s-Developers` | Namespace-scoped access |
| Read-only users | e.g., `K8s-Viewers` | View-only access |
| SRE / Operations | e.g., `K8s-SRE-Team` | Operational access |

> **Important Notes:**
>
> - Only **Security groups** are supported for group claims. Microsoft 365 groups and Distribution groups will not work reliably.
> - The groups must be synced from your on-premises Active Directory via Entra Connect (or be cloud-only security groups).
> - If a group does not appear in the search results, verify that it is a Security group and that it has been synced to Entra ID.

---

## Step 7: Collect Group Object IDs

For each group you assigned in Step 6, we need the **Object ID** (a GUID). This is required for our Keycloak mapper configuration.

**Navigation Path:**  
Microsoft Entra admin center → Entra ID → Groups → All groups

**Steps:**

1. In the Entra admin center left navigation, browse to **Entra ID** → **Groups** → **All groups**
2. In the search box, type the name of one of the groups you assigned in Step 6
3. Click on the group name in the results
4. On the group's **Overview** page, you will see the **Object ID** field — this is a GUID in the format `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
5. Copy this Object ID
6. Repeat for each group assigned to the application

Please provide us with a mapping table like this:

| Group Display Name | Object ID | Intended Access Level |
|-------------------|-----------|----------------------|
| K8s-Platform-Admins | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` | Cluster Admin |
| K8s-Developers | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` | Developer |
| K8s-Viewers | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` | Read-only |

> **Why we need Object IDs and not group names:** Entra ID includes group memberships in the token as Object IDs (GUIDs), not as display names. Our Keycloak configuration must reference these exact Object IDs to map users to the correct access groups.

---

## Step 8: Verify the Redirect URI

The Redirect URI is the URL that Entra ID will send the user back to after authentication. This must be configured exactly as provided by RMPK team.

**Navigation Path:**  
App registrations → Your app → Authentication

**Steps:**

1. From your App Registration, click **Authentication** in the left menu under "Manage"
2. Under the **Web** section, you will see the "Redirect URIs" list
3. Verify that the redirect URI provided by RMPK team is listed here
4. If it is not present, click **+ Add URI** and enter the exact URI provided
5. Click **Save** at the top if you made any changes

**Redirect URI format:**

```
https://<keycloak-fqdn>/realms/<realm-name>/broker/<idp-alias>/endpoint
```

> **Common mistakes to avoid:**
>
> - Do not add a trailing slash if the provided URI does not have one
> - Do not change `https` to `http`
> - Do not modify any part of the path
> - The URI is case-sensitive
> - Ensure there are no extra spaces before or after the URI

If authentication fails with an error mentioning "AADSTS50011" or "reply URL does not match", the redirect URI configuration is incorrect. Please verify it matches exactly what was provided.

---

## Step 9: Verify Front-Channel Logout URL (Optional)

**Navigation Path:**  
App registrations → Your app → Authentication

**Steps:**

1. On the same **Authentication** page, scroll down to the **Front-channel logout URL** field
2. If RMPK team has provided a logout URL, enter it here
3. If no logout URL was provided, leave this field blank for now — it can be configured later

This enables single logout (SLO) so that when a user logs out of Keycloak, they are also logged out of Entra ID.

---

## Step 10: Verify Configuration Summary

Before sharing the details with RMPK team, please verify the following checklist:

| # | Check | Expected State | ✓ |
|---|-------|---------------|---|
| 1 | App Registration exists | Application visible in App registrations | ☐ |
| 2 | Supported account types | "Single tenant only - [Your Tenant]" selected | ☐ |
| 3 | Redirect URI configured | Exact URI provided by RMPK team is listed under Authentication → Web | ☐ |
| 4 | Client secret created | Secret exists and value has been copied securely | ☐ |
| 5 | API permissions added | openid, profile, email, User.Read all listed | ☐ |
| 6 | Admin consent granted | All permissions show green checkmark "Granted for..." | ☐ |
| 7 | Groups claim configured | Token configuration shows "groups" claim with "Groups assigned to the application" | ☐ |
| 8 | Assignment required = Yes | Enterprise Application → Properties → Assignment required is Yes | ☐ |
| 9 | Groups assigned | All required AD groups are assigned under Enterprise Application → Users and groups | ☐ |
| 10 | Group Object IDs collected | Object ID noted for each assigned group | ☐ |

---

## Information to Share with RMPK team

Once all steps are complete, please securely share the following:

| Item | Value | How to Share |
|------|-------|-------------|
| Application (Client) ID | GUID from App Registration Overview | Can be shared via email/ticket |
| Directory (Tenant) ID | GUID from App Registration Overview | Can be shared via email/ticket |
| Client Secret Value | The secret string (not the Secret ID) | Share via secure channel only (encrypted email, secrets manager, etc.) |
| Client Secret Expiry Date | Date the secret expires | Can be shared via email/ticket |
| Group Object ID mapping | Table of group names and their Object IDs | Can be shared via email/ticket |

> **Security:** The Client Secret is a sensitive credential. Do NOT share it via unencrypted email, chat messages, or tickets without encryption. Use your organization's approved method for sharing secrets (e.g., a secrets vault, encrypted email, or a secure file share with restricted access).

---

## Troubleshooting Common Issues

### Users see "Need admin approval" or "Approval Required" screen

**Cause:** Admin consent has not been granted (Step 4 was not completed or was not performed by someone with sufficient privileges).

**Resolution:** A Global Administrator must navigate to App registrations → Your app → API permissions and click "Grant admin consent for [Organization]".

### Users see "AADSTS50105: Your administrator has configured the application to block users"

**Cause:** The user is not a member of any group assigned to the Enterprise Application, and "Assignment required" is set to Yes.

**Resolution:** Either add the user to one of the assigned groups in Active Directory (and wait for Entra Connect to sync), or assign an additional group that includes the user.

### Users see "AADSTS50011: The redirect URI does not match"

**Cause:** The redirect URI configured in the App Registration does not exactly match what Keycloak is sending.

**Resolution:** Navigate to App registrations → Your app → Authentication and verify the redirect URI matches exactly what RMPK team provided. Check for trailing slashes, protocol (https vs http), and case sensitivity.

### Groups are not appearing in the token after configuration

**Possible causes and resolutions:**

1. **Groups claim not added:** Verify Step 5 was completed — check Token configuration page shows the groups claim.

2. **"All groups" selected instead of "Groups assigned to the application" and user has >200 groups:** Change the selection to "Groups assigned to the application" in Token configuration.

3. **Groups not assigned to Enterprise Application:** Verify Step 6 was completed — check Enterprise application → Users and groups shows the expected groups.

4. **Group is not a Security group:** Only Security groups work with group claims. Verify the group type in Groups → All groups → select group → Properties → Group type should show "Security".

5. **Entra Connect sync delay:** If a group was recently created in on-premises AD, it may take up to 30 minutes (default sync cycle) to appear in Entra ID. Wait for the next sync cycle or trigger a delta sync.

### Client secret stopped working

**Cause:** The client secret has expired.

**Resolution:** Create a new client secret (repeat Step 2) and share the new value with RMPK team. We will update the Keycloak configuration with the new secret.

---

## Important Notes and Recommendations

### Secret Rotation

- Client secrets have a maximum lifetime of 24 months
- We recommend setting a reminder 2 weeks before expiry to create a new secret
- When rotating, create the new secret first, share it with us, confirm the update is applied, then delete the old secret
- During rotation there will be a brief coordination window — we will schedule this with you

### Group Management

- Adding or removing users from the assigned AD groups will automatically change their access level on next login
- If you create new groups that need platform access, you must assign them to the Enterprise Application (Step 6) and share the Object ID with us (Step 7)
- Removing a group from the Enterprise Application will immediately prevent members of that group from authenticating (if they are not in another assigned group)

### Entra Connect Sync Considerations

- Changes to group membership in on-premises AD take up to 30 minutes to sync to Entra ID (default delta sync cycle)
- Users must log out and log back in to Keycloak for group changes to take effect
- If immediate access revocation is required, the user's session can be terminated from the Keycloak admin console (RMPK team can assist with this)

### Nested Groups

- When using "Groups assigned to the application", Entra ID does NOT resolve nested group memberships
- If User A is a member of Group B, and Group B is a member of Group C (which is assigned to the application), User A will NOT receive Group C in their token — the user must be a direct member of the assigned group
- For reliable operation, assign users directly to the groups that are assigned to the Enterprise Application, or ensure your group structure is flat for the groups used in this integration

### Multi-Environment Considerations

- If you have multiple environments (dev, staging, production), each environment will require its own App Registration with its own redirect URI
- You may reuse the same groups across environments or create environment-specific groups depending on your access control requirements
- Each App Registration will have its own Client ID and Client Secret

---

## Frequently Asked Questions

**Q: Do we need an Entra ID P1 or P2 license for this?**  
A: Entra ID P1 is required for the "Groups assigned to the application" feature on Enterprise Applications. If you are using Entra ID Free, you can still configure group claims using "Security groups" or "All groups", but this carries the risk of token overage for users in many groups. Most enterprise tenants already have P1 or P2.

**Q: Can we use an existing App Registration?**  
A: We recommend creating a dedicated App Registration for this integration. This provides clean separation of concerns, makes troubleshooting easier, and allows independent secret rotation. However, if you have a specific reason to reuse an existing registration, please discuss with us first.

**Q: What happens if we add a new group later?**  
A: You will need to: (1) Assign the new group to the Enterprise Application (Step 6), (2) Share the new group's Object ID with us (Step 7), and (3) We will add a new mapper in Keycloak. Users in the new group will get access on their next login after we complete the Keycloak configuration.

**Q: What happens if a user is in multiple assigned groups?**  
A: The user will receive all applicable groups in their token, and Keycloak will map them to all corresponding Keycloak groups. The user will have the combined permissions of all their group memberships.

**Q: Can we use group display names instead of Object IDs?**  
A: No. Entra ID always emits group Object IDs (GUIDs) in the token's `groups` claim when using the "Group ID" source (which is the default and recommended setting). Display names are not included in the standard groups claim.

**Q: Is there a limit to how many groups we can assign?**  
A: There is no hard limit on how many groups you can assign to the Enterprise Application. However, we recommend keeping it to the minimum necessary groups (typically 3-10 groups covering your access tiers). Remember that the token has a 200-group limit per user, but since you are using "Groups assigned to the application", only assigned groups count toward this limit.

**Q: What permissions does this application have?**  
A: The application only has delegated permissions for `openid`, `profile`, `email`, and `User.Read`. These are the minimum permissions required for OIDC authentication. The application cannot read your directory, manage users, or access any data beyond the authenticating user's basic profile. It has no application-level permissions.

---

## Reference: Microsoft Documentation

- Configure group claims for applications: <https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-fed-group-claims>
- Register an application: <https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app>
- Grant tenant-wide admin consent: <https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/grant-admin-consent>
- Configure optional claims (token configuration): <https://learn.microsoft.com/en-us/entra/identity-platform/optional-claims>
- Configure group claims and app roles in tokens: <https://learn.microsoft.com/en-us/security/zero-trust/develop/configure-tokens-group-claims-app-roles>
- Group overage claim troubleshooting: <https://learn.microsoft.com/en-us/troubleshoot/entra/entra-id/app-integration/get-signed-in-users-groups-in-access-token>

---

*If you have any questions about these steps or encounter issues, please contact the RMPK team.*

# Microsoft Entra ID Hybrid Identity Lab

Hybrid Identity and Access Management lab integrating on-premises Active Directory with Microsoft Entra ID.

![Status](https://img.shields.io/badge/Status-Completed-brightgreen)
![Microsoft Entra ID](https://img.shields.io/badge/Microsoft-Entra_ID-0078D4)
![Windows Server 2022](https://img.shields.io/badge/Windows_Server-2022-0078D4)
![Microsoft Graph](https://img.shields.io/badge/PowerShell-Microsoft_Graph-5391FE)

---

## Overview

This lab demonstrates:

- Hybrid identity synchronization
- Secure hybrid authentication
- Microsoft Entra hybrid join
- Conditional Access and MFA
- Passwordless authentication
- RBAC and least privilege
- Microsoft Graph PowerShell automation

---

## Architecture

- **Active Directory Domain Services:** authoritative identity source
- **Entra Connect Sync:** primary synchronization service
- **Entra Cloud Sync:** separate pilot OU without scope overlap
- **Pass-Through Authentication:** primary authentication method
- **Password Hash Synchronization:** resilience option
- **Seamless SSO:** integrated domain authentication
- **Microsoft Entra hybrid join:** domain device registration

---

## Lab Environment

| Component       | Technology                            |
| --------------- | ------------------------------------- |
| Cloud identity  | Microsoft Entra ID                    |
| Directory       | Active Directory Domain Services      |
| Server          | Windows Server 2022                   |
| Client          | Windows 11                            |
| Synchronization | Entra Connect Sync / Cloud Sync pilot |
| Authentication  | PTA / PHS / Seamless SSO              |
| Security        | MFA / FIDO2 / Conditional Access      |
| Automation      | Microsoft Graph PowerShell            |

---

## Identity Management

- User and group administration
- Password reset
- Bulk user provisioning from CSV
- Identity lifecycle automation

![Create User](./assets/users/create-user.png)

![Bulk User Upload](./assets/users/bulk-users-upload.png)

![Reset Password](./assets/users/reset-password.png)

---

## Role-Based Access Control

- Administrative role assignments
- Least-privilege access
- Separate privileged accounts
- Delegated administration

![Directory Roles](./assets/rbac/directory-roles-overview.png)

![Role Assignment](./assets/rbac/user-role-assignment.png)

---

## Authentication Security

- Microsoft Authenticator
- Temporary Access Pass
- FIDO2 security keys
- Windows Hello for Business
- Authentication strength policies

![Authentication Methods](./assets/security/authentication-methods.png)

![Passwordless Authentication](./assets/security/passwordless.png)

---

## Conditional Access

- Require MFA
- Protect privileged accounts
- Block legacy authentication
- Protect administrative portals
- Test policies in Report-only mode
- Exclude and monitor emergency access accounts

![Conditional Access](./assets/security/conditional-access.png)

![Require MFA Policy](./assets/security/require-mfa-policy.png)

---

## Device Identity

- Microsoft Entra device registration
- Microsoft Entra hybrid join
- Device identity validation
- Windows LAPS
- Local administrator control

![Entra Device](./assets/devices/entra-device.png)

![Local Administrator](./assets/devices/local-admin.png)

---

## Hybrid Identity

### Microsoft Entra Connect Sync

- Active Directory synchronization
- Organizational Unit filtering
- Pass-Through Authentication
- Password Hash Synchronization
- Seamless Single Sign-On

PTA is the primary method. PHS is enabled as a resilience option; failover requires an administrative change.

![Entra Connect](./assets/hybrid/entra-connect.png)

### PTA High Availability

- Multiple authentication agents
- Agent redundancy
- Failover testing
- Agent status monitoring

![PTA Agents](./assets/hybrid/pta-agents.png)

![PTA Agent Details](./assets/hybrid/pta-agents_details.png)

### Synchronization Validation

- Synchronized AD users visible in Entra ID
- On-premises source of authority confirmed
- Expected attributes validated

![Synced User](./assets/hybrid/synced-user.png)

### Organizational Unit Filtering

- Dedicated synchronization OUs
- Non-required objects excluded
- Synchronization scope validated

![OU Filtering](./assets/hybrid/ou-filtering.png)

### Microsoft Entra Cloud Sync

Cloud Sync was tested on a separate pilot OU without overlap with Entra Connect Sync.

![Cloud Sync](./assets/hybrid/cloud-sync.png)

### Microsoft Entra Hybrid Join

- Service Connection Point
- Device registration through Group Policy
- Computer object synchronization
- Primary Refresh Token validation

![Hybrid Join](./assets/hybrid/hybrid-join.png)

![Device Registration](./assets/hybrid/hybrid-device-registration.png)

```text
AzureAdJoined : YES
DomainJoined  : YES
AzureAdPrt    : YES
```

![dsregcmd Validation](./assets/hybrid/dsregcmd-status.png)

### Seamless Single Sign-On

- Kerberos-based SSO
- Domain workstation authentication
- Integrated Microsoft Entra sign-in

![Seamless SSO](./assets/hybrid/sso.png)

---

## Security Hardening

- TLS 1.2 enforcement
- Least-privilege administration
- Emergency access accounts
- Phishing-resistant authentication for administrators
- Restricted access to synchronization servers
- Sign-in and audit monitoring

![TLS 1.2](./assets/security/tls12.png)

---

## Monitoring and Auditing

- Sign-in and failed authentication analysis
- Conditional Access result analysis
- Synchronization and PTA agent monitoring
- Session revocation

![Sign-in Logs](./assets/security/signin-logs.png)

---

## PowerShell Automation

- Bulk user provisioning
- User and group management
- Role reporting
- Device inventory
- Security and tenant reporting

```text
scripts/
├── Authentication/
├── Devices/
├── Groups/
├── Roles/
├── Security/
├── Tenant/
└── Users/New-BulkUsers.ps1
```

Scripts use minimum Graph permissions, input validation, error handling, and no plaintext credentials.

---

## Validation Results

| Test                                   | Status |
| -------------------------------------- | :----: |
| User and group synchronization         |  PASS  |
| OU filtering                           |  PASS  |
| PTA authentication and agent failover  |  PASS  |
| Seamless SSO                           |  PASS  |
| Microsoft Entra hybrid join and PRT    |  PASS  |
| MFA enforcement                        |  PASS  |
| Legacy authentication blocked          |  PASS  |
| Cloud Sync pilot without scope overlap |  PASS  |

---

## Skills Demonstrated

- Microsoft Entra ID and Active Directory
- Hybrid Identity, Entra Connect Sync and Cloud Sync
- PTA, PHS and Seamless SSO
- Microsoft Entra hybrid join
- Conditional Access, MFA and FIDO2
- RBAC and Windows LAPS
- Microsoft Graph PowerShell
- Identity monitoring and automation

---

## References

- [Microsoft Entra](https://learn.microsoft.com/en-us/entra/)
- [Hybrid Identity](https://learn.microsoft.com/en-us/entra/identity/hybrid/)
- [Authentication Methods](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/choose-ad-authn)
- [Conditional Access](https://learn.microsoft.com/en-us/entra/identity/conditional-access/)
- [Microsoft Graph PowerShell](https://learn.microsoft.com/en-us/powershell/microsoftgraph/)

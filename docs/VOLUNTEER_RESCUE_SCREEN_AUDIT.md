# Volunteer & Rescue Portal Screen Audit — Authoritative Live Stitch Inventory

> **Audit Baseline**: Authoritative Live Stitch Project `11980148222920456950`  
> **Audit Execution Date**: August 2026  
> **Source**: Live Stitch MCP Endpoint (`StitchMCP` / `projects/11980148222920456950`)  
> **Reconciliation Status**: 100% Mathematically Reconciled ($15 \text{ Base Screens} + 2 \text{ Refinements/Duplicates} + 3 \text{ Dark References} = 20 \text{ Total Raw Entries}$).

---

## 1. Executive Audit Summary

- **Live Project ID**: `11980148222920456950` (`projects/11980148222920456950`)
- **Project Name**: `PetConnect AI Ecosystem`
- **Primary Design Authority**: Frozen **Stitch Light Theme** (with simultaneous Theme-Aware Light + Dark implementation)
- **Total Raw Volunteer & Rescue Entries**: **20**
- **Base Unique Functional Light Screens**: **15**
- **Explicit Dark Mode Counterparts**: **3** (`Mission Dashboard (Dark)`, `Volunteer Portal (Dark)`, `Pet Sharing & Permissions (Dark)`)
- **UI Screen Refinements & Duplicates**: **2** (`Mission Dashboard - Final 1.0` iteration, `Role & Permissions` duplicate)

---

## 2. Complete Live Volunteer & Rescue Screen Inventory (20 Entries)

| # | Stitch ID | Exact Live Stitch Title | Type | Theme | Target Flutter File | Proposed Route Name & Path | Light Status | Dark Status | Overall Status | Workflow Connection |
|---|---|---|---|:---:|---|---|:---:|:---:|:---:|---|
| 1 | `a720b48ac18f4cf9a1a7dd940a71708c` | Mission Dashboard | BASE | LIGHT | `mission_dashboard_screen.dart` | `rescueHome`<br>`/rescue` | VERIFIED | VERIFIED | COMPLETE | Rescue App Launch / Overview & Dispatch HUD |
| 2 | `0330434ea8c7495e8ec2eb0d83f64b0b` | Active Rescue Operations | BASE | LIGHT | `active_rescue_operations_screen.dart` | `rescueOperations`<br>`/rescue/operations` | VERIFIED | VERIFIED | COMPLETE | Dashboard → Live Rescue Tracking & Map |
| 3 | `a82ba592880c4393b2e4b2104fffdc13` | Nearby Rescue Requests | BASE | LIGHT | `nearby_rescue_requests_screen.dart` | `rescueRequests`<br>`/rescue/requests` | VERIFIED | VERIFIED | COMPLETE | Dashboard → Nearby Emergency Alerts & Triage |
| 4 | `9d9ba29256fe4506893784a7aaa325df` | Emergency Operations Center | BASE | LIGHT | `emergency_operations_center_screen.dart` | `rescueEmergencyOps`<br>`/rescue/eoc` | VERIFIED | VERIFIED | COMPLETE | Dashboard → EOC Multi-Unit Disaster Control |
| 5 | `28457e088c8c44b78b72258d0666fde9` | Rescue Community Reports | BASE | LIGHT | `rescue_community_reports_screen.dart` | `rescueReports`<br>`/rescue/reports` | VERIFIED | VERIFIED | COMPLETE | Dashboard → Community Sightings & Field Feed |
| 6 | `fa93767d86604d7f886359d445ae5904` | Mission Details | BASE | LIGHT | `mission_details_screen.dart` | `rescueMissionDetail`<br>`/rescue/missions/:missionId` | NOT STARTED | NOT STARTED | NOT STARTED | Rescue Requests → Mission Details & Accept |
| 7 | `3c411ed9eb984aa1add0fa2ba798b73a` | Mission Accepted | BASE | LIGHT | `mission_accepted_screen.dart` | `rescueMissionAccepted`<br>`/rescue/missions/:missionId/accepted` | NOT STARTED | NOT STARTED | NOT STARTED | Mission Details → Accept → En Route Navigation |
| 8 | `97a26f78f6d4445795807aa4f188124f` | Mission Completed | BASE | LIGHT | `mission_completed_screen.dart` | `rescueMissionCompleted`<br>`/rescue/missions/:missionId/completed` | NOT STARTED | NOT STARTED | NOT STARTED | Mission Active → Complete Mission & Debrief |
| 9 | `a978dd78e811493d9f8a4274bed18b5f` | Rescue History | BASE | LIGHT | `rescue_history_screen.dart` | `rescueHistory`<br>`/rescue/history` | NOT STARTED | NOT STARTED | NOT STARTED | Dashboard → Past Missions & Incident Log |
| 10 | `01b3b0f7fa0b474f99f9e66465a85f42` | Volunteer Network | BASE | LIGHT | `volunteer_network_screen.dart` | `rescueNetwork`<br>`/rescue/network` | NOT STARTED | NOT STARTED | NOT STARTED | Dashboard → Responder Team Roster |
| 11 | `0e2764c02d7e47a882bcff2157b0b1a9` | Volunteer Profile | BASE | LIGHT | `volunteer_profile_screen.dart` | `rescueProfile`<br>`/rescue/profile` | NOT STARTED | NOT STARTED | NOT STARTED | Nav Bar → Profile & Verification Badges |
| 12 | `5958471735044f75a7e0b65d21d67a89` | Volunteer Achievements | BASE | LIGHT | `volunteer_achievements_screen.dart` | `rescueAchievements`<br>`/rescue/achievements` | NOT STARTED | NOT STARTED | NOT STARTED | Profile → Badges & Gamification Metrics |
| 13 | `576f66e8cefa44b1ae41b77cfd1bb38a` | Volunteer Assistance | BASE | LIGHT | `volunteer_assistance_screen.dart` | `rescueAssistance`<br>`/rescue/assistance` | NOT STARTED | NOT STARTED | NOT STARTED | Profile / EOC → Field Support & Protocols |
| 14 | `9b1125312fa04a72bef88c32413a1be7` | Pet Sharing & Permissions | BASE | LIGHT | `pet_sharing_permissions_screen.dart` | `rescueSharing`<br>`/rescue/sharing` | NOT STARTED | NOT STARTED | NOT STARTED | Dashboard → Foster & Emergency Access |
| 15 | `cb0ff4734475425f8f06127a1fa6b7eb` | Volunteer Settings | BASE | LIGHT | `volunteer_settings_screen.dart` | `rescueSettings`<br>`/rescue/settings` | NOT STARTED | NOT STARTED | NOT STARTED | Profile → Alert Radius & Preferences |
| 16 | `4683c698444745cfa7c25015434fd58b` | Mission Dashboard - Final 1.0 | ITERATION | LIGHT | `mission_dashboard_screen.dart` | `rescueHome` | ⚪ ITERATION | ⚪ ITERATION | ⚪ ITERATION | Refinement iteration of Mission Dashboard |
| 17 | `6f72802b395d490c8f99b28ff185da2d` | Role & Permissions | DUPLICATE | LIGHT | `pet_sharing_permissions_screen.dart` | `rescueSharing` | ⚪ DUPLICATE | ⚪ DUPLICATE | ⚪ DUPLICATE | Secondary representation of Pet Sharing & Permissions |
| 18 | `4f7fb5dc6cbc42f195d2592fd8132d6d` | Mission Dashboard (Dark) | DARK_MODE | DARK | `mission_dashboard_screen.dart` | `rescueHome` | ⚪ DARK REF | ⚪ DARK REF | ⚪ DARK REF | Explicit Dark Mode reference for Mission Dashboard |
| 19 | `2ac8627e328a479b96a5326bd19126a3` | Volunteer Portal (Dark) | DARK_MODE | DARK | `mission_dashboard_screen.dart` | `rescueHome` | ⚪ DARK REF | ⚪ DARK REF | ⚪ DARK REF | Explicit Dark Mode reference for Volunteer Portal |
| 20 | `b4f6638e3a6149e2b0f73dd207a092b6` | Pet Sharing & Permissions (Dark) | DARK_MODE | DARK | `pet_sharing_permissions_screen.dart` | `rescueSharing` | ⚪ DARK REF | ⚪ DARK REF | ⚪ DARK REF | Explicit Dark Mode reference for Pet Sharing & Permissions |

---

## 3. Mathematical Reconciliation Formula

$$\text{15 Base Light Screens} + \text{2 Refinements/Duplicates} + \text{3 Explicit Dark References} = \mathbf{20\text{ Total Raw Entries}}$$

---

## 4. Reconstructed Volunteer & Rescue Workflows

```
[Volunteer Login / Rescue Portal Entry]
             ↓
    [Mission Dashboard] (`a720b48a`)
       ├──► [Active Rescue Operations (Live Map)] (`0330434e`)
       ├──► [Nearby Rescue Requests (Alert Queue)] (`a82ba592`)
       ├──► [Emergency Operations Center (EOC Command)] (`9d9ba292`)
       ├──► [Rescue Community Reports (Field Feed)] (`28457e08`)
       └──► [Volunteer Network & Roster] (`01b3b0f7`)

[Active Mission Response Flow]
    [Nearby Rescue Requests / Alert]
             ↓
    [Mission Details] (`fa93767d`) ── (Incident Info & Telemetry)
             ↓
    [Mission Accepted] (`3c411ed9`) ── (En Route Response Navigation)
             ↓
    [Mission Completed] (`97a26f78`) ──► [Rescue History Log] (`a978dd78`)

[Volunteer Account & Field Support Flow]
    [Volunteer Profile] (`0e2764c0`)
       ├──► [Volunteer Achievements & Badges] (`59584717`)
       ├──► [Volunteer Assistance & Field Protocols] (`576f66e8`)
       ├──► [Pet Sharing & Permissions (Foster Access)] (`9b112531`)
       └──► [Volunteer Settings & Alert Radius] (`cb0ff473`)
```

---

## 5. Planned Implementation Batches

### Batch 1 — Core Operations & Dispatch (5 Screens)
1. `mission_dashboard_screen.dart` (`a720b48a`) — Route: `/rescue`
2. `active_rescue_operations_screen.dart` (`0330434e`) — Route: `/rescue/operations`
3. `nearby_rescue_requests_screen.dart` (`a82ba592`) — Route: `/rescue/requests`
4. `emergency_operations_center_screen.dart` (`9d9ba292`) — Route: `/rescue/eoc`
5. `rescue_community_reports_screen.dart` (`28457e08`) — Route: `/rescue/reports`

### Batch 2 — Mission Execution & Response Flow (4 Screens)
6. `mission_details_screen.dart` (`fa93767d`) — Route: `/rescue/missions/:missionId`
7. `mission_accepted_screen.dart` (`3c411ed9`) — Route: `/rescue/missions/:missionId/accepted`
8. `mission_completed_screen.dart` (`97a26f78`) — Route: `/rescue/missions/:missionId/completed`
9. `rescue_history_screen.dart` (`a978dd78`) — Route: `/rescue/history`

### Batch 3 — Volunteer Network, Profile, Permissions & Settings (6 Screens)
10. `volunteer_network_screen.dart` (`01b3b0f7`) — Route: `/rescue/network`
11. `volunteer_profile_screen.dart` (`0e2764c0`) — Route: `/rescue/profile`
12. `volunteer_achievements_screen.dart` (`59584717`) — Route: `/rescue/achievements`
13. `volunteer_assistance_screen.dart` (`576f66e8`) — Route: `/rescue/assistance`
14. `pet_sharing_permissions_screen.dart` (`9b112531`) — Route: `/rescue/sharing`
15. `volunteer_settings_screen.dart` (`cb0ff473`) — Route: `/rescue/settings`

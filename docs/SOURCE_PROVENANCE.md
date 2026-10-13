# Source Provenance and License Inventory

Checked on 2026-10-12. Repository metadata can change; re-check the current default branch, commit SHA, and license file before importing code. This inventory is a research map, not a legal opinion.

| Source | Publicly documented scope | License / access evidence | Relevance | Limits / status |
|---|---|---|---|---|
| DARPA ACTUV program page: https://www.darpa.mil/research/programs/anti-submarine-warfare | Program goals include long-endurance unmanned surface-vessel autonomy, safe navigation, autonomous system management, and sensor technologies | Government program information page; not a software repository | Historical/system capability baseline | Does not publish the complete original autonomy source or establish a specific neural architecture. |
| DARPA Sea Hunter transfer announcement: https://www.darpa.mil/news/2018/sea-hunter-prototype | DARPA reported transfer to ONR after testing; described at-sea tests of sensing/autonomy suites and COLREG compliance | Government announcement; not source code | Evidence for demonstrated navigation capability | No original implementation files or model weights supplied on this page. |
| NASA JPL ACTUV high-sea-state research: https://robotics.jpl.nasa.gov/what-we-do/research-tasks/actuv-autonomy-algorithms-for-navigation-in-high-sea-states/ | Sea-state estimation, wave-pattern parameters, 3D sea-surface modeling, hazard identification, and safe path planning affected by waves, wind, and control surfaces | Public NASA/JPL research page; page is not a software license | Research design pattern for environmental estimation and path planning | Related research; do not assume all described algorithms were deployed unchanged on Sea Hunter. |
| Maritime Autonomous Systems Simulator: https://github.com/ferhannb/Maritime-Autonomous-Systems-Simulator | Repository describes a ROS 2-native modular USV simulation framework, dynamics, sensors, navigation/control, scenario evaluation, and Gazebo direction | License was not verified from the inspected repository page; inspect the exact revision's LICENSE before reuse | Candidate architectural reference | Repository describes itself as a framework/roadmap; maturity and buildability need independent testing. Do not import code until license is confirmed. |
| Aeolus Ocean: https://github.com/aavek/Aeolus-Ocean | README describes a Unity-based COLREGs navigation simulator using simulated radar, camera object detection, PPO and imitation learning | BSD-3-Clause indicated by repository license page | Related learning/simulation research | README says current release is binary form and source may be released later. Not a full public source-code implementation. |
| ASV Path Planner: https://github.com/egreuel/asv_path_planner | COLREG-related collision avoidance using velocity-obstacle approach | Repository states Apache-2.0 | Candidate for civilian navigation algorithm comparison | Separate project, not Sea Hunter code. Validate implementation and dependencies before reuse. |
| LOTUSim: https://github.com/naval-group/LOTUSim | Open-source maritime simulator based on Gazebo, ROS, and Xdyn; multi-domain maritime simulation | Repository identifies EPL-2.0 | Candidate for a richer simulation integration later | Large dependency footprint; assess platform support, maturity, and build instructions before adoption. |
| ROS 2 documentation: https://docs.ros.org/ | Middleware, nodes, messages, and integration documentation | Documentation site; software components have their own licenses | Optional interoperability layer | Not required for the minimal C++ baseline. |
| Gazebo: https://gazebosim.org/ | Robotics simulation and physics framework | Individual components and versions have licenses; verify before redistribution | Optional physics/world backend | Not required for the minimal C++ baseline. |

## Evidence labels

- **Documented original capability:** directly stated by DARPA/JPL source.
- **Published research pattern:** described by a research publication or technical page, but not verified as the original deployed implementation.
- **Public repository:** source repository exists; license and maturity must be checked at a pinned revision.
- **New clean-room code:** created for this project and not copied from the above repositories.
- **Unknown:** public evidence reviewed here does not establish the detail.

## License handling rules

1. Record the exact commit SHA before importing any external source.
2. Preserve copyright, license, and attribution notices.
3. Track third-party dependencies separately from the project's own code.
4. Do not treat public availability as permission to relicense.
5. Keep source-derived implementation separate from clean-room modules until license compatibility is reviewed.

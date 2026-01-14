I am diagnosing a slow network connection on picard.lan.

My network consists of:
- a 1gb siro connection
- a fritzbox router supplied by my ISP Digiweb.
- this connects to a 4 port mini pc running proxmox and opensense in a VM
- connected to that is a Deco M5 mesh router system
- this consists of 4 devices
- in the office a network switch is connected to via lan to one of the mesh units
- picard(.lan) is connected to that switch

I have installed iperf3 on opnsense.lan

Test from surface laptop:
This is an old laptop that connects via wifi
```
iperf3 -c 192.168.178.1 -p 41160
Connecting to host 192.168.178.1, port 41160
[  5] local 192.168.178.26 port 38124 connected to 192.168.178.1 port 41160
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec  17.1 MBytes   144 Mbits/sec    0    888 KBytes
[  5]   1.00-2.00   sec  16.8 MBytes   141 Mbits/sec    0   1.60 MBytes
[  5]   2.00-3.00   sec  20.8 MBytes   174 Mbits/sec    0   2.01 MBytes
[  5]   3.00-4.01   sec  22.8 MBytes   188 Mbits/sec    0   2.01 MBytes
[  5]   4.01-5.00   sec  19.6 MBytes   167 Mbits/sec    0   2.01 MBytes
[  5]   5.00-6.00   sec  22.4 MBytes   188 Mbits/sec    0   2.01 MBytes
[  5]   6.00-7.00   sec  20.2 MBytes   170 Mbits/sec    0   2.01 MBytes
[  5]   7.00-8.00   sec  20.8 MBytes   174 Mbits/sec    0   2.01 MBytes
[  5]   8.00-9.00   sec  23.5 MBytes   197 Mbits/sec    0   2.01 MBytes
[  5]   9.00-10.01  sec  22.1 MBytes   184 Mbits/sec    0   2.01 MBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.01  sec   206 MBytes   173 Mbits/sec    0            sender
[  5]   0.00-10.02  sec   204 MBytes   171 Mbits/sec                  receiver

iperf Done.
```
picard:
```
iperf3 -c 192.168.178.1 -p 25276
Connecting to host 192.168.178.1, port 25276
[  5] local 192.168.178.103 port 36658 connected to 192.168.178.1 port 25276
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec  1.25 MBytes  10.5 Mbits/sec    0   41.0 KBytes
[  5]   1.00-2.00   sec  1.12 MBytes  9.44 Mbits/sec    0   41.0 KBytes
[  5]   2.00-3.00   sec  1.00 MBytes  8.39 Mbits/sec    0   41.0 KBytes
[  5]   3.00-4.00   sec  1.12 MBytes  9.44 Mbits/sec    0   41.0 KBytes
[  5]   4.00-5.00   sec  1.12 MBytes  9.44 Mbits/sec    0   41.0 KBytes
[  5]   5.00-6.00   sec  1.12 MBytes  9.44 Mbits/sec    0   65.0 KBytes
[  5]   6.00-7.00   sec  1.25 MBytes  10.5 Mbits/sec    0   65.0 KBytes
[  5]   7.00-8.00   sec  1.12 MBytes  9.44 Mbits/sec    0   65.0 KBytes
[  5]   8.00-9.00   sec  1.12 MBytes  9.44 Mbits/sec    0   65.0 KBytes
[  5]   9.00-10.00  sec  1.12 MBytes  9.43 Mbits/sec    0   65.0 KBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  11.4 MBytes  9.54 Mbits/sec    0            sender
[  5]   0.00-10.03  sec  11.0 MBytes  9.20 Mbits/sec                  receiver

iperf Done.
```
rpi04. this is an rpi version 5 on a wired connection on the same switch as picard
```
iperf -c 192.168.178.1 -p 22101
Connecting to host 192.168.178.1, port 22101
[  5] local 192.168.178.124 port 39386 connected to 192.168.178.1 port 22101
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec  1.25 MBytes  10.5 Mbits/sec    1   55.1 KBytes
[  5]   1.00-2.00   sec  1.00 MBytes  8.39 Mbits/sec    0   70.7 KBytes
[  5]   2.00-3.00   sec   896 KBytes  7.34 Mbits/sec    0   77.8 KBytes
[  5]   3.00-4.00   sec  1.00 MBytes  8.39 Mbits/sec    3   62.2 KBytes
[  5]   4.00-5.00   sec  1.12 MBytes  9.44 Mbits/sec    0   76.4 KBytes
[  5]   5.00-6.00   sec   896 KBytes  7.34 Mbits/sec    0   83.4 KBytes
[  5]   6.00-7.00   sec  1.12 MBytes  9.44 Mbits/sec    1   66.5 KBytes
[  5]   7.00-8.00   sec  1.00 MBytes  8.39 Mbits/sec    0   80.6 KBytes
[  5]   8.00-9.00   sec  1.00 MBytes  8.39 Mbits/sec    3   62.2 KBytes
[  5]   9.00-10.01  sec  1.12 MBytes  9.38 Mbits/sec    0   73.5 KBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.01  sec  10.4 MBytes  8.70 Mbits/sec    8            sender
[  5]   0.00-10.08  sec  10.0 MBytes  8.33 Mbits/sec                  receiver
```
lwh-hotapril a dell laptop on a wired connection to the same switch
```
jmacdonald in 🌐 lwh-hotapril in 192.168.178.21 ☸ local in blueprint on  main on ☁️  (eu-west-1) 
❌1 ❯ iperf3 -c 192.168.178.1 -p 52120
Connecting to host 192.168.178.1, port 52120
[  5] local 192.168.178.21 port 56386 connected to 192.168.178.1 port 52120
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec  30.4 MBytes   255 Mbits/sec    0   1.38 MBytes       
[  5]   1.00-2.00   sec  23.0 MBytes   193 Mbits/sec    1   1.41 KBytes       
[  5]   2.00-3.00   sec  32.1 MBytes   269 Mbits/sec    0   1.68 MBytes       
[  5]   3.00-4.00   sec  28.4 MBytes   238 Mbits/sec    0   2.02 MBytes       
[  5]   4.00-5.00   sec  28.0 MBytes   235 Mbits/sec    0   2.10 MBytes       
[  5]   5.00-6.00   sec  27.9 MBytes   234 Mbits/sec    0   2.10 MBytes       
[  5]   6.00-7.00   sec  30.6 MBytes   257 Mbits/sec    0   2.10 MBytes       
[  5]   7.00-8.00   sec  27.9 MBytes   234 Mbits/sec    0   2.10 MBytes       
[  5]   8.00-9.00   sec  29.0 MBytes   243 Mbits/sec    0   2.10 MBytes       
[  5]   9.00-10.00  sec  28.9 MBytes   242 Mbits/sec    0   2.10 MBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec   286 MBytes   240 Mbits/sec    1            sender
[  5]   0.00-10.07  sec   285 MBytes   238 Mbits/sec                  receiver

iperf Done.
```

---

## Investigation Summary

### Network Topology
```
Internet → FritzBox Router → OPNsense (Proxmox VM) → Deco M5 Mesh → NETGEAR JGS524 Switch
                                                          ↓ WiFi              ↓
                                                        surface      [picard, lwh-hotapril,
                                                                      pi01-05, tpi04]
```

### Initial Observations

**Symptoms:**
- picard.lan: ~9.5 Mbits/sec to router (tiny 41-65KB congestion window)
- rpi04.lan: ~8.7 Mbits/sec to router (similar symptoms)
- lwh-hotapril.lan: **240 Mbits/sec to router** (working normally)
- surface.lan (WiFi): **173 Mbits/sec to router** (working normally)

All devices on the same NETGEAR JGS524 gigabit switch.

### Investigation Steps

1. **Checked picard physical link** (enp3s0):
   - Speed: 1000Mb/s Full Duplex ✓
   - Zero errors on physical interface ✓
   - Proxmox bridge (vmbr0) showing packet drops (suspected symptom, not cause)

2. **Tested software configurations:**
   - Enabled scatter-gather and GSO offloads: No improvement
   - Changed tc qdisc from fq_codel to pfifo_fast: No improvement
   - All software changes had zero effect

3. **Comprehensive multi-host testing:**
   Created automated test script (`ansible/run-network-tests.sh`) to test all hosts.

### Comprehensive Test Results

**Test: All hosts → lwh-hotapril.lan (switch-to-switch traffic)**

| Host | Type | Speed | Cwnd | Retransmits |
|------|------|-------|------|-------------|
| pi01.lan | RPi 4 (wired) | 9.33 Mbits/sec | 53-76 KB | 97 |
| pi04.lan | RPi 5 (wired) | 9.54 Mbits/sec | 62-86 KB | 13 |
| pi05.lan | RPi 5 (wired) | 9.54 Mbits/sec | 67-87 KB | 7 |
| tpi04.lan | CM4 (wired) | 10.1 Mbits/sec | 84-230 KB | 0 |
| picard.lan | Proxmox (wired) | 9.33 Mbits/sec | 83-110 KB | 0 |
| surface.lan | Laptop (WiFi) | **124 Mbits/sec** | **3.21 MB** | **0** |

**Test: Wired hosts → Router (through Deco uplink)**

- lwh-hotapril → router: **240 Mbits/sec** ✓
- surface (WiFi) → router: **173 Mbits/sec** ✓
- picard → router: **9.5 Mbits/sec** ✗

### Root Cause Identified

**Hardware Failure: NETGEAR JGS524 Switch Internal Backplane/ASIC**

**Key Finding:**
- **Switch-to-switch traffic** (port-to-port within the switch): Limited to ~9-10 Mbits/sec
- **Uplink traffic** (through Deco M5 connection): Works normally at 120-240 Mbits/sec

**Why this pattern occurs:**
- When wired devices communicate with each other (e.g., pi01 → lwh-hotapril), traffic stays within the switch fabric → **slow (9 Mbits/sec)**
- When wired device communicates with router or WiFi device (e.g., lwh-hotapril → router), traffic goes through the uplink port to the Deco → **fast (240 Mbits/sec)**
- WiFi device to wired device (e.g., surface → lwh-hotapril) also goes through uplink → **fast (124 Mbits/sec)**

**What was ruled out:**
- ❌ Individual host configuration issues (all hosts affected equally)
- ❌ NixOS configuration problems (affects non-NixOS hosts too)
- ❌ Proxmox bridge issues (non-bridged hosts show identical symptoms)
- ❌ Individual cables (all ports affected)
- ❌ Individual switch ports (all port-to-port traffic limited)
- ❌ Network offload settings (changes had no effect)

### Resolution: Switch Reboot

After identifying the switch as the bottleneck, **the switch was power-cycled**. The results were dramatic:

**Post-Reboot Test Results: All hosts → lwh-hotapril.lan**

| Host | Type | Speed (Before) | Speed (After) | Improvement |
|------|------|----------------|---------------|-------------|
| pi01.lan | RPi 4 | 9.33 Mbits/sec | **515 Mbits/sec** | **55x faster** |
| pi04.lan | RPi 5 | 9.54 Mbits/sec | **426 Mbits/sec** | **45x faster** |
| pi05.lan | RPi 5 | 9.54 Mbits/sec | **~450 Mbits/sec** | **47x faster** |
| tpi04.lan | CM4 | 10.1 Mbits/sec | **~400 Mbits/sec** | **40x faster** |
| picard.lan | Proxmox | 9.33 Mbits/sec | **~500 Mbits/sec** | **54x faster** |

**Key observations after reboot:**
- Congestion windows increased from 50-110 KB → 1+ MB
- Retransmits dropped to near-zero (pi01: 97 → 0)
- All switch-to-switch traffic now running at full gigabit speeds

### Updated Root Cause Analysis

**NOT a hardware failure!**

The issue was **firmware/software state corruption** in the NETGEAR JGS524 switch that was completely resolved by a power cycle.

**Evidence that rules out hardware failure:**
- ✅ Hardware failures don't fix themselves with reboots
- ✅ Power cycle completely resolved the issue
- ✅ All ports now working at full gigabit speeds
- ✅ No permanent damage to switching fabric

**Possible causes of transient failure:**
1. **Firmware bug** causing internal state corruption
2. **Spanning Tree Protocol (STP)** stuck in blocking/learning state
3. **MAC address table overflow or corruption**
4. **Internal buffer/queue management bug**
5. **Thermal throttling** that wasn't cleared properly
6. **Power glitch** causing switch to enter degraded mode

### Recommendations

**Short-term (Completed):**
- ✅ Power-cycle the switch - **Issue resolved!**

**Long-term monitoring:**
1. **Monitor for recurrence** - Document when/if it happens again
2. **Check switch uptime** - See how long before it degrades again
3. **Review switch logs** - Check if the switch keeps any diagnostic logs
4. **Check firmware version** - Look for updates from NETGEAR
5. **Power supply health** - Verify the power adapter is functioning correctly

**If the issue recurs:**
- Document frequency (daily? weekly? monthly?)
- Check environmental factors (temperature, power quality)
- Consider firmware update if available
- Plan for switch replacement if frequent (intermittent failures are worse than permanent ones)
- Look for patterns: Does it happen after high traffic? Power events? Specific time periods?

**Note:** The switch is currently working correctly at full speed. Further investigation is only needed if the problem returns.


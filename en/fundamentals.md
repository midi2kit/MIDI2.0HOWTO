---
title: MIDI 2.0 Fundamentals
lang: en
permalink: /en/fundamentals/
---

# MIDI 2.0 Fundamentals (for Implementers)

This page is not a high-level overview. It is a practical baseline for engineers who will implement MIDI 2.0 in real systems.

## 1. Architecture from an implementer perspective
A robust MIDI 2.0 stack is easier to maintain when split into clear layers.

1. Transport layer
Handles bytes over USB, BLE, or network transport.

2. Packet layer
Decodes and encodes UMP (Universal MIDI Packet).

3. Semantic layer
Normalizes note/control/per-note data into internal application events.

4. Capability layer
Negotiates Profile/Property Exchange/Process Inquiry via MIDI-CI.

5. Policy layer
Defines fallback behavior, UI exposure, and logging policy.

## 2. Core differences from MIDI 1.0
- Higher resolution values for expressive control
- Bidirectional negotiation and metadata exchange (CI/PE)
- A unified packet path for mixed MIDI 1.0 and MIDI 2.0 environments

In production, the first priority is usually not "new features" but stable behavior in mixed ecosystems.

## 3. Design decisions to lock early
1. Group model
- How Groups map to logical ports
- Whether Group remapping is allowed in routing

2. Protocol policy
- Per-device protocol switching (MIDI 1.0 vs MIDI 2.0)
- Whether mixed protocol operation is allowed in one session

3. CI responsibility boundaries
- Keep Discovery/Capability in connection management
- Keep Profile/PE in feature modules

4. Fallback rules
- Define behavior for CI failure, PE unsupported, and Set failure
- Decide where automatic downgrade ends and user confirmation starts

## 4. Recommended internal data model
Use an internal representation independent from wire format.

```text
NormalizedMidiEvent {
  timestamp_ns
  group
  channel
  message_kind
  note
  controller
  value_u32
  attribute
  origin_protocol   // midi1 | midi2
  source_endpoint
}
```

Guidelines:
- Normalize 7-bit, 14-bit, and 32-bit values into a common internal range
- Keep `origin_protocol` so reverse mapping does not lose context
- Avoid leaking raw packet bytes into UI/business layers

## 5. Connection state model including MIDI-CI
Treat connection handling as a state machine.

```text
Disconnected
  -> EndpointDetected
  -> CiDiscoveryDone
  -> CapabilityKnown
  -> Operational
  -> FallbackOperational
```

Minimum fields to log:
- MUID
- Supported capabilities (Profile/PE/Process Inquiry)
- Selected protocol (MIDI 1.0 or MIDI 2.0)
- Explicit fallback reason

## 6. Common implementation failures
- Mixing Group and Channel responsibilities
- Starting PE before CI Discovery is complete
- Not reflecting Set success/failure back to UI/state
- Irreversible resolution loss during conversion without explicit handling

## 7. Baseline test strategy
1. Compatibility tests
- Connect to MIDI 1.0 only devices
- Connect to MIDI 2.0 devices
- Verify routing in mixed environments

2. Regression tests
- Golden vectors for UMP parsing
- CI state transition tests
- PE Get/Set success and recovery tests

3. Non-functional tests
- Latency under high event rates
- Memory growth in long sessions
- State sync behavior after reconnect

## 8. Related pages
- [What is UMP? (for Implementers)]({{ '/en/ump/' | relative_url }})
- [MIDI-CI and Profiles]({{ '/en/ci-profiles/' | relative_url }})
- [What is MUID (MIDI Unique Identifier)?]({{ '/en/muid/' | relative_url }})
- [Discovery, DeviceInfo, and PE Procedure (Get/Set)]({{ '/en/discovery-deviceinfo-pe/' | relative_url }})

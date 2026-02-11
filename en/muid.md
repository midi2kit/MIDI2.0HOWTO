---
title: What is MUID (MIDI Unique Identifier)?
lang: en
permalink: /en/muid/
---

# What is MUID (MIDI Unique Identifier)?

`MUID` is the identifier used by MIDI-CI to address and track peers.  
In implementation, request/reply correlation should use `MUID` as the primary key instead of display name or endpoint label.

## 1. Why MUID matters

MIDI-CI messages carry `sourceMUID` and `destinationMUID`.  
This is how you distinguish peers on a shared bus.

Typical implementation uses:
- identify peer after Discovery
- correlate PE requests and replies
- target timeout/retry handling
- decide session invalidation on reconnect

## 2. Bit width and value ranges

MUID is a 28-bit identifier (encoded as 7-bit x 4 bytes).

| Range | Meaning |
|---|---|
| `0x0000000` - `0x0FFFFEFF` | Dynamic MUID (normal allocation range) |
| `0x0FFFFF00` - `0x0FFFFFFE` | Reserved |
| `0x0FFFFFFF` | Broadcast MUID |

Notes:
- Broadcast appears as `7F 7F 7F 7F` in SysEx fields.
- Allocators should avoid reserved ranges.

## 3. Lifecycle in practice

1. Generate a Dynamic MUID on local startup  
2. Send Discovery to Broadcast MUID  
3. Build `remoteMUID <-> endpoint` mapping from replies  
4. Use MUID as session key during operation  
5. Re-allocate and rerun Discovery on conflict/invalidation/reconnect

## 4. Collision handling

MUID collisions are rare but must be handled.

Minimum behavior:
1. detect conflict (duplicate MUID, Invalidate MUID, etc.)
2. drop stale session for the old MUID
3. generate a new Dynamic MUID
4. rerun Discovery

Do not rely on "MUID is always unique forever."

## 5. Implementation pattern (Swift)

```swift
struct DeviceSession {
    let endpointID: String
    let remoteMUID: UInt32
    var lastSeenAt: UInt64
}

actor MUIDRegistry {
    private var byMUID: [UInt32: DeviceSession] = [:]

    func upsert(_ session: DeviceSession) {
        byMUID[session.remoteMUID] = session
    }

    func session(for muid: UInt32) -> DeviceSession? {
        byMUID[muid]
    }

    func invalidate(_ muid: UInt32) {
        byMUID.removeValue(forKey: muid)
    }
}
```

Operational tips:
- track PE inflight requests by `remoteMUID`
- prefer fresh MUID resolution after reconnect even if endpoint label matches
- clean stale sessions with TTL

## 6. Common failures

1. identifying peers only by endpoint name  
Mitigation: use `MUID` as correlation key

2. starting PE before Discovery finishes  
Mitigation: block PE until `MUIDKnown`

3. keeping old inflight requests after MUID invalidation  
Mitigation: cancel inflight requests when MUID changes

4. mixing broadcast and unicast semantics  
Mitigation: reserve `0x0FFFFFFF` for operations that require broadcast

## 7. Related pages
- [MIDI-CI and Profiles]({{ '/en/ci-profiles/' | relative_url }})
- [Initiator / Responder (MIDI-CI Implementation Guide)]({{ '/en/initiator-responder/' | relative_url }})
- [Discovery, DeviceInfo, and PE Procedure (Get/Set)]({{ '/en/discovery-deviceinfo-pe/' | relative_url }})

## 8. References
- [MIDI-CI Specification](https://midi.org/midi-ci-specification)
- [MIDI-CI: Handling Multiple Initiators and Responders](https://midi.org/midi-ci-handling-multiple-initiators-and-responders)
- [MIDI 2.0 Core Specification Collection](https://midi.org/midi-2-0-core-specification-collection)

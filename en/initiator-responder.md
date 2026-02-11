---
title: Initiator / Responder (MIDI-CI Implementation Guide)
lang: en
permalink: /en/initiator-responder/
---

# Initiator / Responder (MIDI-CI Implementation Guide)

This page explains `Initiator` and `Responder` in MIDI-CI from an implementation perspective, including state handling and practical MIDI2Kit examples.

## 1. Fix the definitions first

- `Initiator`: the side that starts a request
- `Responder`: the side that returns a reply

Important:
- Roles are not fixed per device
- Roles are decided per transaction
- Between the same two devices, role direction can change by operation

## 2. Common implementation confusion

### 2.1 Role is not a connection-level constant

Even if the same USB/BLE session is active, role direction may differ across Discovery, Profile operations, and PE Get/Set.

### 2.2 Every transaction needs correlation keys

At minimum, correlate request/reply using:

- local MUID
- remote MUID
- Request ID (PE)
- resource name (PE)
- timeout context

Weak correlation logic causes mismatched replies and retry loops.

## 3. Who is Initiator in each phase?

| Phase | Initiator | Responder | Main outcome |
|---|---|---|---|
| Discovery | side that starts discovery | discovered side | MUID resolution |
| Capability query | querying side | responding side | Profile/PE/PI capability flags |
| PE `Get` | requesting side | resource provider | JSON/binary response |
| PE `Set` | updating side | applying side | success/failure reply |
| Subscribe/Notify | side starting subscription | side publishing notifications | update stream |

## 4. Minimal state machine

### 4.1 Initiator side

```text
EndpointDetected
  -> DiscoverySent
  -> MUIDKnown
  -> CapabilityKnown
  -> PEReady
  -> Operational
  -> Recovering (timeout/reconnect)
```

### 4.2 Responder side

```text
Idle
  -> DiscoveryReceived
  -> MUIDAssigned
  -> CapabilityReplyReady
  -> ServingPE
  -> Idle
```

## 5. MIDI2Kit implementation examples

### 5.1 Initiator (high-level API: `MIDI2Client`)

```swift
import Foundation
import MIDI2Kit

let client = try MIDI2Client(name: "CI-Initiator")
try await client.start()

Task {
    for await event in await client.makeEventStream() {
        switch event {
        case .deviceDiscovered(let device):
            guard device.supportsPropertyExchange else { continue }

            let info = try await client.getDeviceInfo(from: device.muid)
            print("Product: \(info.productName ?? "Unknown")")

            let resources = try await client.getResourceList(from: device.muid)

            if resources.contains(where: { $0.resource == "DeviceInfo" && $0.canGet }) {
                _ = try await client.get("DeviceInfo", from: device.muid)
            }

            if resources.contains(where: { $0.resource == "State" && $0.canSet }) {
                let body: [String: Any] = ["note": "initiator example"]
                let data = try JSONSerialization.data(withJSONObject: body)
                _ = try await client.set("State", data: data, to: device.muid)
            }

        default:
            break
        }
    }
}
```

Key points:
- Always gate `Get/Set` by `canGet/canSet` from `ResourceList`
- Skip PE operations if `supportsPropertyExchange == false`

### 5.2 Local testing with a Responder (`MockDevice + LoopbackTransport`)

```swift
import MIDI2Kit

let (initiatorTransport, responderTransport) = LoopbackTransport.createPair()

let mock = MockDevice(
    transport: responderTransport,
    preset: .korgModulePro
)
try await mock.start()

// Low-level example (initializer details may vary by SDK version)
let ciManager = CIManager(transport: initiatorTransport /* ... */)
let peManager = PEManager(transport: initiatorTransport /* ... */)

await ciManager.startDiscovery()
let _ = try await peManager.get("DeviceInfo", from: mock.handle)
```

Use case:
- Reproduce both Initiator/Responder roles without physical hardware
- Automate timeout/retry/capability-gating tests

## 6. How to handle Get/Set capability safely

Do not hard-code assumptions like "this resource should be writable."
Decide per connection based on advertised capability.

| Resource example | Typical use | Check |
|---|---|---|
| `DeviceInfo` | device identity | `canGet` |
| `ResourceList` | capability table | `canGet` |
| `CurrentMode` | mode read/write | `canGet` / `canSet` |
| `LocalOn` | local control | `canGet` / `canSet` |
| `State` | save/restore state | `canGet` / `canSet` |
| `X-ParameterList` | vendor parameter catalog | `canGet` |
| `X-ProgramEdit` | vendor program edit values | `canGet` / `canSet` (device-dependent) |

## 7. Multi-initiator/responder design notes

1. Separate inflight requests per `remoteMUID`
2. Manage timeout/retry per request
3. Drop old MUID sessions on reconnect
4. Process notifications on a queue separate from request/reply flow

MIDI-CI can involve multiple peers at once, so single-peer assumptions are fragile.

## 8. Frequent failures and mitigations

1. Starting PE before Discovery completes  
Mitigation: block PE until `MUIDKnown`

2. Running `Set` without `canSet` check  
Mitigation: persist a capability table from `ResourceList`

3. Reusing stale MUID after reconnect  
Mitigation: reset session state and rerun Discovery

4. Weak request/reply correlation  
Mitigation: use at least `MUID + requestId + resource` as correlation keys

## 9. Related pages
- [What is MUID (MIDI Unique Identifier)?]({{ '/en/muid/' | relative_url }})
- [MIDI-CI and Profiles]({{ '/en/ci-profiles/' | relative_url }})
- [Discovery, DeviceInfo, and PE Procedure (Get/Set)]({{ '/en/discovery-deviceinfo-pe/' | relative_url }})
- [Property Exchange (PE)]({{ '/en/property-exchange/' | relative_url }})
- [What is MIDI2Kit? (What It Can and Cannot Do)]({{ '/en/midi2kit/' | relative_url }})

## 10. References
- [MIDI-CI Specification](https://midi.org/midi-ci-specification)
- [MIDI-CI: Handling Multiple Initiators and Responders](https://midi.org/midi-ci-handling-multiple-initiators-and-responders)
- [MIDI 2.0 Property Exchange](https://midi.org/midi-2-0-property-exchange)
- [MIDI2Kit-SDK README](https://github.com/midi2kit/MIDI2Kit-SDK/blob/main/README.md)
- [MIDI2Kit Guide: Inter-App MIDI-CI Limitations](https://midi2kit.dev/guides/inter-app-midi-ci.html)

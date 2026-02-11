---
title: What is UMP?
lang: en
permalink: /en/ump/
---

# What is UMP? (for Implementers)

UMP is the common binary format that carries MIDI messages as 32-bit words.  
For implementation work, the key is not theory alone but building a parser/encoder that fails safely.

## 1. UMP as an implementation unit
- One UMP message is represented by `1 to 4 words`
- Read `Message Type (MT)` and `Group` from word0
- Determine message length from MT, then consume the full message atomically

## 2. First fields to decode from word0
1. `MT` (Message Type)
- Classifies the message category
- Determines word count

2. `Group`
- Logical port identifier
- Core key for routing/filter/state partitioning

Example (concept):
```c
uint8_t mt = (word0 >> 28) & 0x0F;
uint8_t group = (word0 >> 24) & 0x0F;
size_t words = word_count_for_mt(mt); // spec-driven table
```

## 3. Parser pattern that scales
Use a streaming parser driven by MT -> word count.

```text
while (buffer has >= 1 word) {
  peek word0
  mt = extract_mt(word0)
  n  = word_count_for_mt(mt)
  if (buffer has < n words) break

  msg_words = pop n words
  dispatch(msg_words)
}
```

Implementation notes:
- Keep `word_count_for_mt` explicit and table-driven
- Treat unknown MT as a structured parse error
- Keep partial message fragments until enough words arrive
- Partition downstream state by Group

## 4. Encoder pattern
Implement encoding as a one-way mapping from internal events to UMP words.

1. Validate normalized input event
2. Resolve MT
3. Build word array
4. Re-validate before transmit (length/range/group)

Recommended split:
- `encode_midi1()` and `encode_midi2()` as separate paths
- Shared `validate_ump(words)` before write

## 5. SysEx and segmented messages
SysEx-like flows need explicit reassembly state.

- Handle Complete / Start / Continue / End as a state machine
- Partition reassembly context by Group (and stream id when applicable)
- Add timeout and reset behavior for incomplete sequences

## 6. JR Timestamp handling
Treat JR timestamps independently from local arrival time.

- RX path: map JR to internal scheduling time
- TX path: derive JR from scheduler timeline
- Non-supporting path: fallback to arrival-time scheduling

## 7. Mixed MIDI 1.0 and MIDI 2.0 paths
- Keep an explicit path for MIDI 1.0 semantic data inside UMP transport
- Resolution mapping may be lossy; keep `origin_protocol`
- Aim for practical equivalence, not strict bitwise equivalence

## 8. Performance and quality checklist
1. Allocation discipline
- Prefer fixed buffers and slices during parse

2. Threading model
- Decode in I/O thread, pass semantic events through queues

3. Observability
- Track unknown MT, length mismatch, and reassembly failures

4. Regression tests
- Golden vectors for known word sequences
- Boundary cases: shortest/longest, unknown MT, broken segmentation

## 9. Minimal implementation set
1. MT -> word count table
2. Streaming parser
3. Group-aware dispatch
4. SysEx reassembly
5. Encoder + validator

## 10. Related pages
- [MIDI 2.0 Fundamentals (for Implementers)]({{ '/en/fundamentals/' | relative_url }})
- [MIDI-CI and Profiles]({{ '/en/ci-profiles/' | relative_url }})
- [Discovery, DeviceInfo, and PE Procedure (Get/Set)]({{ '/en/discovery-deviceinfo-pe/' | relative_url }})
